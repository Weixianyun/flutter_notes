import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../data/models/note_model.dart';
import '../../data/models/sync_checkpoint.dart';
import 'checkpoint_store.dart';
import 'github_service.dart';

/// 同步状态
enum SyncStatus { idle, syncing, success, error }

/// 冲突解决策略
enum ConflictResolution {
  /// 本地版本优先（覆盖远程）
  localWins,
  /// 远程版本优先（覆盖本地）
  remoteWins,
  /// 跳过冲突项
  skip,
}

/// 笔记同步服务
///
/// 将本地笔记同步到 GitHub 仓库的 `notes/` 目录。
/// 每条笔记存储为独立的 Markdown 文件，文件名使用笔记标题的 slug。
class SyncService {
  SyncService(this._github, this._token, [CheckpointStore? store])
      : _store = store;

  final GitHubService _github;
  final String _token;
  final CheckpointStore? _store;

  static const _uuid = Uuid();

  /// 推送单条笔记到 GitHub
  Future<void> pushNote({
    required String owner,
    required String repo,
    required NoteModel note,
  }) async {
    final path = 'notes/${_slugify(note.title.isEmpty ? note.id : note.title)}.md';
    final content = _noteToMarkdown(note);

    final existing = await _github.getFile(
      token: _token,
      owner: owner,
      repo: repo,
      path: path,
    );

    await _github.createOrUpdateFile(
      token: _token,
      owner: owner,
      repo: repo,
      path: path,
      content: content,
      message: 'sync: ${note.title.isEmpty ? "untitled" : note.title}',
      sha: existing?.sha,
    );
  }

  /// 批量推送所有笔记
  Future<SyncResult> pushAllNotes({
    required String owner,
    required String repo,
    required List<NoteModel> notes,
  }) async {
    int success = 0;
    final errors = <String>[];

    for (final note in notes) {
      try {
        await pushNote(owner: owner, repo: repo, note: note);
        success++;
      } catch (e) {
        errors.add('${note.title}: $e');
      }
    }

    return SyncResult(total: notes.length, success: success, errors: errors);
  }

  /// 从 GitHub 拉取所有笔记
  ///
  /// 列出 `notes/` 目录下的 `.md` 文件，逐个下载并解析为 [NoteModel]。
  Future<List<NoteModel>> pullNotes({
    required String owner,
    required String repo,
  }) async {
    final files = await _github.listFiles(
      token: _token,
      owner: owner,
      repo: repo,
      path: 'notes',
    );

    final notes = <NoteModel>[];
    for (final file in files) {
      if (!file.name.endsWith('.md')) continue;
      final result = await _github.getFile(
        token: _token,
        owner: owner,
        repo: repo,
        path: file.path,
      );
      if (result != null) {
        final note = _markdownToNote(result.content);
        if (note != null) notes.add(note);
      }
    }
    return notes;
  }

  /// 带冲突检测的同步
  ///
  /// 比较本地笔记与远程笔记的 `updatedAt` 时间戳：
  /// - 本地较新 → 推送本地版本
  /// - 远程较新 → 根据 [resolution] 处理
  /// - 时间相同 → 跳过
  Future<SyncResult> syncWithConflictCheck({
    required String owner,
    required String repo,
    required List<NoteModel> localNotes,
    required List<NoteModel> remoteNotes,
    required ConflictResolution resolution,
  }) async {
    final remoteMap = <String, NoteModel>{
      for (final n in remoteNotes) n.id: n,
    };

    int success = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final local in localNotes) {
      final remote = remoteMap[local.id];

      if (remote == null) {
        try {
          await pushNote(owner: owner, repo: repo, note: local);
          success++;
        } catch (e) {
          errors.add('${local.title}: $e');
        }
        continue;
      }

      final localUpdated = local.updatedAt;
      final remoteUpdated = remote.updatedAt;

      if (localUpdated.isAfter(remoteUpdated)) {
        try {
          await pushNote(owner: owner, repo: repo, note: local);
          success++;
        } catch (e) {
          errors.add('${local.title}: $e');
        }
      } else if (remoteUpdated.isAfter(localUpdated)) {
        switch (resolution) {
          case ConflictResolution.localWins:
            try {
              await pushNote(owner: owner, repo: repo, note: local);
              success++;
            } catch (e) {
              errors.add('${local.title}: $e');
            }
          case ConflictResolution.remoteWins:
            skipped++;
          case ConflictResolution.skip:
            skipped++;
        }
      } else {
        skipped++;
      }
    }

