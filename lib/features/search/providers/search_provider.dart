import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/providers/notes_provider.dart';
import '../../../data/models/note_model.dart';

/// 搜索查询文本
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索结果列表
///
/// 监听 [notesProvider] 和 [searchQueryProvider]，
/// 按标题、内容、标签模糊匹配过滤。
final searchResultsProvider = Provider<List<NoteModel>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final notes = ref.watch(notesProvider);

  if (query.isEmpty) return [];

  return notes.where((note) {
    final title = note.title.toLowerCase();
    final content = note.content.toLowerCase();
    final tags = note.tags.map((t) => t.toLowerCase()).join(' ');
    return title.contains(query) ||
        content.contains(query) ||
        tags.contains(query);
  }).toList();
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
