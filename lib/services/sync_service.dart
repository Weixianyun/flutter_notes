import '../../data/models/note_model.dart';
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
  SyncService(this._github, this._token);

  final GitHubService _github;
  final String _token;

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
