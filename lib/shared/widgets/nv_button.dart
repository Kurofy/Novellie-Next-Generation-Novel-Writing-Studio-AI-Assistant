import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

enum NvButtonVariant {
  primary,
  secondary,
  tonal,
  text,
  destructive,
  floatingBar,
}

enum NvButtonSize {
  regular,
  compact,
}

class NvButton extends StatelessWidget {
  const NvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NvButtonVariant.primary,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  });

  const NvButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.primary;

  const NvButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.secondary;

  const NvButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.tonal;

  const NvButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.text;

  const NvButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.destructive;

  const NvButton.floatingBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = NvButtonSize.regular,
    this.icon,
    this.isLoading = false,
  }) : variant = NvButtonVariant.floatingBar;

  final String label;
  final VoidCallback? onPressed;
  final NvButtonVariant variant;
  final NvButtonSize size;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    List<BoxShadow> shadows = const [];

    switch (variant) {
      case NvButtonVariant.primary:
        bg = c.primaryFill;
        fg = c.onPrimary;
        break;
      case NvButtonVariant.secondary:
        bg = c.surfaceSecondary;
        fg = c.textPrimary;
        break;
      case NvButtonVariant.tonal:
        bg = c.primarySoft;
        fg = c.primary;
        break;
      case NvButtonVariant.text:
        bg = Colors.transparent;
        fg = c.primary;
        break;
      case NvButtonVariant.destructive:
        bg = c.errorContainer;
        fg = c.onErrorContainer;
        break;
      case NvButtonVariant.floatingBar:
        bg = c.primaryFill;
        fg = c.onPrimary;
        shadows = AppShadows.resolve(context, AppShadows.floating);
        break;
    }

    final height = size == NvButtonSize.compact ? 40.0 : 48.0;
    final radius = variant == NvButtonVariant.floatingBar
        ? AppRadius.pill
        : AppRadius.control;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.cardTitle.copyWith(
                color: fg,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.38,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: shadows,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: variant == NvButtonVariant.floatingBar
                    ? double.infinity
                    : 48,
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
