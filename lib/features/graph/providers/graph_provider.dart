import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/providers/notes_provider.dart';
import '../models/graph_data.dart';

/// 知识图谱数据 Provider
///
/// 从笔记列表构建图谱：
/// - 节点 = 每条笔记
/// - 边 = 共享相同标签的两条笔记之间的连接，边标签为共享的标签名
final graphDataProvider = Provider<AsyncValue<GraphData>>((ref) {
  final notesAsync = ref.watch(notesProvider);

  return notesAsync.whenData((notes) {
    if (notes.isEmpty) return GraphData(nodes: [], edges: []);

    final nodes = notes
        .map((note) => GraphNode(
              id: note.id,
              title: note.title.isEmpty ? '无标题' : note.title,
              tags: note.tags,
              priority: note.priority.index,
            ))
        .toList();

    final edges = <GraphEdge>[];
    final added = <String>{};

    for (int i = 0; i < notes.length; i++) {
      for (int j = i + 1; j < notes.length; j++) {
        final shared = notes[i].tags.toSet().intersection(notes[j].tags.toSet());
        for (final tag in shared) {
          final key = '${notes[i].id}-${notes[j].id}-$tag';
          if (added.add(key)) {
            edges.add(GraphEdge(
              sourceId: notes[i].id,
              targetId: notes[j].id,
              label: tag,
            ));
          }
        }
      }
    }

    return GraphData(nodes: nodes, edges: edges);
  });
});
