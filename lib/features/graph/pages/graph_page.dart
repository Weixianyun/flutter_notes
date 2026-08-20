import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../notes/providers/notes_provider.dart';
import '../models/graph_data.dart';
import '../providers/graph_provider.dart';
import '../widgets/graph_canvas.dart';

/// 知识图谱页面
///
/// 以可视化方式展示笔记之间的关联关系（通过共享标签连接）。
/// 支持：
/// - 平移、缩放、节点拖拽
/// - 长按节点进入多选模式
/// - 多选后可批量删除或跳转
/// - 搜索节点（按标题或标签高亮匹配）
class GraphPage extends ConsumerStatefulWidget {
  const GraphPage({super.key});

  @override
  ConsumerState<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends ConsumerState<GraphPage> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';

  void _onSelectionChanged(Set<String> selected) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(selected);
      _isSelectionMode = selected.isNotEmpty;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
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

    _exitSelectionMode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已移入回收站 $count 篇笔记')),
      );
    }
  }

  void _openSelected() {
    if (_selectedIds.length == 1) {
      final id = _selectedIds.first;
      _exitSelectionMode();
      context.push(AppRouter.editor, extra: id);
    }
  }

  Set<String> _getHighlightedIds(GraphData graph) {
    if (_searchQuery.isEmpty) return {};
    final query = _searchQuery.toLowerCase();
    final ids = <String>{};
    for (final node in graph.nodes) {
      if (node.title.toLowerCase().contains(query) ||
          node.tags.any((t) => t.toLowerCase().contains(query))) {
        ids.add(node.id);
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(graphDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '已选 ${_selectedIds.length} 篇'
            : '知识图谱'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedIds.length == 1)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: '打开笔记',
                onPressed: _openSelected,
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: '删除选中',
              onPressed: _deleteSelected,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: '图例',
              onPressed: () => _showLegend(context, colorScheme, theme),
            ),
        ],
      ),
      body: graphAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: '加载失败',
          subtitle: error.toString(),
        ),
        data: (graph) {
          if (graph.isEmpty) {
            return EmptyState(
              icon: Icons.account_tree_outlined,
              title: '暂无笔记',
              subtitle: '创建笔记并添加标签后，\n图谱将展示笔记间的关联关系',
              actionLabel: '新建笔记',
              onAction: () => context.push(AppRouter.editor),
            );
          }

          final size = MediaQuery.of(context).size;
          graph.applyForceLayout();
          graph.normalize(
            size.width,
            size.height - kToolbarHeight,
            padding: 60,
          );

          final highlightedIds = _getHighlightedIds(graph);
          final hasSearch = _searchQuery.isNotEmpty;

          return Stack(
            children: [
              GraphCanvas(
                data: graph,
                highlightedIds: highlightedIds,
                hasSearch: hasSearch,
                onNodeTap: (node) {
                  if (!_isSelectionMode) {
                    context.push(
                      AppRouter.editor,
                      extra: node.id,
                    );
                  }
                },
                onSelectionChanged: _onSelectionChanged,
              ),
              // 搜索栏
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: _SearchBar(
                  query: _searchQuery,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              // 搜索结果计数
              if (hasSearch)
                Positioned(
                  top: 56,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      highlightedIds.isEmpty
                          ? '无匹配节点'
                          : '匹配 ${highlightedIds.length} 个节点',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              // 统计信息
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${graph.nodes.length} 篇笔记',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.link, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${graph.edges.length} 个关联',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 多选模式提示
              if (_isSelectionMode)
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '长按选择，点击节点添加/移除选中',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showLegend(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图例'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(color: colorScheme.tertiary, label: '低优先级'),
            const SizedBox(height: 8),
            _LegendItem(color: colorScheme.primary, label: '中优先级'),
            const SizedBox(height: 8),
            _LegendItem(color: colorScheme.error, label: '高优先级'),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.link, size: 16, color: colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '共享标签的笔记相互连接',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '长按节点进入多选模式',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.drag_indicator, size: 16, color: colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '拖拽节点调整位置',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.search, size: 16, color: colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '搜索栏按标题或标签筛选节点',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索节点标题或标签...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
