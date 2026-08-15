import 'dart:math';

/// 知识图谱节点
class GraphNode {
  GraphNode({
    required this.id,
    required this.title,
    required this.tags,
    required this.priority,
    this.x = 0,
    this.y = 0,
    this.radius = 24,
  });

  final String id;
  final String title;
  final List<String> tags;
  final int priority;
  double x;
  double y;
  final double radius;
}

/// 知识图谱边
class GraphEdge {
  GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.label,
  });

  final String sourceId;
  final String targetId;
  final String label;
}

/// 知识图谱数据
class GraphData {
  GraphData({required this.nodes, required this.edges});

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  bool get isEmpty => nodes.isEmpty;

  /// 使用力导向布局计算节点位置
  void applyForceLayout({
    int iterations = 100,
    double repulsion = 800,
    double attraction = 0.04,
    double damping = 0.85,
  }) {
    if (nodes.length <= 1) return;

    // 初始圆形布局
    final center = nodes.length / 2;
    for (int i = 0; i < nodes.length; i++) {
      final angle = (i / nodes.length) * 2 * pi;
      final r = 150.0;
      nodes[i].x = center + r * cos(angle);
      nodes[i].y = center + r * sin(angle);
    }

    final edgePairs = <List<int>>[];
    for (final edge in edges) {
      final s = nodes.indexWhere((n) => n.id == edge.sourceId);
      final t = nodes.indexWhere((n) => n.id == edge.targetId);
      if (s != -1 && t != -1) edgePairs.add([s, t]);
    }

    for (int iter = 0; iter < iterations; iter++) {
      final forces = List.generate(nodes.length, (_) => [0.0, 0.0]);

      // 节点间斥力
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final dx = nodes[i].x - nodes[j].x;
          final dy = nodes[i].y - nodes[j].y;
          final distSq = dx * dx + dy * dy + 0.01;
          final force = repulsion / distSq;
          final dist = sqrt(distSq);
          forces[i][0] += (dx / dist) * force;
          forces[i][1] += (dy / dist) * force;
          forces[j][0] -= (dx / dist) * force;
          forces[j][1] -= (dy / dist) * force;
        }
      }

      // 边的引力
      for (final pair in edgePairs) {
        final i = pair[0];
        final j = pair[1];
        final dx = nodes[j].x - nodes[i].x;
        final dy = nodes[j].y - nodes[i].y;
        forces[i][0] += dx * attraction;
        forces[i][1] += dy * attraction;
        forces[j][0] -= dx * attraction;
        forces[j][1] -= dy * attraction;
      }

      // 应用力
      for (int i = 0; i < nodes.length; i++) {
        nodes[i].x += forces[i][0] * damping;
        nodes[i].y += forces[i][1] * damping;
      }
    }
  }

  /// 归一化节点位置到 [0, width] x [0, height] 范围
  void normalize(double width, double height, {double padding = 50}) {
    if (nodes.isEmpty) return;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = min(minX, node.x);
      maxX = max(maxX, node.x);
      minY = min(minY, node.y);
      maxY = max(maxY, node.y);
    }

    final rangeX = (maxX - minX).clamp(1.0, double.infinity);
    final rangeY = (maxY - minY).clamp(1.0, double.infinity);
    final scaleX = (width - padding * 2) / rangeX;
    final scaleY = (height - padding * 2) / rangeY;
    final scale = min(scaleX, scaleY);

    for (final node in nodes) {
      node.x = padding + (node.x - minX) * scale;
      node.y = padding + (node.y - minY) * scale;
    }
  }
}
