import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/service_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../notes/providers/notes_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/sort_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/tag_filter_bar.dart';

/// 笔记列表页面
///
/// 应用首页，展示所有笔记的卡片列表。
/// 通过 Riverpod [sortedNotesProvider] 管理排序+过滤后的笔记数据，
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
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSelectedDialogTitle),
        content: Text(l10n.deleteSelectedDialogContent(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tagActionDelete),
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
        SnackBar(content: Text(l10n.movedToTrashCount(count))),
      );
    }
    _exitSelectionMode();
  }

  Future<void> _exportSelected() async {
    final l10n = AppLocalizations.of(context);
    final notesAsync = ref.read(notesProvider);
    final allNotes = notesAsync.valueOrNull ?? [];
    final selectedNotes =
        allNotes.where((n) => _selectedIds.contains(n.id)).toList();

    if (selectedNotes.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportingInProgress)),
    );

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAllNotes(selectedNotes);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exportComplete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exportSuccessCount(result.success, result.total)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.exportFailedCount(result.failed),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.exportPath),
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
            TextButton(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: result.directoryPath));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.exportPathCopied)),
                );
              },
              child: Text(l10n.copyPathAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.doneAction),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
    _exitSelectionMode();
  }

  String _labelForSort(BuildContext context, NoteSortOrder order) {
    final l10n = AppLocalizations.of(context);
    return switch (order) {
      NoteSortOrder.updatedAtDesc => l10n.sortUpdatedAtDesc,
      NoteSortOrder.createdAtDesc => l10n.sortCreatedAtDesc,
      NoteSortOrder.createdAtAsc => l10n.sortCreatedAtAsc,
      NoteSortOrder.titleAsc => l10n.sortTitleAsc,
      NoteSortOrder.priorityDesc => l10n.sortPriorityDesc,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            ? l10n.selectedNotesCount(_selectedIds.length)
            : l10n.appTitle),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.exitSelectionTooltip,
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAllTooltip,
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
              tooltip: l10n.exportSelectedTooltip,
              onPressed: _selectedIds.isEmpty ? null : _exportSelected,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: l10n.deleteSelectedTooltip,
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.account_tree_outlined),
              tooltip: l10n.knowledgeGraphTooltip,
              onPressed: () => context.push(AppRouter.graph),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.recycleBin,
              onPressed: () => context.push(AppRouter.trash),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchNotesTooltip,
              onPressed: () => context.push(AppRouter.search),
            ),
            PopupMenuButton<NoteSortOrder>(
              icon: const Icon(Icons.sort),
              tooltip: l10n.sortMenuTooltip,
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
                          Text(_labelForSort(context, o)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.moreTooltip,
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
              label: Text(l10n.emptyNotesAction),
            ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    WidgetRef ref,
    List<NoteModel> notes,
  ) {
    final density = ref.watch(notesDensityProvider);
    final isCompact = density == NotesDensity.compact;
    final cardPadding = isCompact ? 4.0 : 8.0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: notes.length,
      // ignore: deprecated_member_use
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedIds.contains(note.id);
        return Padding(
          padding: EdgeInsets.only(bottom: cardPadding),
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
              compact: isCompact,
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
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.note_add_outlined,
      title: l10n.emptyNotesTitle,
      subtitle: l10n.emptyNotesSubtitle,
      actionLabel: l10n.emptyNotesAction,
      onAction: () => _createNote(context),
    );
  }

  Widget _buildNoFilteredNotes(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: l10n.noFilteredNotesTitle,
      subtitle: l10n.noFilteredNotesSubtitle,
      actionLabel: l10n.noFilteredNotesAction,
      onAction: () => ref.read(selectedTagsProvider.notifier).clear(),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.error_outline,
      title: l10n.loadErrorTitle,
      subtitle: '${l10n.loadErrorTitle}: $error',
      actionLabel: l10n.loadErrorAction,
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
    final l10n = AppLocalizations.of(context);
    ref.read(notesProvider.notifier).deleteNote(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.movedNoteToTrash(note.title)),
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () {
            ref.read(notesProvider.notifier).restoreNote(note.id);
          },
        ),
      ),
    );
  }
}
