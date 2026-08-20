import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../notes/providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../../../services/service_providers.dart';

/// 设置页面
///
/// 包含外观设置（主题模式）、同步设置（GitHub OAuth）、
/// 数据管理和关于信息四个分区。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);
    final isEncrypted = ref.watch(encryptionStatusProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── 外观 ──
          const _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (set) =>
                  ref.read(themeModeProvider.notifier).setMode(set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('主题色'),
            subtitle: Text(_seedColorLabel(seedColor)),
            trailing: CircleAvatar(
              backgroundColor: seedColor,
              radius: 14,
            ),
            onTap: () => _showSeedColorPicker(context, ref, seedColor),
          ),
          const Divider(height: 32),

          // ── 同步 ──
          const _SectionHeader(title: '云同步'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('GitHub 同步'),
            subtitle: const Text('将笔记同步到 GitHub 仓库'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRouter.syncSettings),
          ),
          ListTile(
            leading: Icon(
              isEncrypted ? Icons.lock : Icons.lock_open,
              color: isEncrypted ? colorScheme.primary : colorScheme.error,
            ),
            title: const Text('加密设置'),
            subtitle: Text(
              isEncrypted ? 'AES-256 加密已启用' : '加密未启用',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEncryptionInfo(context, isEncrypted),
          ),
          const Divider(height: 32),

          // ── 数据管理 ──
          const _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('回收站'),
            subtitle: const Text('查看和恢复已删除的笔记'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRouter.trash),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导出笔记'),
            subtitle: const Text('导出为 Markdown 文件'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportNotes(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导入笔记'),
            subtitle: const Text('从 Markdown 文件导入'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showComingSoon(context, '导入功能'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: colorScheme.error,
            ),
            title: Text(
              '清空所有笔记',
              style: TextStyle(color: colorScheme.error),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearConfirm(context, ref),
          ),
          const Divider(height: 32),

          // ── 关于 ──
          const _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: Text(
              appVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub 仓库'),
            subtitle: const Text(githubRepoUrl),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _showRepoInfo(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('开源许可'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenses(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => '浅色模式',
      ThemeMode.dark => '深色模式',
      ThemeMode.system => '跟随系统',
    };
  }

  String _seedColorLabel(Color color) {
    for (final option in AppColors.seedColorOptions) {
      if (option.color.toARGB32() == color.toARGB32()) {
        return option.name;
      }
    }
    return '自定义';
  }

  void _showSeedColorPicker(BuildContext context, WidgetRef ref, Color current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择主题色',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: AppColors.seedColorOptions.map((option) {
                  final isSelected =
                      option.color.toARGB32() == current.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(seedColorProvider.notifier)
                          .setColor(option.color);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEncryptionInfo(BuildContext context, bool isEncrypted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加密设置'),
        content: Text(
          isEncrypted
              ? 'AES-256 加密已启用。\n\n'
                  '本地敏感数据（如 GitHub OAuth Token）使用 '
                  'AES-256-CBC 模式加密存储，每次加密使用独立随机 IV。\n\n'
                  '密钥安全存储在设备本地。'
              : '加密未启用。\n\n'
                  '首次使用加密功能时将自动生成密钥。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature即将推出')),
    );
  }

  Future<void> _exportNotes(BuildContext context, WidgetRef ref) async {
    final notesAsync = ref.read(notesProvider);
    final notes = notesAsync.valueOrNull ?? [];

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有笔记可导出')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在导出...')),
    );

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAllNotes(notes);

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('成功导出 ${result.success}/${result.total} 篇笔记'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '失败 ${result.failed} 篇',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              const Text('导出路径：'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.directoryPath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: result.directoryPath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('路径已复制到剪贴板')),
                );
              },
              child: const Text('复制路径'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  void _showClearConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有笔记？'),
        content: const Text('此操作不可撤销，所有笔记将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notesProvider.notifier).clearAllNotes();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空所有笔记')),
              );
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _showRepoInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请在浏览器中访问: github.com/Weixianyun/flutter_notes'),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Flutter Notes',
      applicationVersion: appVersion,
    );
  }
}

/// 分区标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
