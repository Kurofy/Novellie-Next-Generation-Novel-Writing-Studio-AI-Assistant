import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/mind_map_models.dart';

class MindMapNodeWidget extends StatelessWidget {
  final MindMapNode node;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final VoidCallback onPanEnd;

  const MindMapNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    this.isDimmed = false,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final typeColor = _getNodeColor(node.type);

    return Positioned(
      left: node.x,
      top: node.y,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => onPanEnd(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isDimmed ? 0.35 : 1.0,
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isSelected
                    ? typeColor
                    : c.outlineVariant.withValues(alpha: 0.6),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? typeColor.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Type badge & Sequence number pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3,),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getNodeIcon(node.type),
                              size: 13, color: typeColor,),
                          const SizedBox(width: 4),
                          Text(
                            node.type.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (node.sequenceOrder != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,),
                        decoration: BoxDecoration(
                          color: c.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: c.outlineVariant.withValues(alpha: 0.5),),
                        ),
                        child: Text(
                          '#${node.sequenceOrder}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  node.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Story Arc name or description
                if (node.storyArcName != null &&
                    node.storyArcName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Symbols.timeline, size: 12, color: typeColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          node.storyArcName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (node.description != null &&
                    node.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    node.description!,
                    style: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(MindMapNodeType type) {
    switch (type) {
      case MindMapNodeType.brainstorm:
        return const Color(0xFFF59E0B); // Amber / Orange
      case MindMapNodeType.storyArc:
        return const Color(0xFF6366F1); // Indigo
      case MindMapNodeType.chapterOrder:
        return const Color(0xFF06B6D4); // Cyan
      case MindMapNodeType.plotPoint:
        return const Color(0xFFEF4444); // Red / Coral
      case MindMapNodeType.theme:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  IconData _getNodeIcon(MindMapNodeType type) {
    switch (type) {
      case MindMapNodeType.brainstorm:
        return Symbols.lightbulb;
      case MindMapNodeType.storyArc:
        return Symbols.alt_route;
      case MindMapNodeType.chapterOrder:
        return Symbols.menu_book;
      case MindMapNodeType.plotPoint:
        return Symbols.flag;
      case MindMapNodeType.theme:
        return Symbols.psychology;
    }
  }
}
