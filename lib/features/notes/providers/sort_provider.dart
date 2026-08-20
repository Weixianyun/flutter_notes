import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import 'tags_provider.dart';

/// 笔记排序方式
enum NoteSortOrder {
  /// 按更新时间倒序（默认）
  updatedAtDesc,

  /// 按创建时间倒序
  createdAtDesc,

  /// 按创建时间正序
  createdAtAsc,

  /// 按标题字母升序
  titleAsc,

  /// 按优先级降序
  priorityDesc,
}

/// 排序方式 i18n key 映射
extension NoteSortOrderL10nKey on NoteSortOrder {
  String get l10nKey {
    return switch (this) {
      NoteSortOrder.updatedAtDesc => 'sortUpdatedAtDesc',
      NoteSortOrder.createdAtDesc => 'sortCreatedAtDesc',
      NoteSortOrder.createdAtAsc => 'sortCreatedAtAsc',
      NoteSortOrder.titleAsc => 'sortTitleAsc',
      NoteSortOrder.priorityDesc => 'sortPriorityDesc',
    };
  }

  /// 默认中文标签（兼容旧调用方与单元测试）
  String get label {
    return switch (this) {
      NoteSortOrder.updatedAtDesc => '最近修改',
      NoteSortOrder.createdAtDesc => '最新创建',
      NoteSortOrder.createdAtAsc => '最早创建',
      NoteSortOrder.titleAsc => '标题 A→Z',
      NoteSortOrder.priorityDesc => '优先级高→低',
    };
  }
}

/// 笔记排序方式 Provider
class NoteSortOrderNotifier extends Notifier<NoteSortOrder> {
  @override
  NoteSortOrder build() => NoteSortOrder.updatedAtDesc;

  void setOrder(NoteSortOrder order) {
    state = order;
  }
}

final noteSortOrderProvider =
    NotifierProvider<NoteSortOrderNotifier, NoteSortOrder>(
  NoteSortOrderNotifier.new,
);

/// 排序后的笔记列表
///
/// 在 [filteredNotesProvider] 基础上应用当前排序方式。
final sortedNotesProvider = Provider<AsyncValue<List<NoteModel>>>((ref) {
  final filtered = ref.watch(filteredNotesProvider);
  final order = ref.watch(noteSortOrderProvider);

  return filtered.whenData((notes) {
    final list = List<NoteModel>.from(notes);
    switch (order) {
      case NoteSortOrder.updatedAtDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOrder.createdAtDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOrder.createdAtAsc:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSortOrder.titleAsc:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case NoteSortOrder.priorityDesc:
        list.sort((a, b) {
          final p = b.priority.index.compareTo(a.priority.index);
          if (p != 0) return p;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }
    return list;
  });
});
