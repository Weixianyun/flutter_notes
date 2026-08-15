import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/graph_provider.dart';
import '../widgets/graph_canvas.dart';

/// 知识图谱页面
///
/// 以可视化方式展示笔记之间的关联关系（通过共享标签连接）。
/// 支持平移、缩放、点击节点跳转到笔记编辑器。
class GraphPage extends ConsumerWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(graphDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识图谱'),
        actions: [
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
              onAction: () =>
                  Navigator.pushNamed(context, AppRouter.editor),
            );
          }

          final size = MediaQuery.of(context).size;
          graph.applyForceLayout();
          graph.normalize(
            size.width,
            size.height - kToolbarHeight,
            padding: 60,
          );

          return Stack(
            children: [
              GraphCanvas(
                data: graph,
                onNodeTap: (node) => Navigator.pushNamed(
                  context,
                  AppRouter.editor,
                  arguments: node.id,
                ),
              ),
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
            _LegendItem(
              color: colorScheme.tertiary,
              label: '低优先级',
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: colorScheme.primary,
              label: '中优先级',
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: colorScheme.error,
              label: '高优先级',
            ),
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
