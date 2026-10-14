import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/family_tree_models.dart';

class FamilyTreeNodeWidget extends StatelessWidget {
  final FamilyTreeNode node;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final VoidCallback onPanEnd;

  const FamilyTreeNodeWidget({
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
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final isDeceased = node.status?.toLowerCase() == 'deceased';

    final cardBg = c.surface;
    final borderColor = isSelected
        ? const Color(0xFFD97706)
        : (isDeceased ? c.outlineVariant : c.outlineVariant.withValues(alpha: 0.6));

    final generationLabel = node.generation == 0
        ? (isIndo ? 'Akar' : 'Root')
        : (node.generation < 0
            ? 'Gen ${node.generation}'
            : 'Gen +${node.generation}');

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
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFD97706).withValues(alpha: 0.25)
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
                // Top row: Avatar + Gen Pill + Status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          const Color(0xFFD97706).withValues(alpha: 0.15),
                      child: Text(
                        node.name.isNotEmpty
                            ? node.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2,),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  generationLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Tooltip(
                                message: isDeceased
                                    ? (isIndo ? 'Meninggal' : 'Deceased')
                                    : (isIndo ? 'Hidup' : 'Alive'),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDeceased
                                        ? Colors.grey
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (node.titleOrRole != null &&
                              node.titleOrRole!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              node.titleOrRole!,
                              style: AppTypography.labelSm.copyWith(
                                color: c.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Name
                Text(
                  node.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Lifespan / Years or Bio
                if (node.years != null && node.years!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Symbols.schedule, size: 12, color: c.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        node.years!,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
