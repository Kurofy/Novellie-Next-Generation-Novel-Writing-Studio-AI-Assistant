import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

enum NvEntityType {
  character,
  location,
  faction,
  item,
  worldEntry,
  chapter,
  event,
}

class NvEntityPill extends StatelessWidget {
  const NvEntityPill({
    super.key,
    required this.name,
    required this.type,
    this.onTap,
    this.onDeleted,
    this.isDeleted = false,
    this.onCard = false,
  });

  final String name;
  final NvEntityType type;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool isDeleted;
  final bool onCard;

  IconData get _icon {
    switch (type) {
      case NvEntityType.character:
        return Symbols.person;
      case NvEntityType.location:
        return Symbols.location_on;
      case NvEntityType.faction:
        return Symbols.shield;
      case NvEntityType.item:
        return Symbols.key;
      case NvEntityType.worldEntry:
        return Symbols.auto_stories;
      case NvEntityType.chapter:
        return Symbols.article;
      case NvEntityType.event:
        return Symbols.timeline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final bg = onCard ? c.surfaceSecondary : c.surface;
    final fg = isDeleted ? c.textSecondary : c.textPrimary;
    final iconColor = isDeleted ? c.textMuted : c.primary;

    final shadows = onCard || isDeleted
        ? const <BoxShadow>[]
        : AppShadows.resolve(context, AppShadows.soft);

    final textStyle = AppTypography.labelMd.copyWith(
      color: fg,
      decoration: isDeleted ? TextDecoration.lineThrough : null,
    );

    return Tooltip(
      message: isDeleted ? 'Deleted' : name,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 16, color: iconColor),
                  const SizedBox(width: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      name,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDeleted != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: onDeleted,
                      child: Icon(Symbols.close, size: 14, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
