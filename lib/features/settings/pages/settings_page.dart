import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);
    final locale = ref.watch(appLocaleProvider);
    final isEncrypted = ref.watch(encryptionStatusProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ── 外观 ──
          _SectionHeader(title: l10n.appearanceSection),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.themeModeLabel),
            subtitle: Text(_themeModeLabel(themeMode, l10n)),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 16),
                  tooltip: l10n.themeModeLight,
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.settings_brightness, size: 16),
                  tooltip: l10n.themeModeSystem,
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 16),
                  tooltip: l10n.themeModeDark,
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
            title: Text(l10n.seedColorLabel),
            subtitle: Text(_seedColorLabel(seedColor)),
            trailing: CircleAvatar(
              backgroundColor: seedColor,
              radius: 14,
            ),
            onTap: () => _showSeedColorPicker(context, ref, seedColor),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.languageLabel),
            subtitle: Text(_localeLabel(locale, l10n)),
            trailing: PopupMenuButton<Locale?>(
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.languageLabel,
              initialValue: locale,
              onSelected: (newLocale) =>
                  ref.read(appLocaleProvider.notifier).setLocale(newLocale),
              itemBuilder: (context) => [
                PopupMenuItem<Locale?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        locale == null ? Icons.check : Icons.radio_button_unchecked,
                        size: 18,
                        color: locale == null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.languageFollowSystem),
                    ],
                  ),
                ),
                PopupMenuItem<Locale?>(
                  value: const Locale('en'),
                  child: Row(
                    children: [
                      Icon(
                        locale?.languageCode == 'en'
                            ? Icons.check
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: locale?.languageCode == 'en'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.languageEnglish),
                    ],
                  ),
                ),
                PopupMenuItem<Locale?>(
                  value: const Locale('zh'),
                  child: Row(
                    children: [
                      Icon(
                        locale?.languageCode == 'zh'
                            ? Icons.check
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: locale?.languageCode == 'zh'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.languageChinese),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // ── 同步 ──
          _SectionHeader(title: l10n.syncSection),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.githubSync),
            subtitle: Text(l10n.githubSyncSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRouter.syncSettings),
          ),
          ListTile(
            leading: Icon(
              isEncrypted ? Icons.lock : Icons.lock_open,
              color: isEncrypted ? colorScheme.primary : colorScheme.error,
            ),
            title: Text(l10n.encryptionSettings),
            subtitle: Text(
              isEncrypted ? l10n.encryptionEnabled : l10n.encryptionDisabled,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEncryptionInfo(context, isEncrypted, l10n),
          ),
          const Divider(height: 32),

          // ── 数据管理 ──
          _SectionHeader(title: l10n.dataManagementSection),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.tagManagement),
            subtitle: Text(l10n.tagManagementSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRouter.tagManagement),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.recycleBin),
            subtitle: Text(l10n.recycleBinSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRouter.trash),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l10n.exportNotes),
            subtitle: Text(l10n.exportNotesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportNotes(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l10n.importNotes),
            subtitle: Text(l10n.importNotesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showComingSoon(context, l10n, l10n.importNotes),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: colorScheme.error,
            ),
            title: Text(
              l10n.clearAllNotes,
              style: TextStyle(color: colorScheme.error),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearConfirm(context, ref, l10n),
          ),
          const Divider(height: 32),

          // ── 关于 ──
          _SectionHeader(title: l10n.aboutSection),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            trailing: Text(
              appVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.githubRepo),
            subtitle: const Text(githubRepoUrl),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _showRepoInfo(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.openSourceLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenses(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.light => l10n.themeModeLight,
      ThemeMode.dark => l10n.themeModeDark,
      ThemeMode.system => l10n.themeModeSystem,
    };
  }

  String _localeLabel(Locale? locale, AppLocalizations l10n) {
    return switch (locale?.languageCode) {
      'en' => l10n.languageEnglish,
      'zh' => l10n.languageChinese,
      _ => l10n.languageFollowSystem,
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

  void _showEncryptionInfo(BuildContext context, bool isEncrypted, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.encryptionSettings),
        content: Text(
          isEncrypted
              ? '${l10n.encryptionEnabled}。\n\n'
                  '本地敏感数据（如 GitHub OAuth Token）使用 '
                  'AES-256-CBC 模式加密存储，每次加密使用独立随机 IV。\n\n'
                  '密钥安全存储在设备本地。'
              : '${l10n.encryptionDisabled}。\n\n'
                  '首次使用加密功能时将自动生成密钥。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature ${l10n.comingSoon}')),
    );
  }

  Future<void> _exportNotes(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final notesAsync = ref.read(notesProvider);
    final notes = notesAsync.valueOrNull ?? [];

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noNotesToExport)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exportingInProgress)),
    );

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAllNotes(notes);

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exportComplete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exportSuccessCount(result.success, result.total)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.exportFailedCount(result.failed),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.exportPath),
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
                  SnackBar(content: Text(l10n.exportPathCopied)),
                );
              },
              child: Text(l10n.copyPathAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.doneAction),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  void _showClearConfirm(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllConfirmTitle),
        content: Text(l10n.clearAllConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notesProvider.notifier).clearAllNotes();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.clearAllNotesSuccess)),
              );
            },
            child: Text(l10n.clearAllConfirmAction),
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
