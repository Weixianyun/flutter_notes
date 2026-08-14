import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import 'notes_provider.dart';

/// 全部标签集合
///
/// 监听 [notesProvider]，从所有笔记中提取去重标签，
/// 按使用频率降序排列。
final allTagsProvider = Provider<List<TagInfo>>((ref) {
  final notes = ref.watch(notesProvider);
  final tagCount = <String, int>{};

  for (final note in notes) {
    for (final tag in note.tags) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }

  return tagCount.entries
      .map((e) => TagInfo(name: e.key, count: e.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
});

/// 选中标签状态管理
class SelectedTagsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  /// 切换标签选中状态
  void toggle(String tag) {
    final newSet = Set<String>.from(state);
    if (newSet.contains(tag)) {
      newSet.remove(tag);
    } else {
      newSet.add(tag);
    }
    state = newSet;
  }

  /// 设置选中标签（单选模式）
  void select(String tag) {
    state = {tag};
  }

  /// 清空选中标签
  void clear() => state = {};

  /// 判断是否选中
  bool isSelected(String tag) => state.contains(tag);
}

/// 选中标签 Provider
final selectedTagsProvider =
    NotifierProvider<SelectedTagsNotifier, Set<String>>(
  SelectedTagsNotifier.new,
);

/// 按标签过滤的笔记列表
///
/// 若无选中标签，返回全部笔记；否则返回包含任一选中标签的笔记。
final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  final selectedTags = ref.watch(selectedTagsProvider);

  if (selectedTags.isEmpty) return notes;

  return notes
      .where((note) => note.tags.any((t) => selectedTags.contains(t)))
      .toList();
});

/// 标签信息
class TagInfo {
  const TagInfo({required this.name, required this.count});

  final String name;
  final int count;

  @override
  String toString() => 'TagInfo($name: $count)';
}
