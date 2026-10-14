import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

enum NvChipVariant {
  filter,
  status,
  input,
}

enum NvStatusTagKind {
  neutral,
  success,
  warning,
}

class NvChip extends StatelessWidget {
  const NvChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.count,
    this.onTap,
    this.onDeleted,
    this.variant = NvChipVariant.filter,
    this.statusKind = NvStatusTagKind.neutral,
    this.icon,
  });

  const NvChip.filter({
    super.key,
    required this.label,
    required this.isSelected,
    this.count,
    this.onTap,
    this.icon,
  })  : variant = NvChipVariant.filter,
        statusKind = NvStatusTagKind.neutral,
        onDeleted = null;

  const NvChip.status({
    super.key,
    required this.label,
    this.statusKind = NvStatusTagKind.neutral,
    this.icon,
  })  : variant = NvChipVariant.status,
        isSelected = false,
        count = null,
        onTap = null,
        onDeleted = null;

  const NvChip.input({
    super.key,
    required this.label,
    required this.onDeleted,
    this.icon,
  })  : variant = NvChipVariant.input,
        isSelected = false,
        count = null,
        onTap = null,
        statusKind = NvStatusTagKind.neutral;

  final String label;
  final bool isSelected;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final NvChipVariant variant;
  final NvStatusTagKind statusKind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Color bg;
    Color fg;
    List<BoxShadow> shadows = const [];

    switch (variant) {
      case NvChipVariant.filter:
        if (isSelected) {
          bg = c.primaryFill;
          fg = c.onPrimary;
        } else {
          bg = c.surface;
          fg = c.textSecondary;
          shadows = AppShadows.resolve(context, AppShadows.soft);
        }
        break;
      case NvChipVariant.status:
        switch (statusKind) {
          case NvStatusTagKind.neutral:
            bg = c.primarySoft;
            fg = c.primaryPressed;
            break;
          case NvStatusTagKind.success:
            bg = c.successContainer;
            fg = c.success;
            break;
          case NvStatusTagKind.warning:
            bg = c.warningContainer;
            fg = c.warning;
            break;
        }
        break;
      case NvChipVariant.input:
        bg = c.surfaceSecondary;
        fg = c.textPrimary;
        break;
    }

    final displayText =
        (count != null && count! > 0) ? '$label ($count)' : label;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          displayText,
          style: AppTypography.labelMd.copyWith(color: fg),
        ),
        if (onDeleted != null) ...[
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(Symbols.close, size: 16, color: fg),
          ),
        ],
      ],
    );

    return Container(
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
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.xs + 2,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
