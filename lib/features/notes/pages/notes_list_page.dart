import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../../services/service_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/notes_provider.dart';
import '../providers/sort_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/tag_filter_bar.dart';

/// 笔记列表页面
///
/// 应用首页，展示所有笔记的卡片列表。
/// 通过 Riverpod [filteredNotesProvider] 管理过滤后的笔记数据，
/// 支持标签过滤、搜索入口、新建笔记、滑动删除、长按操作菜单。
/// 长按笔记卡片进入多选模式，支持批量删除和导出。
class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({super.key});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _enterSelectionMode(String noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(noteId);
    });
  }

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedIds.contains(noteId)) {
        _selectedIds.remove(noteId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(noteId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<NoteModel> notes) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(notes.map((n) => n.id));
      _isSelectionMode = true;
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除选中的笔记？'),
        content: Text('将移入回收站 $count 篇笔记。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final id in _selectedIds) {
      await ref.read(notesProvider.notifier).deleteNote(id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已移入回收站 $count 篇笔记')),
      );
    }
    _exitSelectionMode();
  }

  Future<void> _exportSelected() async {
    final notesAsync = ref.read(notesProvider);
    final allNotes = notesAsync.valueOrNull ?? [];
    final selectedNotes =
        allNotes.where((n) => _selectedIds.contains(n.id)).toList();

    if (selectedNotes.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在导出...')),
    );

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAllNotes(selectedNotes);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('成功导出 ${result.success}/${result.total} 篇笔记'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '失败 ${result.failed} 篇',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              const Text('导出路径：'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.directoryPath,
                  style:
                      const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(sortedNotesProvider);
    final allNotesAsync = ref.watch(notesProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final sortOrder = ref.watch(noteSortOrderProvider);

    final hasTags = tagsAsync.maybeWhen(
      data: (tags) => tags.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '已选 ${_selectedIds.length} 篇'
            : 'Flutter Notes'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '全选',
              onPressed: () {
                final notes = notesAsync.valueOrNull ?? [];
                if (_selectedIds.length == notes.length) {
                  _exitSelectionMode();
                } else {
                  _selectAll(notes);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: '导出选中',
              onPressed: _selectedIds.isEmpty ? null : _exportSelected,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: '删除选中',
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ] else ...[
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
            PopupMenuButton<NoteSortOrder>(
              icon: const Icon(Icons.sort),
              tooltip: '排序方式',
              initialValue: sortOrder,
              onSelected: (order) =>
                  ref.read(noteSortOrderProvider.notifier).setOrder(order),
              itemBuilder: (context) => NoteSortOrder.values
                  .map(
                    (o) => PopupMenuItem<NoteSortOrder>(
                      value: o,
                      child: Row(
                        children: [
                          Icon(
                            o == sortOrder
                                ? Icons.check
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: o == sortOrder
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(o.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多',
              onPressed: () => context.push(AppRouter.settings),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (hasTags && !_isSelectionMode) const TagFilterBar(),
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
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
        final isSelected = _selectedIds.contains(note.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(note.id),
            direction: _isSelectionMode
                ? DismissDirection.none
                : DismissDirection.endToStart,
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
              isSelected: _isSelectionMode && isSelected,
              showCheckbox: _isSelectionMode,
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(note.id);
                } else {
                  _openNote(context, note);
                }
              },
              onLongPress: () {
                if (_isSelectionMode) {
                  _toggleSelection(note.id);
                } else {
                  _enterSelectionMode(note.id);
                }
              },
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
}
