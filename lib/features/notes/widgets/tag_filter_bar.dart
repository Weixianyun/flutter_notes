import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tags_provider.dart';

/// 标签过滤栏
///
/// 水平滚动的标签芯片列表，支持多选过滤。
/// 点击「全部」清除所有选中标签。
class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(allTagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 「全部」按钮
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
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
              padding:
                  const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: FilterChip(
                label: Text(
                  '${tag.name} (${tag.count})',
                  style: TextStyle(
                    fontSize: 12,
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
    );
  }
}
