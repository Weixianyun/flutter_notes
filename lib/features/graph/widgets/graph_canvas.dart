import 'package:flutter/material.dart';

import '../models/graph_data.dart';

/// 知识图谱画布
///
/// 使用 CustomPainter 绘制节点和边，支持平移和缩放。
class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.data,
    this.onNodeTap,
  });

  final GraphData data;
  final void Function(GraphNode)? onNodeTap;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _scale = 1.0;
      _offset = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onScaleStart: (details) {
          _lastFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          setState(() {
            _scale = (_scale * details.scale).clamp(0.3, 3.0);
            _offset += details.focalPointDelta;
            _lastFocalPoint = details.focalPoint;
          });
        },
        onScaleEnd: (details) {
          if (details.scaleVelocity.abs() < 0.01 &&
              details.velocity.pixelsPerSecond.distance < 50 &&
              _lastFocalPoint != null) {
            final tapPos = _lastFocalPoint! - _offset;
            final node = _findNodeAt(tapPos);
            if (node != null) {
              widget.onNodeTap?.call(node);
            }
          }
        },
        child: CustomPaint(
          painter: _GraphPainter(
            data: widget.data,
            scale: _scale,
            offset: _offset,
            theme: Theme.of(context),
          ),
          child: Container(),
        ),
      ),
    );
  }

  GraphNode? _findNodeAt(Offset position) {
    final scaled = position / _scale - _offset / _scale;
    for (final node in widget.data.nodes) {
      final dx = node.x - scaled.dx;
      final dy = node.y - scaled.dy;
      if (dx * dx + dy * dy <= node.radius * node.radius) {
        return node;
      }
    }
    return null;
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.data,
    required this.scale,
    required this.offset,
    required this.theme,
  });

  final GraphData data;
  final double scale;
  final Offset offset;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final colorScheme = theme.colorScheme;

    // 绘制边
    final edgePaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final labelStyle = TextStyle(
      fontSize: 9,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    for (final edge in data.edges) {
      final source = data.nodes.firstWhere((n) => n.id == edge.sourceId);
      final target = data.nodes.firstWhere((n) => n.id == edge.targetId);

      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        edgePaint,
      );

      // 边标签
      final midX = (source.x + target.x) / 2;
      final midY = (source.y + target.y) / 2;
      final labelSpan = TextSpan(text: edge.label, style: labelStyle);
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(midX - labelPainter.width / 2, midY - 8),
      );
    }

    // 绘制节点
    for (final node in data.nodes) {
      final color = _priorityColor(node.priority, colorScheme);

      // 节点圆形
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        nodePaint,
      );

      // 节点边框
      final borderPaint = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        borderPaint,
      );

      // 节点标题（截断）
      final titleSpan = TextSpan(
        text: _truncate(node.title, 6),
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      );
      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: node.radius * 3);
      titlePainter.paint(
        canvas,
        Offset(
          node.x - titlePainter.width / 2,
          node.y + node.radius + 4,
        ),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.data != data;
  }

  Color _priorityColor(int priority, ColorScheme colorScheme) {
    return switch (priority) {
      0 => colorScheme.tertiary,
      1 => colorScheme.primary,
      2 => colorScheme.error,
      _ => colorScheme.primary,
    };
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }
}
