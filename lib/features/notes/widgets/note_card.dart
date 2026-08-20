import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/note_model.dart';

/// 笔记卡片组件
///
/// 在列表中展示单条笔记的标题、摘要、标签和更新时间。
/// 支持点击进入编辑、长按进入多选模式。
/// 多选模式下显示复选框和选中高亮。
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showCheckbox = false,
  });

  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Card(
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheckbox) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PriorityDot(priority: note.priority),
                      ],
                    ),
                    // ── 摘要 ──
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(note.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        if (note.tags.isNotEmpty)
                          _TagChips(tags: note.tags.take(3).toList()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
          ),
        );
      }).toList(),
    );
  }
}
