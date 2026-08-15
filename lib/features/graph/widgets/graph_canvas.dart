import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/graph_data.dart';

/// 知识图谱画布
///
/// 使用 CustomPainter 绘制节点和边，支持：
/// - 平移和缩放（双指或单指拖拽空白区域）
/// - 节点拖拽（单指拖拽节点）
/// - 长按节点进入多选模式
/// - 点击节点跳转到笔记编辑器
class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.data,
    this.onNodeTap,
    this.onSelectionChanged,
  });

  final GraphData data;
  final void Function(GraphNode)? onNodeTap;
  final void Function(Set<String> selected)? onSelectionChanged;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  GraphNode? _draggedNode;
  bool _isDragging = false;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _scale = 1.0;
      _offset = Offset.zero;
      _selectedIds.clear();
      _isSelectionMode = false;
      _draggedNode = null;
    }
  }

  void _toggleSelection(GraphNode node) {
    setState(() {
      if (_selectedIds.contains(node.id)) {
        _selectedIds.remove(node.id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(node.id);
      }
    });
    widget.onSelectionChanged?.call(Set.from(_selectedIds));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onScaleStart: (details) {
          _isDragging = false;

          final localPos = _screenToCanvas(details.focalPoint);
          _draggedNode = _findNodeAt(localPos);
        },
        onScaleUpdate: (details) {
          if (_draggedNode != null && details.pointerCount == 1) {
            setState(() {
              final canvasPos = _screenToCanvas(details.focalPoint);
              _draggedNode!.x = canvasPos.dx;
              _draggedNode!.y = canvasPos.dy;
              _isDragging = true;
            });
          } else {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.3, 3.0);
              _offset += details.focalPointDelta;
            });
          }
        },
        onScaleEnd: (details) {
          if (_draggedNode != null && !_isDragging) {
            if (_isSelectionMode) {
              _toggleSelection(_draggedNode!);
            } else if (details.scaleVelocity.abs() < 0.01 &&
                details.velocity.pixelsPerSecond.distance < 50) {
              widget.onNodeTap?.call(_draggedNode!);
            }
          }
          _draggedNode = null;
          _isDragging = false;
        },
        onLongPressStart: (details) {
          final localPos = _screenToCanvas(details.globalPosition);
          final node = _findNodeAt(localPos);
          if (node != null) {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(node.id);
            });
            widget.onSelectionChanged?.call(Set.from(_selectedIds));
            HapticFeedback.mediumImpact();
          }
        },
        child: CustomPaint(
          painter: _GraphPainter(
            data: widget.data,
            scale: _scale,
            offset: _offset,
            theme: Theme.of(context),
            selectedIds: _selectedIds,
            isSelectionMode: _isSelectionMode,
            draggedNodeId: _draggedNode?.id,
          ),
          child: Container(),
        ),
      ),
    );
  }

  Offset _screenToCanvas(Offset screenPos) {
    return (screenPos - _offset) / _scale;
  }

  GraphNode? _findNodeAt(Offset position) {
    for (final node in widget.data.nodes) {
      final dx = node.x - position.dx;
      final dy = node.y - position.dy;
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
    required this.selectedIds,
    required this.isSelectionMode,
    required this.draggedNodeId,
  });

  final GraphData data;
  final double scale;
  final Offset offset;
  final ThemeData theme;
  final Set<String> selectedIds;
  final bool isSelectionMode;
  final String? draggedNodeId;

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

    final selectedEdgePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final labelStyle = TextStyle(
      fontSize: 9,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    for (final edge in data.edges) {
      final source = data.nodes.firstWhere((n) => n.id == edge.sourceId);
      final target = data.nodes.firstWhere((n) => n.id == edge.targetId);

      final isHighlighted = selectedIds.contains(source.id) ||
          selectedIds.contains(target.id);

      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        isHighlighted ? selectedEdgePaint : edgePaint,
      );

      if (!isHighlighted) {
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
    }

    // 绘制节点
    for (final node in data.nodes) {
      final color = _priorityColor(node.priority, colorScheme);
      final isSelected = selectedIds.contains(node.id);
      final isDragged = node.id == draggedNodeId;

      // 选中节点的光晕
      if (isSelected || isDragged) {
        final glowPaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(node.x, node.y),
          node.radius + 8,
          glowPaint,
        );
      }

      // 节点圆形
      final nodePaint = Paint()
        ..color = isSelected ? colorScheme.primary : color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        nodePaint,
      );

      // 节点边框
      final borderPaint = Paint()
        ..color = isSelected
            ? colorScheme.primary
            : colorScheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        borderPaint,
      );

      // 选中标记
      if (isSelected) {
        final checkPaint = Paint()
          ..color = colorScheme.onPrimary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(node.x + node.radius * 0.5, node.y - node.radius * 0.5),
          8,
          checkPaint,
        );
        final checkSpan = TextSpan(
          text: '\u2713',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        );
        final checkPainter = TextPainter(
          text: checkSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        checkPainter.paint(
          canvas,
          Offset(
            node.x + node.radius * 0.5 - checkPainter.width / 2,
            node.y - node.radius * 0.5 - checkPainter.height / 2,
          ),
        );
      }

      // 节点标题（截断）
      final titleSpan = TextSpan(
        text: _truncate(node.title, 6),
        style: TextStyle(
          fontSize: 10,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        oldDelegate.data != data ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.isSelectionMode != isSelectionMode ||
        oldDelegate.draggedNodeId != draggedNodeId;
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
