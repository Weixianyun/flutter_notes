import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../services/service_providers.dart';
import 'notes_provider.dart';

/// 标签信息（含颜色）
class TagInfo {
  const TagInfo({
    required this.name,
    required this.count,
    this.color,
  });

  final String name;
  final int count;
  final Color? color;

  TagInfo copyWith({String? name, int? count, Color? color}) {
    return TagInfo(
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
    );
  }

  @override
  String toString() => 'TagInfo($name: $count)';
}

/// 全部标签集合（含颜色元数据）
///
/// 监听 [notesProvider] 与 [tagMetadataServiceProvider]，
/// 从所有笔记中提取去重标签并附加颜色配置，
/// 按使用频率降序排列。返回 [AsyncValue] 以适配异步笔记加载。
final allTagsProvider = Provider<AsyncValue<List<TagInfo>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final tagMetadata = ref.watch(tagMetadataServiceProvider);

  return notesAsync.whenData((notes) {
    final tagCount = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    return tagCount.entries
        .map((e) => TagInfo(
              name: e.key,
              count: e.value,
              color: tagMetadata.getTagColor(e.key),
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  });
});

/// 选中标签状态管理
class SelectedTagsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String tag) {
    final newSet = Set<String>.from(state);
    if (newSet.contains(tag)) {
      newSet.remove(tag);
    } else {
      newSet.add(tag);
    }
    state = newSet;
  }

  void select(String tag) {
    state = {tag};
  }

  void clear() => state = {};

  bool isSelected(String tag) => state.contains(tag);
}

final selectedTagsProvider =
    NotifierProvider<SelectedTagsNotifier, Set<String>>(
  SelectedTagsNotifier.new,
);

/// 按标签过滤的笔记列表
final filteredNotesProvider = Provider<AsyncValue<List<NoteModel>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final selectedTags = ref.watch(selectedTagsProvider);

  return notesAsync.whenData((notes) {
    if (selectedTags.isEmpty) return notes;
    return notes
        .where((note) => note.tags.any((t) => selectedTags.contains(t)))
        .toList();
  });
});

/// 标签管理 Notifier
///
/// 提供标签的 CRUD 与颜色管理能力。
/// - [createTag]: 创建新标签（仅保存颜色配置，需手动添加到笔记）
/// - [deleteTag]: 从所有笔记中移除该标签并清除颜色配置
/// - [renameTag]: 重命名标签（更新所有笔记中的标签名）
/// - [setColor]: 设置标签颜色
/// - [resetColor]: 重置标签颜色（恢复默认）
class TagsManagerNotifier extends Notifier<void> {
  @override
  void build() {}

  /// 创建新标签
  ///
  /// 仅注册颜色配置，不会自动添加到任何笔记。
  /// 调用方需在笔记中引用该标签使其可见。
  Future<void> createTag(String name, {Color? color}) async {
    final service = ref.read(tagMetadataServiceProvider);
    if (color != null) {
      await service.setTagColor(name, color);
    }
  }

  /// 删除标签
  ///
  /// 从所有笔记的 tags 列表中移除该标签，并清除其颜色配置。
  /// 操作不可撤销（除手动从回收站恢复外）。
  Future<int> deleteTag(String name) async {
    final notesAsync = ref.read(notesProvider);
    final notes = notesAsync.valueOrNull ?? [];
    final notesNotifier = ref.read(notesProvider.notifier);
    final service = ref.read(tagMetadataServiceProvider);

    var affectedCount = 0;
    for (final note in notes) {
      if (note.tags.contains(name)) {
        final newTags = note.tags.where((t) => t != name).toList();
        await notesNotifier.updateNote(
          note.copyWith(tags: newTags, updatedAt: DateTime.now()),
        );
        affectedCount++;
      }
    }

    await service.removeTagColor(name);
    return affectedCount;
  }

  /// 重命名标签
  ///
  /// 更新所有引用该标签的笔记。空名称或与现有标签同名时拒绝操作。
  /// 返回受影响的笔记数。
  Future<int> renameTag(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('标签名不能为空');
    }
    if (trimmed == oldName) return 0;

    final tagsAsync = ref.read(allTagsProvider);
    final existingNames =
        tagsAsync.valueOrNull?.map((t) => t.name).toSet() ?? <String>{};
    if (existingNames.contains(trimmed)) {
      throw StateError('标签「$trimmed」已存在');
    }

    final notesAsync = ref.read(notesProvider);
    final notes = notesAsync.valueOrNull ?? [];
    final notesNotifier = ref.read(notesProvider.notifier);
    final service = ref.read(tagMetadataServiceProvider);

    final oldColor = service.getTagColor(oldName);
    var affectedCount = 0;
    for (final note in notes) {
      if (note.tags.contains(oldName)) {
        final newTags = note.tags
            .map((t) => t == oldName ? trimmed : t)
            .toList();
        await notesNotifier.updateNote(
          note.copyWith(tags: newTags, updatedAt: DateTime.now()),
        );
        affectedCount++;
      }
    }

    await service.removeTagColor(oldName);
    await service.setTagColor(trimmed, oldColor);
    return affectedCount;
  }

  /// 设置标签颜色
  Future<void> setColor(String name, Color color) async {
    final service = ref.read(tagMetadataServiceProvider);
    await service.setTagColor(name, color);
  }

  /// 重置标签颜色（恢复默认紫色）
  Future<void> resetColor(String name) async {
    final service = ref.read(tagMetadataServiceProvider);
    await service.removeTagColor(name);
  }
}

final tagsManagerProvider =
    NotifierProvider<TagsManagerNotifier, void>(TagsManagerNotifier.new);
