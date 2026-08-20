import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../services/sync_service.dart';
import '../providers/sync_provider.dart';

/// 同步设置页面
///
/// 管理 GitHub 登录状态、同步仓库配置和笔记同步操作。
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  late final TextEditingController _ownerController;
  late final TextEditingController _repoController;

  @override
  void initState() {
    super.initState();
    final sync = ref.read(syncProvider.notifier);
    final repo = sync.getSyncRepo();
    _ownerController = TextEditingController(text: repo.owner ?? '');
    _repoController = TextEditingController(text: repo.repo ?? '');
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('GitHub 同步')),
      body: ListView(
        children: [
          // ── 账户状态 ──
          _SectionHeader(title: '账户', colorScheme: colorScheme),
          if (syncState.user != null)
            _buildUserInfo(syncState, colorScheme)
          else
            _buildLoginPrompt(colorScheme),
          const Divider(height: 32),

          // ── 同步仓库 ──
          _SectionHeader(title: '同步仓库', colorScheme: colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: '仓库所有者',
                    hintText: 'GitHub 用户名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _repoController,
                  decoration: const InputDecoration(
                    labelText: '仓库名称',
                    hintText: '例如: my_notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saveRepoConfig,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('保存配置'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // ── 同步操作 ──
          _SectionHeader(title: '同步', colorScheme: colorScheme),
          if (syncState.lastSyncTime != null)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('上次同步'),
              trailing: Text(
                _formatTime(syncState.lastSyncTime!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (syncState.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: syncState.status == SyncStatus.error
                      ? colorScheme.errorContainer
                      : syncState.status == SyncStatus.success
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      syncState.status == SyncStatus.error
                          ? Icons.error_outline
                          : syncState.status == SyncStatus.success
                              ? Icons.check_circle_outline
                              : Icons.sync,
                      size: 20,
                      color: syncState.status == SyncStatus.error
                          ? colorScheme.onErrorContainer
                          : syncState.status == SyncStatus.success
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncState.message!,
                        style: TextStyle(
                          color: syncState.status == SyncStatus.error
                              ? colorScheme.onErrorContainer
                              : syncState.status == SyncStatus.success
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ListTile(
            leading: syncState.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            title: const Text('立即同步'),
            subtitle: const Text('推送所有笔记到 GitHub'),
            enabled: syncState.user != null &&
                syncState.status != SyncStatus.syncing,
            onTap: () => ref.read(syncProvider.notifier).syncAllNotes(),
          ),
          ListTile(
            leading: syncState.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: const Text('导入笔记'),
            subtitle: const Text('从 GitHub 仓库拉取笔记到本地'),
            enabled: syncState.user != null &&
                syncState.status != SyncStatus.syncing,
            onTap: () => ref.read(syncProvider.notifier).importNotes(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserInfo(SyncState syncState, ColorScheme colorScheme) {
    final user = syncState.user!;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          user.login.isNotEmpty ? user.login[0].toUpperCase() : '?',
          style: TextStyle(color: colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(user.name.isNotEmpty ? user.name : user.login),
      subtitle: Text('@${user.login}'),
      trailing: TextButton.icon(
        onPressed: () async {
          await ref.read(syncProvider.notifier).logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已退出 GitHub 登录')),
            );
          }
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('退出'),
        style: TextButton.styleFrom(foregroundColor: colorScheme.error),
      ),
    );
  }

  Widget _buildLoginPrompt(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: colorScheme.outline),
          const SizedBox(height: 12),
          const Text('未登录 GitHub'),
          const SizedBox(height: 4),
          Text(
            '登录后可将笔记同步到 GitHub 仓库',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final result = await context.push<bool>(
                AppRouter.githubLogin,
              );
              if (result == true && mounted) {
                await ref.read(syncProvider.notifier).fetchUser();
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('登录 GitHub'),
          ),
        ],
      ),
    );
  }

  void _saveRepoConfig() {
    final owner = _ownerController.text.trim();
    final repo = _repoController.text.trim();
    if (owner.isEmpty || repo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整仓库信息')),
      );
      return;
    }
    ref.read(syncProvider.notifier).setSyncRepo(owner, repo);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仓库配置已保存')),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colorScheme});

  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
