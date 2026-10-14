import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class NvCard extends StatelessWidget {
  const NvCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.isCompact = false,
  })  : isInset = false,
        insetSecondary = false;

  const NvCard.compact({
    super.key,
    required this.child,
    this.onTap,
  })  : padding = const EdgeInsets.all(AppSpacing.lg),
        isCompact = true,
        isInset = false,
        insetSecondary = false;

  const NvCard.inset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.insetSecondary = false,
  })  : isCompact = false,
        isInset = true;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool isInset;
  final bool insetSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final radius = isInset ? AppRadius.inset : AppRadius.card;
    final bg = isInset
        ? (insetSecondary ? c.surfaceSecondary : c.surfaceSoft)
        : c.surface;
    final shadows = isInset
        ? const <BoxShadow>[]
        : AppShadows.resolve(context, AppShadows.card);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                splashColor: c.surfaceHigh.withAlpha(50),
                highlightColor: c.surfaceSoft,
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              )
            : Padding(
                padding: padding,
                child: child,
              ),
      ),
    );
  }
}
