import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../services/github_service.dart';
import '../../../services/service_providers.dart';
import '../../../services/sync_service.dart';
import '../../notes/providers/notes_provider.dart';

export '../../../services/sync_service.dart' show ConflictResolution;

/// 同步状态
class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.user,
    this.lastSyncTime,
    this.message,
    this.conflicts = const <SyncConflictItem>[],
    this.pendingResolutions = const <String, ConflictResolution>{},
  });

  final SyncStatus status;
  final GitHubUser? user;
  final DateTime? lastSyncTime;
  final String? message;

  /// 当前检测到的冲突列表
  final List<SyncConflictItem> conflicts;

  /// 用户对每条冲突已做的选择（noteId -> resolution）
  final Map<String, ConflictResolution> pendingResolutions;

  bool get hasConflicts => conflicts.isNotEmpty;

  int get unresolvedCount =>
      conflicts.where((c) => !pendingResolutions.containsKey(c.noteId)).length;

  bool get allResolved =>
      conflicts.isNotEmpty && unresolvedCount == 0;

  SyncState copyWith({
    SyncStatus? status,
    GitHubUser? user,
    DateTime? lastSyncTime,
    String? message,
    List<SyncConflictItem>? conflicts,
    Map<String, ConflictResolution>? pendingResolutions,
  }) {
    return SyncState(
      status: status ?? this.status,
      user: user ?? this.user,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      message: message ?? this.message,
      conflicts: conflicts ?? this.conflicts,
      pendingResolutions:
          pendingResolutions ?? this.pendingResolutions,
    );
  }
}

