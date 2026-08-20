import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/notes_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/tag_filter_bar.dart';

/// 笔记列表页面
///
/// 应用首页，展示所有笔记的卡片列表。
/// 通过 Riverpod [filteredNotesProvider] 管理过滤后的笔记数据，
/// 支持标签过滤、搜索入口、新建笔记、滑动删除、长按操作菜单。
class NotesListPage extends ConsumerWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final allNotesAsync = ref.watch(notesProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    final hasTags = tagsAsync.maybeWhen(
      data: (tags) => tags.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: '知识图谱',
            onPressed: () => context.push(AppRouter.graph),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '回收站',
            onPressed: () => context.push(AppRouter.trash),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索笔记',
            onPressed: () => context.push(AppRouter.search),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onPressed: () => context.push(AppRouter.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签过滤栏（有标签时显示）
          if (hasTags) const TagFilterBar(),
          // 笔记列表
          Expanded(
            child: allNotesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(context, ref, error),
              data: (allNotes) {
                if (allNotes.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return notesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      _buildErrorState(context, ref, error),
                  data: (notes) => notes.isEmpty
                      ? _buildNoFilteredNotes(context, ref)
                      : _buildNotesList(context, ref, notes),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNote(context),
        icon: const Icon(Icons.add),
        label: const Text('新建笔记'),
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    WidgetRef ref,
    List<NoteModel> notes,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: notes.length,
      // ignore: deprecated_member_use
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(note.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            onDismissed: (_) => _deleteNote(context, ref, note),
            child: NoteCard(
              note: note,
              onTap: () => _openNote(context, note),
              onLongPress: () => _showNoteOptions(context, ref, note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.note_add_outlined,
      title: '还没有任何笔记',
      subtitle: '点击右下角按钮创建你的第一条笔记',
      actionLabel: '新建笔记',
      onAction: () => _createNote(context),
    );
  }

  Widget _buildNoFilteredNotes(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: '没有匹配的笔记',
      subtitle: '当前标签筛选下没有笔记，试试其他标签',
      actionLabel: '清除筛选',
      onAction: () => ref.read(selectedTagsProvider.notifier).clear(),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return EmptyState(
      icon: Icons.error_outline,
      title: '加载失败',
      subtitle: '数据加载出错：$error',
      actionLabel: '重试',
      onAction: () => ref.invalidate(notesProvider),
    );
  }

  void _createNote(BuildContext context) {
    context.push(AppRouter.editor);
  }

  void _openNote(BuildContext context, NoteModel note) {
    context.push(AppRouter.editor, extra: note.id);
  }

  void _deleteNote(
    BuildContext context,
    WidgetRef ref,
    NoteModel note,
  ) {
    ref.read(notesProvider.notifier).deleteNote(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移入回收站「${note.title}」'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            ref.read(notesProvider.notifier).restoreNote(note.id);
          },
        ),
      ),
    );
  }

  void _showNoteOptions(
    BuildContext context,
    WidgetRef ref,
    NoteModel note,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制内容'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('归档'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(context, ref, note);
              },
            ),
          ],
        ),
      ),
    );
  }
}
