import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/note_model.dart';
import '../../../services/sync_service.dart';
import '../providers/sync_provider.dart';

/// 冲突解决页面
///
/// 列出当前同步检测到的所有冲突，逐条提供三个选择：
/// - 保留本地版本（localWins）
/// - 保留远端版本（remoteWins）
/// - 跳过（skip）
///
/// 全部选择后可点击底部 "应用解决方案" 一次性应用所有选择。
class ConflictResolutionPage extends ConsumerStatefulWidget {
  const ConflictResolutionPage({super.key});

  @override
  ConsumerState<ConflictResolutionPage> createState() =>
      _ConflictResolutionPageState();
}

class _ConflictResolutionPageState
    extends ConsumerState<ConflictResolutionPage> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);

    if (syncState.conflicts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('冲突解决')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text('当前没有需要解决的冲突'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('冲突解决 (${syncState.conflicts.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(syncProvider.notifier).clearConflicts();
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已检测到 ${syncState.conflicts.length} 条笔记在本地和远端都被修改',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '剩余未选择: ${syncState.unresolvedCount} 条',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: syncState.conflicts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final conflict = syncState.conflicts[index];
                final resolution = syncState.pendingResolutions[conflict.noteId];
                return _ConflictCard(
                  key: ValueKey(conflict.noteId),
                  conflict: conflict,
                  selectedResolution: resolution,
                  onSelect: (next) {
                    ref
                        .read(syncProvider.notifier)
                        .setResolution(conflict.noteId, next);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: syncState.allResolved || _applying
                          ? null
                          : () {
                              for (final c in syncState.conflicts) {
                                ref
                                    .read(syncProvider.notifier)
                                    .setResolution(
                                      c.noteId,
                                      ConflictResolution.skip,
                                    );
                              }
                            },
                      child: const Text('全部跳过'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: _applying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _applying
                            ? '应用中...'
                            : '应用解决方案 (${syncState.pendingResolutions.length})',
                      ),
                      onPressed: syncState.pendingResolutions.isEmpty || _applying
                          ? null
                          : _apply,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final result = await ref
          .read(syncProvider.notifier)
          .applyResolutions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已应用: 本地 ${result.localWins}, 远端 ${result.remoteWins}, 跳过 ${result.skipped}'
            '${result.errors.isEmpty ? "" : "; 错误: ${result.errors.length} 条"}',
          ),
        ),
      );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    super.key,
    required this.conflict,
    required this.selectedResolution,
    required this.onSelect,
  });

  final SyncConflictItem conflict;
  final ConflictResolution? selectedResolution;
  final ValueChanged<ConflictResolution> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ConflictSideTile(
              label: '本地版本',
              note: conflict.local,
              isLocal: true,
              isNewer: conflict.localIsNewer,
              isSelected:
                  selectedResolution == ConflictResolution.localWins,
              onTap: () => onSelect(ConflictResolution.localWins),
            ),
            const SizedBox(height: 8),
            _ConflictSideTile(
              label: '远端版本',
              note: conflict.remote,
              isLocal: false,
              isNewer: !conflict.localIsNewer,
              isSelected:
                  selectedResolution == ConflictResolution.remoteWins,
              onTap: () => onSelect(ConflictResolution.remoteWins),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SkipChoice(
                    isSelected:
                        selectedResolution == null,
                    onTap: () => onSelect(ConflictResolution.skip),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictSideTile extends StatelessWidget {
  const _ConflictSideTile({
    required this.label,
    required this.note,
    required this.isLocal,
    required this.isNewer,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final NoteModel note;
  final bool isLocal;
  final bool isNewer;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leadingColor =
        isLocal ? colorScheme.primary : colorScheme.secondary;
    final bg = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final fg = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? leadingColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLocal ? Icons.phone_android : Icons.cloud_outlined,
              color: leadingColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isNewer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '更新',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.content.isEmpty ? '(空内容)' : note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? leadingColor : colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.year}-${_p(t.month)}-${_p(t.day)} '
        '${_p(t.hour)}:${_p(t.minute)}';
  }

  String _p(int v) => v.toString().padLeft(2, '0');
}

class _SkipChoice extends StatelessWidget {
  const _SkipChoice({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.outline : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 8),
            const Text('跳过（暂不处理）'),
          ],
        ),
      ),
    );
  }
}