/// 同步状态管理
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    final token = _ref.read(githubTokenProvider);
    if (token == null) return;

    state = state.copyWith(status: SyncStatus.idle);
    await fetchUser();
  }

  /// 获取 GitHub 用户信息
  Future<void> fetchUser() async {
    final token = _ref.read(githubTokenProvider);
    if (token == null) {
      state = const SyncState();
      return;
    }

    try {
      final github = _ref.read(githubServiceProvider);
      final user = await github.getUser(token);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(message: '获取用户信息失败: $e');
    }
  }

  /// 保存认证 token
  ///
  /// 加密后存储到 PreferencesService，然后获取用户信息。
  Future<void> saveToken(String token) async {
    final prefs = _ref.read(preferencesServiceProvider);
    final github = _ref.read(githubServiceProvider);

    final encrypted = github.encryptToken(token);
    await prefs.setEncryptedToken(encrypted);

    await fetchUser();
  }

  /// 登出：清除 token 和用户信息
  Future<void> logout() async {
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.clearToken();
    await prefs.clearSyncConfig();
    state = const SyncState();
  }

  /// 同步所有笔记到 GitHub
  Future<void> syncAllNotes() async {
    final syncService = _ref.read(syncServiceProvider);
    if (syncService == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未登录 GitHub',
      );
      return;
    }

    final prefs = _ref.read(preferencesServiceProvider);
    final owner = prefs.getSyncRepoOwner();
    final repo = prefs.getSyncRepoName();

    if (owner == null || repo == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未配置同步仓库',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: '正在同步...',
    );

    try {
      final notesAsync = _ref.read(notesProvider);
      final notes = notesAsync.maybeWhen(
        data: (n) => n,
        orElse: () => <NoteModel>[],
      );

      if (notes.isEmpty) {
        state = state.copyWith(
          status: SyncStatus.success,
          message: '没有笔记需要同步',
          lastSyncTime: DateTime.now(),
        );
        return;
      }

      final result = await syncService.pushAllNotes(
        owner: owner,
        repo: repo,
        notes: notes,
      );

      state = state.copyWith(
        status: SyncStatus.success,
        message: result.isSuccess
            ? '成功同步 ${result.success}/${result.total} 条笔记'
            : '同步完成: ${result.success} 成功, ${result.failed} 失败',
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '同步失败: $e',
      );
    }
  }

  /// 从 GitHub 导入笔记
  ///
  /// 拉取远程仓库 `notes/` 目录下的所有 Markdown 文件，
  /// 解析后通过 Repository 写入本地数据库。
  Future<void> importNotes() async {
    final syncService = _ref.read(syncServiceProvider);
    if (syncService == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未登录 GitHub',
      );
      return;
    }

    final prefs = _ref.read(preferencesServiceProvider);
    final owner = prefs.getSyncRepoOwner();
    final repo = prefs.getSyncRepoName();

    if (owner == null || repo == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未配置同步仓库',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: '正在从 GitHub 导入笔记...',
    );

    try {
      final remoteNotes = await syncService.pullNotes(
        owner: owner,
        repo: repo,
      );

      if (remoteNotes.isEmpty) {
        state = state.copyWith(
          status: SyncStatus.success,
          message: '远程仓库没有笔记',
        );
        return;
      }

      final repository = _ref.read(noteRepositoryProvider);
      for (final note in remoteNotes) {
        await repository.addNote(note);
      }

      state = state.copyWith(
        status: SyncStatus.success,
        message: '成功导入 ${remoteNotes.length} 条笔记',
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '导入失败: $e',
      );
    }
  }

  /// 检测并填充冲突列表
  ///
  /// - 拉取远端笔记
  /// - 读取本地 lastSyncedAt
  /// - 调用 [SyncService.detectConflicts] 得到冲突项
  /// - 把冲突放进 state，UI 可导航到冲突解决页
  ///
  /// 返回检测到的冲突数量。
  Future<int> detectAndStoreConflicts() async {
    final syncService = _ref.read(syncServiceProvider);
    if (syncService == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未登录 GitHub',
      );
      return 0;
    }
    final prefs = _ref.read(preferencesServiceProvider);
    final owner = prefs.getSyncRepoOwner();
    final repo = prefs.getSyncRepoName();
    if (owner == null || repo == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未配置同步仓库',
      );
      return 0;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: '正在检测冲突...',
    );

    try {
      final notesAsync = _ref.read(notesProvider);
      final localNotes = notesAsync.maybeWhen(
        data: (n) => n,
        orElse: () => <NoteModel>[],
      );
      final remoteNotes = await syncService.pullNotes(
        owner: owner,
        repo: repo,
      );
      final lastSyncedAt = prefs.getLastSyncedAt();
      final conflicts = SyncService.detectConflicts(
        localNotes: localNotes,
        remoteNotes: remoteNotes,
        lastSyncedAt: lastSyncedAt,
      );
      state = state.copyWith(
        status: conflicts.isEmpty ? SyncStatus.success : SyncStatus.idle,
        message: conflicts.isEmpty
            ? '没有发现冲突'
            : '检测到 ${conflicts.length} 条冲突，请逐条选择保留版本',
        conflicts: conflicts,
        pendingResolutions: const <String, ConflictResolution>{},
      );
      return conflicts.length;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '冲突检测失败: $e',
      );
      return 0;
    }
  }

  /// 对单条冲突设置解决方案
  void setResolution(String noteId, ConflictResolution resolution) {
    final next = Map<String, ConflictResolution>.from(state.pendingResolutions);
    if (resolution == ConflictResolution.skip) {
      next.remove(noteId);
    } else {
      next[noteId] = resolution;
    }
    state = state.copyWith(pendingResolutions: next);
  }

  /// 应用所有已解决的冲突
  ///
  /// - localWins → 写回本地后推送到 GitHub
  /// - remoteWins → 写回本地（覆盖本地版本）
  /// - skip → 不处理
  ///
  /// 返回处理结果摘要。完成后清空 conflicts。
  Future<({int localWins, int remoteWins, int skipped, List<String> errors})>
      applyResolutions() async {
    final syncService = _ref.read(syncServiceProvider);
    final prefs = _ref.read(preferencesServiceProvider);
    final owner = prefs.getSyncRepoOwner();
    final repo = prefs.getSyncRepoName();
    if (syncService == null || owner == null || repo == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: '未登录或未配置仓库，无法应用冲突解决',
      );
      return (localWins: 0, remoteWins: 0, skipped: 0, errors: <String>[]);
    }
    if (state.pendingResolutions.isEmpty) {
      state = state.copyWith(
        status: SyncStatus.success,
        message: '没有已解决的冲突',
      );
      return (localWins: 0, remoteWins: 0, skipped: 0, errors: <String>[]);
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: '正在应用冲突解决...',
    );

    final repo_ = _ref.read(noteRepositoryProvider);
    int localWins = 0;
    int remoteWins = 0;
    final skipped = state.conflicts.length - state.pendingResolutions.length;
    final errors = <String>[];

    for (final entry in state.pendingResolutions.entries) {
      final conflict = state.conflicts.firstWhere(
        (c) => c.noteId == entry.key,
        orElse: () => state.conflicts.first,
      );
      try {
        switch (entry.value) {
          case ConflictResolution.localWins:
            await repo_.updateNote(conflict.local);
            await syncService.pushNote(
              owner: owner,
              repo: repo,
              note: conflict.local,
            );
            localWins++;
          case ConflictResolution.remoteWins:
            await repo_.updateNote(conflict.remote);
            remoteWins++;
          case ConflictResolution.skip:
            // skip 不在 pendingResolutions 中，无需处理
            break;
        }
      } catch (e) {
        errors.add('${conflict.title}: $e');
      }
    }

    state = state.copyWith(
      status: errors.isEmpty ? SyncStatus.success : SyncStatus.error,
      message: errors.isEmpty
          ? '冲突解决完成: 本地 $localWins 条, 远端 $remoteWins 条, 跳过 $skipped 条'
          : '冲突解决出错: ${errors.join("; ")}',
      conflicts: const <SyncConflictItem>[],
      pendingResolutions: const <String, ConflictResolution>{},
      lastSyncTime: DateTime.now(),
    );
    return (
      localWins: localWins,
      remoteWins: remoteWins,
      skipped: skipped,
      errors: errors,
    );
  }

  /// 清空冲突状态（用户主动放弃）
  void clearConflicts() {
    state = state.copyWith(
      conflicts: const <SyncConflictItem>[],
      pendingResolutions: const <String, ConflictResolution>{},
      message: '已取消冲突解决',
    );
  }

  /// 设置同步仓库
  Future<void> setSyncRepo(String owner, String repo) async {
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.setSyncRepoOwner(owner);
    await prefs.setSyncRepoName(repo);
  }

  /// 获取同步仓库配置
  ({String? owner, String? repo}) getSyncRepo() {
    final prefs = _ref.read(preferencesServiceProvider);
    return (owner: prefs.getSyncRepoOwner(), repo: prefs.getSyncRepoName());
  }
}

/// 同步状态 Provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

/// 是否已登录 GitHub
final isGitHubLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(githubTokenProvider) != null;
});
