import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/design_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// 开发者选项页面
///
/// 暴露设计 token 常量（间距、圆角、动画时长、字号、行高）供开发 / 设计
/// 同学在运行时查阅。点击 token 值可复制到剪贴板。
///
/// 不参与生产行为，仅作为调试辅助。
class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('开发者选项')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          const _SectionHeader(title: '设计 Token 速查'),
          const _TokenGroup(
            title: 'AppSpacing (8 倍数阶梯)',
            entries: [
              _TokenEntry('xxs', '4'),
              _TokenEntry('xs', '8'),
              _TokenEntry('sm', '12'),
              _TokenEntry('md', '16'),
              _TokenEntry('lg', '20'),
              _TokenEntry('xl', '24'),
              _TokenEntry('xxl', '32'),
              _TokenEntry('xxxl', '48'),
              _TokenEntry('huge', '64'),
            ],
          ),
          const _TokenGroup(
            title: 'AppRadius (5 档)',
            entries: [
              _TokenEntry('xs', '4'),
              _TokenEntry('sm', '8'),
              _TokenEntry('md', '12'),
              _TokenEntry('lg', '16'),
              _TokenEntry('xl', '28'),
            ],
          ),
          const _TokenGroup(
            title: 'AppDurations (毫秒)',
            entries: [
              _TokenEntry('fast', '150'),
              _TokenEntry('medium', '280'),
              _TokenEntry('slow', '400'),
              _TokenEntry('stagger', '420'),
            ],
          ),
          const _TokenGroup(
            title: 'AppLineHeights',
            entries: [
              _TokenEntry('display', '1.2'),
              _TokenEntry('title', '1.25'),
              _TokenEntry('body', '1.5'),
              _TokenEntry('label', '1.4'),
            ],
          ),
          const _TokenGroup(
            title: 'AppFontSizes (选)',
            entries: [
              _TokenEntry('displayLarge', '57'),
              _TokenEntry('headlineLarge', '32'),
              _TokenEntry('titleLarge', '22'),
              _TokenEntry('titleMedium', '16'),
              _TokenEntry('bodyLarge', '16'),
              _TokenEntry('bodyMedium', '14'),
              _TokenEntry('labelLarge', '14'),
              _TokenEntry('labelSmall', '11'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _SectionHeader(title: '设计 token 用途说明'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('所有页面间距 / 圆角 / 字号必须从 token 读取'),
            subtitle: Text(l10n.appTitle),
            isThreeLine: true,
          ),
          const ListTile(
            leading: Icon(Icons.bookmark_border),
            title: Text('源码位置'),
            subtitle: Text('lib/core/design/design_tokens.dart'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TokenGroup extends StatelessWidget {
  const _TokenGroup({required this.title, required this.entries});

  final String title;
  final List<_TokenEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (var i = 0; i < entries.length; i++) ...[
            ListTile(
              dense: true,
              title: Text(entries[i].name),
              trailing: Text(
                entries[i].value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              onTap: () => _copyToClipboard(
                context,
                '${entries[i].name} = ${entries[i].value}',
              ),
            ),
            if (i < entries.length - 1)
              const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已复制: $value'),
          duration: AppDurations.slow,
        ),
      );
  }
}

class _TokenEntry {
  const _TokenEntry(this.name, this.value);
  final String name;
  final String value;
}
