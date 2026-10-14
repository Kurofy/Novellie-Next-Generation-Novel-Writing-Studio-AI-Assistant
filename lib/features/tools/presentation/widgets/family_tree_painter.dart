import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/family_tree_models.dart';

class FamilyTreePainter extends CustomPainter {
  final FamilyTree tree;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final AppColors colors;
  final double nodeWidth;
  final double nodeHeight;

  FamilyTreePainter({
    required this.tree,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.colors,
    this.nodeWidth = 220.0,
    this.nodeHeight = 110.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawGenerationSwimlanes(canvas, size);
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

  void _drawGenerationSwimlanes(Canvas canvas, Size size) {
    if (tree.nodes.isEmpty) return;

    final gens = tree.nodes.map((n) => n.generation).toSet().toList()..sort();
    if (gens.isEmpty) return;

    final guidePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final badgeBgPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (final gen in gens) {
      final nodesInGen = tree.nodes.where((n) => n.generation == gen).toList();
      if (nodesInGen.isEmpty) continue;
      final avgY =
          nodesInGen.map((n) => n.y).reduce((a, b) => a + b) / nodesInGen.length;

      final bandRect = Rect.fromLTWH(0, avgY - 28, size.width, nodeHeight + 56);
      canvas.drawRect(bandRect, guidePaint);
      canvas.drawLine(Offset(0, bandRect.top), Offset(size.width, bandRect.top), borderPaint);
      canvas.drawLine(Offset(0, bandRect.bottom), Offset(size.width, bandRect.bottom), borderPaint);

      final genName = gen == 0
          ? 'GEN 0 • FOUNDERS & PROGENITORS'
          : (gen < 0
              ? 'GEN $gen • ANCESTORS'
              : 'GEN +$gen • DESCENDANTS');

      final span = TextSpan(
        text: genName,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD97706),
          letterSpacing: 0.8,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();

      // Rounded pill badge on left rail
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(28, avgY - 22, tp.width + 16, tp.height + 8),
        const Radius.circular(12),
      );
      canvas.drawRRect(badgeRect, badgeBgPaint);
      tp.paint(canvas, Offset(36, avgY - 18));
    }
  }

  void _drawEdges(Canvas canvas) {
    final nodeMap = {for (final node in tree.nodes) node.id: node};

    for (final edge in tree.edges) {
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

      if (edge.relationshipType == FamilyRelationshipType.adoptive) {
        _drawDashedLine(canvas, fromNode, toNode, linePaint);
      } else if (edge.relationshipType == FamilyRelationshipType.spouse) {
        _drawSpouseLine(canvas, fromNode, toNode, linePaint, edge, isSelected);
      } else {
        _drawHierarchicalLine(canvas, fromNode, toNode, linePaint, edge, isSelected);
      }
    }
  }

  void _drawHierarchicalLine(
    Canvas canvas,
    FamilyTreeNode from,
    FamilyTreeNode to,
    Paint paint,
    FamilyTreeEdge edge,
    bool isSelected,
  ) {
    // Top-to-bottom parent-child connection
    final start = Offset(from.x + nodeWidth / 2, from.y + nodeHeight);
    final end = Offset(to.x + nodeWidth / 2, to.y);

    final midY = (start.dy + end.dy) / 2;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);

    canvas.drawPath(path, paint);

    // Arrow pointing to child
    _drawArrow(canvas, Offset(end.dx, end.dy - 2), paint.color);

    // Label badge at midpoint
    final midPoint = Offset((start.dx + end.dx) / 2, midY);
    _drawBadge(canvas, midPoint, edge.displayLabel, paint.color, isSelected);
  }

  void _drawSpouseLine(
    Canvas canvas,
    FamilyTreeNode from,
    FamilyTreeNode to,
    Paint paint,
    FamilyTreeEdge edge,
    bool isSelected,
  ) {
    // Horizontal connection between spouses
    final isFromLeft = from.x < to.x;
    final start = isFromLeft
        ? Offset(from.x + nodeWidth, from.y + nodeHeight / 2)
        : Offset(from.x, from.y + nodeHeight / 2);
    final end = isFromLeft
        ? Offset(to.x, to.y + nodeHeight / 2)
        : Offset(to.x + nodeWidth, to.y + nodeHeight / 2);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);

    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    _drawBadge(canvas, midPoint, edge.displayLabel, paint.color, isSelected);
  }

  void _drawDashedLine(
    Canvas canvas,
    FamilyTreeNode from,
    FamilyTreeNode to,
    Paint paint,
  ) {
    final start = Offset(from.x + nodeWidth / 2, from.y + nodeHeight);
    final end = Offset(to.x + nodeWidth / 2, to.y);

    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    final double distance = (end - start).distance;
    final double dx = (end.dx - start.dx) / distance;
    final double dy = (end.dy - start.dy) / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final p1 = Offset(start.dx + dx * currentDist, start.dy + dy * currentDist);
      final nextDist = math.min(currentDist + dashWidth, distance);
      final p2 = Offset(start.dx + dx * nextDist, start.dy + dy * nextDist);
      canvas.drawLine(p1, p2, paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, Color color) {
    const arrowSize = 6.0;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - arrowSize, tip.dy - arrowSize * 1.5)
      ..lineTo(tip.dx + arrowSize, tip.dy - arrowSize * 1.5)
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

  Color _getEdgeColor(FamilyTreeEdge edge, bool isHighlighted) {
    if (isHighlighted) return const Color(0xFFD97706);

    switch (edge.relationshipType) {
      case FamilyRelationshipType.spouse:
        return const Color(0xFFE11D48); // Rose / Pink
      case FamilyRelationshipType.parent:
      case FamilyRelationshipType.child:
        return const Color(0xFF2563EB); // Royal Blue
      case FamilyRelationshipType.sibling:
        return const Color(0xFF059669); // Emerald Green
      case FamilyRelationshipType.ancestor:
        return const Color(0xFF7C3AED); // Deep Violet
      case FamilyRelationshipType.adoptive:
        return const Color(0xFF9333EA); // Purple
    }
  }

  @override
  bool shouldRepaint(covariant FamilyTreePainter oldDelegate) {
    return oldDelegate.tree != tree ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.selectedEdgeId != selectedEdgeId;
  }
}
