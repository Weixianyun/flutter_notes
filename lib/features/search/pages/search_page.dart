import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/note_search_result.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../notes/widgets/note_card.dart';
import '../providers/search_provider.dart';
import '../utils/highlight_parser.dart';

/// 搜索页面
///
/// 提供全文搜索功能，支持按标题、内容、标签模糊匹配。
/// 包含搜索历史记录、关键词高亮预览与点击结果跳转定位。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _onSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(trimmed);
    }
  }

  void _searchFromHistory(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    ref.read(searchQueryProvider.notifier).state = query;
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '清除',
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: query.isEmpty
          ? _buildHistoryView(history)
          : resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: '搜索失败',
                subtitle: '出错：$error',
              ),
              data: (results) => results.isEmpty
                  ? _buildNoResults()
                  : _buildResults(results, query),
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      onSubmitted: _onSubmit,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: '搜索笔记标题、内容、标签...',
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // ── 搜索结果列表 ──

  Widget _buildResults(List<NoteSearchResult> results, String query) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.contentSnippet != null &&
                  result.contentSnippet!.isNotEmpty)
                _HighlightSnippetCard(snippet: result.contentSnippet!),
              NoteCard(
                note: result.note,
                onTap: () {
                  _onSubmit(query);
                  context.push(
                    AppRouter.editor,
                    extra: EditorArgs(
                      noteId: result.note.id,
                      highlight: query,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 搜索历史 ──

  Widget _buildHistoryView(List<String> history) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: '搜索笔记',
        subtitle: '输入关键词搜索标题、内容或标签',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '搜索历史',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton.icon(
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).clear(),
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history.map((q) {
            return InputChip(
              label: Text(q),
              onPressed: () => _searchFromHistory(q),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () =>
                  ref.read(searchHistoryProvider.notifier).remove(q),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 无搜索结果 ──

  Widget _buildNoResults() {
    final query = ref.watch(searchQueryProvider);
    return EmptyState(
      icon: Icons.search_off,
      title: '未找到相关笔记',
      subtitle: '没有与「$query」匹配的笔记',
    );
  }
}

// ── 内容片段高亮预览 ──

class _HighlightSnippetCard extends StatelessWidget {
  const _HighlightSnippetCard({required this.snippet});

  final String snippet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segments = parseHighlight(snippet);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: segments.map((s) {
            return TextSpan(
              text: s.text,
              style: s.isHighlight
                  ? textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                    )
                  : textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
