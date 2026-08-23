import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../data/models/outline_node.dart';
import '../services/outline_service.dart';

/// 大纲面板
///
/// 从笔记 Markdown 文本中解析出 heading 列表并以缩进形式展示。
/// 用户点击某个 heading 触发 [onJumpToOffset]，编辑器可滚动并高亮对应行。
class OutlinePanel extends StatelessWidget {
  const OutlinePanel({
    super.key,
    required this.content,
    this.service = const OutlineService(),
    this.onJumpToOffset,
  });

  final String content;
  final OutlineService service;
  final void Function(int offset)? onJumpToOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flat = service.flatten(content);

    if (flat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '暂无大纲（添加 # 标题后将自动出现）',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: flat.length,
      itemBuilder: (context, index) {
        final node = flat[index];
        return _OutlineTile(
          node: node,
          onTap: () => onJumpToOffset?.call(node.startOffset),
        );
      },
    );
  }
}

class _OutlineTile extends StatelessWidget {
  const _OutlineTile({required this.node, required this.onTap});

  final OutlineNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final indent = AppSpacing.sm * node.depth;
    final size = switch (node.level) {
      1 => theme.textTheme.titleMedium,
      2 => theme.textTheme.titleSmall,
      _ => theme.textTheme.bodyMedium,
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          indent + AppSpacing.sm,
          AppSpacing.xxs,
          AppSpacing.sm,
          AppSpacing.xxs,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(
                color: _accentColor(colorScheme, node.level),
                borderRadius: AppRadius.allXs,
              ),
            ),
            Expanded(
              child: Text(
                node.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: size?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: node.level <= 2 ? FontWeight.w600 : null,
                ),
              ),
            ),
            Text(
              'H${node.level}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(ColorScheme cs, int level) {
    return switch (level) {
      1 => cs.primary,
      2 => cs.primary.withValues(alpha: 0.7),
      3 => cs.secondary,
      _ => cs.outline,
    };
  }
}
