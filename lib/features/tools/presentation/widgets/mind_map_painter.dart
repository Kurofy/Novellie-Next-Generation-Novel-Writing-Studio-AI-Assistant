import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/mind_map_models.dart';

class MindMapPainter extends CustomPainter {
  final MindMapGraph graph;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final AppColors colors;
  final double nodeWidth;
  final double nodeHeight;

  MindMapPainter({
    required this.graph,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.colors,
    this.nodeWidth = 230.0,
    this.nodeHeight = 110.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawEdges(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.75, dotPaint);
      }
    }
  }

  void _drawEdges(Canvas canvas) {
    final nodeMap = {for (final node in graph.nodes) node.id: node};

    for (final edge in graph.edges) {
      final fromNode = nodeMap[edge.fromNodeId];
      final toNode = nodeMap[edge.toNodeId];
      if (fromNode == null || toNode == null) continue;

      final isSelected = edge.id == selectedEdgeId;
      final isConnectedToSelectedNode =
          fromNode.id == selectedNodeId || toNode.id == selectedNodeId;

      final edgeColor = _getEdgeColor(edge, isSelected || isConnectedToSelectedNode);
      final strokeWidth = isSelected
          ? 3.0
          : (isConnectedToSelectedNode ? 2.5 : 1.8);

      final linePaint = Paint()
        ..color = edgeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      final start = Offset(
        fromNode.x + nodeWidth / 2,
        fromNode.y + nodeHeight / 2,
      );
      final end = Offset(
        toNode.x + nodeWidth / 2,
        toNode.y + nodeHeight / 2,
      );

      // Smooth curved path between narrative nodes
      final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final normal = Offset(-dy * 0.15, dx * 0.15);
      final controlPoint = midPoint + normal;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

      canvas.drawPath(path, linePaint);

      // Arrow pointing towards target node (sequence destination)
      _drawArrowOnCurve(canvas, controlPoint, end, edgeColor);

      // Label badge
      _drawBadge(canvas, controlPoint, edge.displayLabel, edgeColor, isSelected);
    }
  }

  void _drawArrowOnCurve(
    Canvas canvas,
    Offset control,
    Offset end,
    Color color,
  ) {
    const arrowLength = 9.0;
    const arrowWidth = 5.0;

    // Tangent direction near end
    final tangent = (end - control);
    final distance = tangent.distance;
    if (distance == 0) return;

    final dir = tangent / distance;
    final normal = Offset(-dir.dy, dir.dx);

    // Tip slightly offset from exact center of destination card
    final tip = end - dir * (nodeWidth * 0.35);

    final p1 = tip - dir * arrowLength + normal * arrowWidth;
    final p2 = tip - dir * arrowLength - normal * arrowWidth;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawBadge(
    Canvas canvas,
    Offset position,
    String text,
    Color color,
    bool isSelected,
  ) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : color,
      ),
    );

    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: tp.width + 12,
        height: tp.height + 6,
      ),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = isSelected ? color : colors.surface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 1.0 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(badgeRect, bgPaint);
    canvas.drawRRect(badgeRect, borderPaint);

    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  Color _getEdgeColor(MindMapEdge edge, bool isHighlighted) {
    if (isHighlighted) return colors.primary;

    switch (edge.type) {
      case MindMapConnectionType.leadsTo:
        return const Color(0xFF06B6D4); // Cyan
      case MindMapConnectionType.causes:
        return const Color(0xFFEF4444); // Red
      case MindMapConnectionType.parallelArc:
        return const Color(0xFF6366F1); // Indigo
      case MindMapConnectionType.conflictsWith:
        return const Color(0xFFF43F5E); // Rose
      case MindMapConnectionType.subPlot:
        return const Color(0xFF8B5CF6); // Violet
      case MindMapConnectionType.supports:
        return const Color(0xFF10B981); // Emerald
      case MindMapConnectionType.custom:
        return colors.outlineVariant;
    }
  }

  @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.selectedEdgeId != selectedEdgeId;
  }
}
