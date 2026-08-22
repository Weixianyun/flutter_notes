import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/notes_provider.dart';

/// 回收站页面
///
/// 展示已软删除的笔记，支持恢复和永久删除。
/// 通过 [NotesNotifier.getDeletedNotes] 异步加载回收站数据。
class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  List<NoteModel>? _deletedNotes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notes = await ref.read(notesProvider.notifier).getDeletedNotes();
      if (!mounted) return;
      setState(() {
        _deletedNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          if (_deletedNotes != null && _deletedNotes!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '清空回收站',
              onPressed: () => _showEmptyTrashConfirm(context),
            ),
        ],
      ),
      body: _buildBody(context, colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '加载失败',
        subtitle: '数据加载出错：$_error',
        actionLabel: '重试',
        onAction: _loadDeletedNotes,
      );
    }

    final notes = _deletedNotes ?? [];

    if (notes.isEmpty) {
      return const EmptyState(
        icon: Icons.delete_outline,
        title: '回收站为空',
        subtitle: '删除的笔记会暂存在这里，30 天内可恢复',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${notes.length} 篇已删除笔记',
                style: TextStyle(
                  fontSize: AppFontSizes.bodyMedium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDeletedNotes,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _TrashNoteCard(
                  note: note,
                  onRestore: () => _restoreNote(note),
                  onPermanentlyDelete: () => _showPermanentDeleteConfirm(note),
                  onTap: () => context.push(
                    AppRouter.editor,
                    extra: note.id,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _restoreNote(NoteModel note) async {
    await ref.read(notesProvider.notifier).restoreNote(note.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已恢复「${note.title}」')),
    );
    _loadDeletedNotes();
  }

  void _showPermanentDeleteConfirm(NoteModel note) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('永久删除？'),
        content: Text('「${note.title}」将被永久删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(notesProvider.notifier).permanentlyDeleteNote(note.id);
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('已永久删除「${note.title}」')),
              );
              _loadDeletedNotes();
            },
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
  }

  void _showEmptyTrashConfirm(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空回收站？'),
        content: const Text('回收站中的所有笔记将被永久删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(notesProvider.notifier).emptyTrash();
              if (!context.mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('已清空回收站')),
              );
              _loadDeletedNotes();
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _TrashNoteCard extends StatelessWidget {
  const _TrashNoteCard({
    required this.note,
    required this.onRestore,
    required this.onPermanentlyDelete,
    required this.onTap,
  });

  final NoteModel note;
  final VoidCallback onRestore;
  final VoidCallback onPermanentlyDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deletedTime = note.deletedAt;
    final timeStr = deletedTime != null
        ? '${deletedTime.month}/${deletedTime.day} ${deletedTime.hour.toString().padLeft(2, '0')}:${deletedTime.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? '(无标题)' : note.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(
                      '删除于 $timeStr',
                      style: TextStyle(
                        fontSize: AppFontSizes.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                note.excerpt,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: AppFontSizes.bodyMedium,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('恢复'),
                  ),
                  TextButton.icon(
                    onPressed: onPermanentlyDelete,
                    icon: Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      '永久删除',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
