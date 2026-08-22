import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_animations.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/note_model.dart';
import '../../../services/service_providers.dart';

/// 笔记卡片组件
///
/// 在列表中展示单条笔记的标题、摘要、标签和更新时间。
/// 支持点击进入编辑、长按进入多选模式。
/// 多选模式下显示复选框和选中高亮。
/// 标签 chip 根据 `TagMetadataService` 配置染色。
class NoteCard extends ConsumerWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showCheckbox = false,
    this.compact = false,
  });

  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showCheckbox;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MM/dd HH:mm');
    final tagMetadata = ref.watch(tagMetadataServiceProvider);
    final padding = compact ? AppSpacing.xs + 2 : AppSpacing.md;

    return AppAnimations.noteHero(
      noteId: note.id,
      child: Material(
        type: MaterialType.transparency,
        child: Card(
      color: isSelected ? colorScheme.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheckbox) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                            opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 标题行 ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? '无标题' : note.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _PriorityDot(priority: note.priority),
                      ],
                    ),
                    // ── 摘要（紧凑模式下隐藏摘要与标签） ──
                    if (!compact && note.content.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        note.excerpt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // ── 底部信息行 ──
                    SizedBox(height: compact ? AppSpacing.xxs + 2 : AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          dateFormat.format(note.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        if (!compact && note.tags.isNotEmpty)
                          _TagChips(
                            tags: note.tags.take(3).toList(),
                            colorResolver: tagMetadata.getTagColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

/// 优先级指示点
class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final NotePriority priority;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: switch (priority) {
        NotePriority.low => '低优先级',
        NotePriority.medium => '中优先级',
        NotePriority.high => '高优先级',
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (priority) {
            NotePriority.low => AppColors.priorityLow,
            NotePriority.medium => AppColors.priorityMedium,
            NotePriority.high => AppColors.priorityHigh,
          },
        ),
      ),
    );
  }
}

/// 标签芯片组
class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags, required this.colorResolver});

  final List<String> tags;
  final Color Function(String) colorResolver;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final luminance = Theme.of(context).brightness == Brightness.dark
        ? 0.25
        : 0.18;

    return Wrap(
      spacing: AppSpacing.xxs,
      children: tags.map((tag) {
        final color = colorResolver(tag);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(color, colorScheme.surface, luminance),
            borderRadius: BorderRadius.circular(AppRadius.sm - 2),
          ),
          child: Text(
            '#$tag',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }
}
