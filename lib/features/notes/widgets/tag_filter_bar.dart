import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../providers/tags_provider.dart';

/// 标签过滤栏
///
/// 水平滚动的标签芯片列表，支持多选过滤。
/// 点击「全部」清除所有选中标签。
/// 标签使用 `TagInfo.color` 染色，提升视觉识别。
class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: AppSpacing.xxxl,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 「全部」按钮
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.xxs,
                    top: AppSpacing.xxs,
                    bottom: AppSpacing.xxs,
                  ),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: selectedTags.isEmpty,
                    onSelected: (_) =>
                        ref.read(selectedTagsProvider.notifier).clear(),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                  ),
                ),
                // 标签列表
                for (final tag in tags)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.xxs,
                      top: AppSpacing.xxs,
                      bottom: AppSpacing.xxs,
                    ),
                    child: FilterChip(
                      avatar: Container(
                        width: AppRadius.xs * 2,
                        height: AppRadius.xs * 2,
                        decoration: BoxDecoration(
                          color: tag.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text(
                        '${tag.name} (${tag.count})',
                        style: TextStyle(
                          fontSize: AppFontSizes.bodySmall,
                          color: selectedTags.contains(tag.name)
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: selectedTags.contains(tag.name),
                      onSelected: (_) =>
                          ref.read(selectedTagsProvider.notifier).toggle(tag.name),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