    return SyncResult(
      total: localNotes.length,
      success: success,
      errors: errors,
      skipped: skipped,
    );
  }

  /// 将笔记转换为 Markdown 文件内容（含 YAML front matter）
  String noteToMarkdown(NoteModel note) => _noteToMarkdown(note);

  String _noteToMarkdown(NoteModel note) {
    final buffer = StringBuffer();

    buffer.writeln('---');
    buffer.writeln('id: ${note.id}');
    buffer.writeln('title: ${note.title}');
    buffer.writeln('priority: ${note.priority.name}');
    buffer.writeln('status: ${note.status.name}');
    buffer.writeln('tags: [${note.tags.join(', ')}]');
    buffer.writeln('created_at: ${note.createdAt.toIso8601String()}');
    buffer.writeln('updated_at: ${note.updatedAt.toIso8601String()}');
    buffer.writeln('---');
    buffer.writeln();

    buffer.write(note.content.isEmpty ? '*暂无内容*' : note.content);

    return buffer.toString();
  }

  /// 将 Markdown 文件内容解析为 [NoteModel]
  ///
  /// 解析 YAML front matter 提取元数据，正文为 Markdown 内容。
  /// 格式不合法时返回 null。
  NoteModel? _markdownToNote(String markdown) {
    final lines = markdown.split('\n');

    if (lines.isEmpty || lines.first.trim() != '---') return null;

    final frontMatter = <String, String>{};
    int i = 1;
    while (i < lines.length && lines[i].trim() != '---') {
      final colonIdx = lines[i].indexOf(':');
      if (colonIdx > 0) {
        final key = lines[i].substring(0, colonIdx).trim();
        final value = lines[i].substring(colonIdx + 1).trim();
        frontMatter[key] = value;
      }
      i++;
    }

    if (i >= lines.length) return null;
    i++;

    final content = lines.skip(i).join('\n').trim();

    final id = frontMatter['id'];
    final title = frontMatter['title'] ?? '';
    if (id == null) return null;

    final priority = NotePriority.values.firstWhere(
      (e) => e.name == frontMatter['priority'],
      orElse: () => NotePriority.medium,
    );
    final status = NoteStatus.values.firstWhere(
      (e) => e.name == frontMatter['status'],
      orElse: () => NoteStatus.draft,
    );

    final tagsStr = (frontMatter['tags'] ?? '').replaceAll(RegExp(r'[\[\]]'), '');
    final tags = tagsStr.isEmpty
        ? <String>[]
        : tagsStr
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    return NoteModel(
      id: id,
      title: title,
      content: content == '*暂无内容*' ? '' : content,
      priority: priority,
      status: status,
      tags: tags,
      createdAt: frontMatter['created_at'] != null
          ? DateTime.tryParse(frontMatter['created_at']!)
          : null,
      updatedAt: frontMatter['updated_at'] != null
          ? DateTime.tryParse(frontMatter['updated_at']!)
          : null,
    );
  }

  /// 将标题转换为文件名安全的 slug
  String slugify(String text) => _slugify(text);

  /// 增量推送：仅推送 [since] 之后有更新的本地笔记
  ///
  /// 配合 `PreferencesService.getLastSyncedAt()` 使用。
  /// 每条成功推送后更新调用方的 lastSyncedAt 集合。
  Future<SyncResult> pushNotesAfter({
    required String owner,
    required String repo,
    required List<NoteModel> notes,
    required DateTime? since,
  }) async {
    final candidates = since == null
        ? notes
        : notes.where((n) => n.updatedAt.isAfter(since)).toList();
    return pushAllNotes(owner: owner, repo: repo, notes: candidates);
  }

  /// 增量拉取：仅拉取 [since] 之后有更新的远程笔记
  ///
  /// 依赖 GitHub 仓库最近 commit 时间或文件 sha 元数据判断增量。
  /// 当前实现：拉取 `notes/` 目录下所有 .md 文件后用 front-matter 的
  /// `updated_at` 与 [since] 二次过滤。
  Future<List<NoteModel>> pullNotesSince({
    required String owner,
    required String repo,
    required DateTime? since,
  }) async {
    final all = await pullNotes(owner: owner, repo: repo);
    if (since == null) return all;
    return all.where((n) => n.updatedAt.isAfter(since)).toList();
  }

  /// 检测冲突：返回本地与远程均变更的笔记对
  ///
  /// 冲突条件：
  /// - 同一 noteId 在本地与远程都存在
  /// - 本地 updatedAt > lastSyncedAt
  /// - 远程 updatedAt > lastSyncedAt
  /// - （可选）当 [lastSyncedRemoteSha] 提供时，要求本地 sha 也发生变更
  ///   才算冲突。任一方未真正修改内容（updatedAt 推进但 sha 不变）时
  ///   不会上报冲突。
  ///
  /// 纯函数,不调用 GitHubService,可独立测试。
  static List<SyncConflictItem> detectConflicts({
    required List<NoteModel> localNotes,
    required List<NoteModel> remoteNotes,
    required DateTime? lastSyncedAt,
    Map<String, String>? lastSyncedRemoteSha,
  }) {
    final remoteMap = <String, NoteModel>{
      for (final n in remoteNotes) n.id: n,
    };
    final conflicts = <SyncConflictItem>[];
    for (final local in localNotes) {
      final remote = remoteMap[local.id];
      if (remote == null) continue;
      if (lastSyncedAt == null) {
        // 没有 lastSyncedAt 时无法判断是否双方都更新，全部冲突
        conflicts.add(SyncConflictItem(local: local, remote: remote));
        continue;
      }
      final localChanged = local.updatedAt.isAfter(lastSyncedAt);
      final remoteChanged = remote.updatedAt.isAfter(lastSyncedAt);
      if (!localChanged || !remoteChanged) continue;
      // 双方 updatedAt 都推进时，再用 sha 做内容级二次校验
      if (lastSyncedRemoteSha != null) {
        final prevSha = lastSyncedRemoteSha[local.id];
        if (prevSha != null && prevSha == computeContentSha(remote)) {
          // 远端内容 sha 未变 → 远端没有真实变更，不算冲突
          continue;
        }
      }
      conflicts.add(SyncConflictItem(local: local, remote: remote));
    }
    return conflicts;
  }

  /// 计算内容 sha（基于标题/正文/标签/优先级/状态，忽略 updatedAt）
  ///
  /// 用于判断"updatedAt 推进但内容未变"的情况，例如保存触发
  /// `updatedAt = DateTime.now()` 但内容相同。
  /// 算法：归一化字段后拼接 → utf8 字节 → SHA-1。
  static String computeContentSha(NoteModel note) {
    final normalized = [
      note.title.trim(),
      note.content,
      note.priority.name,
      note.status.name,
      note.tags.join('\u0001'),
    ].join('\u0000');
    return _sha1OfString(normalized);
  }

  /// 计算 Markdown 字符串的 sha（用于 GitHub 远端内容）
  static String computeRemoteSha(String markdown) => _sha1OfString(markdown);

  static String _sha1OfString(String input) {
    final bytes = utf8.encode(input);
    return _sha1OfBytes(bytes);
  }

  static String _sha1OfBytes(List<int> bytes) {
    // 纯 Dart SHA-1 实现（40 hex chars）。不依赖 crypto 包，避免在测试中
    // 引入额外的 package 依赖。如果项目后续引入 crypto，可替换为
    // `crypto` 包的 `sha1.convert(bytes).toString()`。
    const h0 = 0x67452301;
    const h1 = 0xEFCDAB89;
    const h2 = 0x98BADCFE;
    const h3 = 0x10325476;
    const h4 = 0xC3D2E1F0;

    int a = h0, b = h1, c = h2, d = h3, e = h4;
    final msgLen = bytes.length;
    final bitLen = msgLen * 8;

    // Padding
    final padded = <int>[...bytes, 0x80];
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    // Append 64-bit big-endian length (we only support 32-bit lengths)
    for (int i = 7; i >= 0; i--) {
      padded.add(i < 4 ? 0 : ((bitLen >> ((7 - i) * 8)) & 0xFF));
    }

    int leftRotate(int x, int n) =>
        ((x << n) | (x >>> (32 - n))) & 0xFFFFFFFF;

    final words = <int>[];
    for (int i = 0; i < padded.length; i += 4) {
      words.add(
        (padded[i] << 24) |
            (padded[i + 1] << 16) |
            (padded[i + 2] << 8) |
            padded[i + 3],
      );
    }

    for (int chunkStart = 0; chunkStart < words.length; chunkStart += 16) {
      final w = List<int>.filled(80, 0);
      for (int i = 0; i < 16; i++) {
        w[i] = words[chunkStart + i];
      }
      for (int i = 16; i < 80; i++) {
        w[i] = leftRotate(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var aa = a, bb = b, cc = c, dd = d, ee = e;
      for (int i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (bb & cc) | ((~bb & 0xFFFFFFFF) & dd);
          k = 0x5A827999;
        } else if (i < 40) {
          f = bb ^ cc ^ dd;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (bb & cc) | (bb & dd) | (cc & dd);
          k = 0x8F1BBCDC;
        } else {
          f = bb ^ cc ^ dd;
          k = 0xCA62C1D6;
        }
        final temp = (leftRotate(aa, 5) + f + ee + k + w[i]) & 0xFFFFFFFF;
        ee = dd;
        dd = cc;
        cc = leftRotate(bb, 30);
        bb = aa;
        aa = temp;
      }

      a = (a + aa) & 0xFFFFFFFF;
      b = (b + bb) & 0xFFFFFFFF;
      c = (c + cc) & 0xFFFFFFFF;
      d = (d + dd) & 0xFFFFFFFF;
      e = (e + ee) & 0xFFFFFFFF;
    }

    String hex(int v) {
      String s = '';
      for (int i = 7; i >= 0; i--) {
        s += ((v >> (i * 4)) & 0xF).toRadixString(16);
      }
      return s;
    }

    return hex(a) + hex(b) + hex(c) + hex(d) + hex(e);
  }

  // ── 断点续传 ──

  /// 读取当前持久化的 checkpoint（无 store 或无 checkpoint 时返回 null）
  SyncCheckpoint? loadCheckpoint() => _store?.load();

  /// 持久化 checkpoint（无 store 时为 no-op）
  Future<void> saveCheckpoint(SyncCheckpoint checkpoint) async {
    await _store?.save(checkpoint);
  }

  /// 清除 checkpoint
  Future<void> clearCheckpoint() async {
    await _store?.clear();
  }

  /// 创建初始 checkpoint
  ///
  /// - [owner]/[repo] 同步目标仓库
  /// - [direction] 同步方向
  /// - [localNotes] 本地笔记（用于初始化 push 队列）
  /// - [pendingPullPaths] 远端待拉取文件列表
  /// - [lastSyncedAt] 本次同步基线时间
  SyncCheckpoint createCheckpoint({
    required String owner,
    required String repo,
    required SyncDirection direction,
    required List<NoteModel> localNotes,
    required List<String> pendingPullPaths,
    required DateTime? lastSyncedAt,
  }) {
    final now = DateTime.now();
    return SyncCheckpoint(
      id: _uuid.v4(),
      direction: direction,
      stage: SyncStage.idle,
      owner: owner,
      repo: repo,
      lastSyncedAt: lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      pendingPushIds: [for (final n in localNotes) n.id],
      pendingPullPaths: List.of(pendingPullPaths),
      pulledRemoteNotes: <String, Map<String, dynamic>>{},
      completedPushIds: <String>{},
      completedPullPaths: <String>{},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 标记一条推送任务完成
  ///
  /// 返回更新后的 checkpoint（不持久化，调用方负责写入）。
  SyncCheckpoint markPushCompleted(SyncCheckpoint cp, String noteId) {
    return cp.copyWith(
      pendingPushIds: cp.pendingPushIds.where((id) => id != noteId).toList(),
      completedPushIds: {...cp.completedPushIds, noteId},
      updatedAt: DateTime.now(),
    );
  }

  /// 标记一条拉取任务完成
  SyncCheckpoint markPullCompleted(
    SyncCheckpoint cp,
    String path,
    Map<String, dynamic> noteJson,
  ) {
    final pulled = Map<String, Map<String, dynamic>>.from(cp.pulledRemoteNotes);
    final noteId = noteJson['id'] as String? ?? path;
    pulled[noteId] = noteJson;
    return cp.copyWith(
      pendingPullPaths: cp.pendingPullPaths.where((p) => p != path).toList(),
      completedPullPaths: {...cp.completedPullPaths, path},
      pulledRemoteNotes: pulled,
      updatedAt: DateTime.now(),
    );
  }

  /// 进入下一阶段
  SyncCheckpoint advanceStage(SyncCheckpoint cp, SyncStage next) {
    return cp.copyWith(stage: next, updatedAt: DateTime.now());
  }

  /// 同步执行：基于 checkpoint 推进 push 队列
  ///
  /// - 接受 [notesById] 用来按 ID 查找待推送笔记
  /// - 每成功推送一条就更新 checkpoint；任意一条失败抛错
  /// - 完成后清除 checkpoint
  Future<SyncResult> resumePush({
    required SyncCheckpoint checkpoint,
    required Map<String, NoteModel> notesById,
  }) async {
    final cp = checkpoint.copyWith(stage: SyncStage.pushing, updatedAt: DateTime.now());
    await saveCheckpoint(cp);

    int success = 0;
    final errors = <String>[];

    for (final noteId in List.of(cp.pendingPushIds)) {
      final note = notesById[noteId];
      if (note == null) {
        errors.add('$noteId: 本地笔记已不存在，已跳过');
        final next = markPushCompleted(cp, noteId);
        await saveCheckpoint(next);
        continue;
      }
      try {
        await pushNote(owner: cp.owner, repo: cp.repo, note: note);
        success++;
        final next = markPushCompleted(cp, noteId);
        await saveCheckpoint(next);
      } catch (e) {
        errors.add('${note.title}: $e');
        // 失败时不更新 checkpoint，等待下次 resume 继续
        break;
      }
    }

    return SyncResult(
      total: cp.completedPushIds.length + cp.pendingPushIds.length,
      success: success,
      errors: errors,
    );
  }

  /// 同步执行：基于 checkpoint 推进 pull 队列
  ///
  /// 逐条拉取远程文件内容，回调 [onNotePulled] 把已拉取笔记交给上层保存。
  /// 失败抛错，成功后更新 checkpoint。
  Future<SyncResult> resumePull({
    required SyncCheckpoint checkpoint,
    required Future<void> Function(Map<String, dynamic> noteJson) onNotePulled,
  }) async {
    final cp = checkpoint.copyWith(
      stage: SyncStage.pullingContent,
      updatedAt: DateTime.now(),
    );
    await saveCheckpoint(cp);

    int success = 0;
    final errors = <String>[];

    for (final path in List.of(cp.pendingPullPaths)) {
      try {
        final file = await _github.getFile(
          token: _token,
          owner: cp.owner,
          repo: cp.repo,
          path: path,
        );
        if (file == null) {
          errors.add('$path: 远端文件不存在');
          final next = markPullCompleted(cp, path, {'id': path, 'missing': true});
          await saveCheckpoint(next);
          continue;
        }
        final note = _markdownToNote(file.content);
        if (note == null) {
          errors.add('$path: 远端 Markdown 格式不合法');
          final next = markPullCompleted(cp, path, {'id': path, 'invalid': true});
          await saveCheckpoint(next);
          continue;
        }
        final json = note.toJson();
        json['remotePath'] = path;
        await onNotePulled(json);
        success++;
        final next = markPullCompleted(cp, path, json);
        await saveCheckpoint(next);
      } catch (e) {
        errors.add('$path: $e');
        break;
      }
    }

    return SyncResult(
      total: cp.completedPullPaths.length + cp.pendingPullPaths.length,
      success: success,
      errors: errors,
    );
  }

  /// 标记同步完成并清理 checkpoint
  Future<void> finalizeCheckpoint(SyncCheckpoint cp) async {
    final done = cp.copyWith(
      stage: SyncStage.done,
      pendingPushIds: <String>[],
      pendingPullPaths: <String>[],
      updatedAt: DateTime.now(),
    );
    await saveCheckpoint(done);
    await clearCheckpoint();
  }

  String _slugify(String text) {
    final slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.substring(0, slug.length.clamp(0, 50));
  }
}

/// 同步结果
class SyncResult {
  const SyncResult({
    required this.total,
    required this.success,
    required this.errors,
    this.skipped = 0,
  });

  final int total;
  final int success;
  final List<String> errors;
  final int skipped;

  int get failed => total - success - skipped;
  bool get isSuccess => errors.isEmpty;
}

/// 单条笔记冲突
class SyncConflictItem {
  const SyncConflictItem({required this.local, required this.remote});

  final NoteModel local;
  final NoteModel remote;

  /// 笔记 ID（两版本应一致）
  String get noteId => local.id;

  /// 笔记标题
  String get title => local.title.isNotEmpty ? local.title : '(无标题)';

  /// 本地更新时间是否晚于远程
  bool get localIsNewer => local.updatedAt.isAfter(remote.updatedAt);

  /// 本地内容 sha
  String get localSha => SyncService.computeContentSha(local);

  /// 远程内容 sha
  String get remoteSha => SyncService.computeContentSha(remote);

  /// 本地与远程的内容 sha 是否相同（仅 updatedAt 推进）
  bool get onlyTimestampChanged => localSha == remoteSha;

  /// 远端落后时长（让 UI 显示"本地领先 X 分钟"）
  Duration localLeadDuration(Duration? lastSyncedAt) {
    if (lastSyncedAt == null) return Duration.zero;
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local.updatedAt.difference(remote.updatedAt);
    }
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return remote.updatedAt.difference(local.updatedAt);
    }
    return Duration.zero;
  }
}
