import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_search_result.dart';
import '../../notes/providers/notes_provider.dart';

/// 搜索查询文本
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 当前搜索关键词（用于编辑器定位）
///
/// 与 [searchQueryProvider] 保持同步值，专门暴露给编辑器读取，
/// 避免编辑器对 StateProvider 的 `notifier` 依赖。
final searchHighlightTokenProvider = Provider<String>((ref) {
  return ref.watch(searchQueryProvider).trim();
});

/// 搜索结果列表（带高亮片段）
///
/// 使用 SQLite FTS5 全文索引的 `highlight()` / `snippet()` 函数
/// 在数据库层生成包含 `<<` `>>` 标记的片段，UI 层再用
/// [parseHighlight] 拆分为可渲染的富文本。
final searchResultsProvider =
    FutureProvider<List<NoteSearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  // 重新监听 notesProvider 以便在笔记变更时刷新搜索结果
  ref.watch(notesProvider);
  final repository = ref.read(noteRepositoryProvider);
  return repository.searchNotesWithHighlights(query);
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
