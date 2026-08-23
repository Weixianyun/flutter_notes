import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../services/backlink_index.dart';

/// 反向链接面板
///
/// 根据笔记标题查询 [BacklinkIndex]，展示所有引用了当前笔记的条目。
/// 用户点击某条记录触发 [onOpenSource]，编辑器可跳转到源笔记。
class BacklinksPanel extends StatelessWidget {
  const BacklinksPanel({
    super.key,
    required this.targetTitle,
    required this.index,
    this.onOpenSource,
  });

  final String targetTitle;
  final BacklinkIndex index;
  final void Function(BacklinkEntry entry)? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = index.findBacklinks(targetTitle);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '暂无反向链接。在其他笔记中使用 [[${targetTitle.isEmpty ? '当前笔记' : targetTitle}]] 即可在此显示。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: entries.length * 2 - 1,
        itemBuilder: (context, i) {
          if (i.isOdd) {
            return const Divider(height: 1);
          }
          final entry = entries[i ~/ 2];
          return _BacklinkTile(
            entry: entry,
            onTap: () => onOpenSource?.call(entry),
          );
        },
      ),
    );
  }
}

class _BacklinkTile extends StatelessWidget {
  const _BacklinkTile({required this.entry, required this.onTap});

  final BacklinkEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(Icons.arrow_back, color: colorScheme.primary, size: 18),
      title: Text(
        entry.sourceTitle,
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entry.link.displayText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
