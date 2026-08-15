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
  });

  final SyncStatus status;
  final GitHubUser? user;
  final DateTime? lastSyncTime;
  final String? message;

  SyncState copyWith({
    SyncStatus? status,
    GitHubUser? user,
    DateTime? lastSyncTime,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      user: user ?? this.user,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      message: message ?? this.message,
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
