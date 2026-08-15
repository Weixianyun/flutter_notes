import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/providers/notes_provider.dart';
import '../../../data/models/note_model.dart';

/// 搜索查询文本
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索结果列表
///
/// 使用 SQLite FTS5 全文索引进行数据库级搜索，
/// 支持标题、内容、标签的全文匹配。
final searchResultsProvider = FutureProvider<List<NoteModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return [];
  // 重新监听 notesProvider 以便在笔记变更时刷新搜索结果
  ref.watch(notesProvider);
  return ref.read(notesProvider.notifier).searchNotes(query);
});

/// 搜索历史状态管理
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const int _maxHistory = 10;

  @override
  List<String> build() => [];

  /// 添加搜索记录（去重、限制数量）
  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((q) => q != trimmed),
    ].take(_maxHistory).toList();
  }

  /// 清空搜索历史
  void clear() => state = [];

  /// 删除单条历史
  void remove(String query) {
    state = state.where((q) => q != query).toList();
  }
}

/// 搜索历史 Provider
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
