import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'nv_button.dart';

enum NvEmptyKind {
  nothingYet,
  noMatches,
  notConfigured,
  inline,
}

class NvEmptyState extends StatelessWidget {
  const NvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.kind = NvEmptyKind.nothingYet,
  });

  const NvEmptyState.nothingYet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  }) : kind = NvEmptyKind.nothingYet;

  const NvEmptyState.noMatches({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  })  : secondaryLabel = null,
        onSecondary = null,
        kind = NvEmptyKind.noMatches;

  const NvEmptyState.notConfigured({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  })  : secondaryLabel = null,
        onSecondary = null,
        kind = NvEmptyKind.notConfigured;

  const NvEmptyState.inline({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  })  : icon = null,
        secondaryLabel = null,
        onSecondary = null,
        kind = NvEmptyKind.inline;

  final IconData? icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final NvEmptyKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (kind == NvEmptyKind.inline) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.inset),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              NvButton.text(
                label: actionLabel!,
                onPressed: onAction!,
                size: NvButtonSize.compact,
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                  ),
                  child: ExcludeSemantics(
                    child: Icon(icon, size: 32, color: c.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.x2),
                NvButton.primary(
                  label: actionLabel!,
                  onPressed: onAction!,
                ),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: AppSpacing.md),
                NvButton.secondary(
                  label: secondaryLabel!,
                  onPressed: onSecondary!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
