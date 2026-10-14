import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

class NvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NvAppBar({
    super.key,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.leading,
    this.actions,
    this.isScrolled = false,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final TextStyle? titleStyle;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool isScrolled;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final topPadding = MediaQuery.paddingOf(context).top;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBack) {
      leadingWidget = IconButton(
        icon: Icon(Symbols.arrow_back, size: 22, color: c.textPrimary),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      );
    }

    final shadow = isScrolled
        ? AppShadows.resolve(context, AppShadows.appBar)
        : const <BoxShadow>[];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: shadow,
      ),
      padding: EdgeInsets.only(top: topPadding),
      height: 64 + topPadding,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              SizedBox(
                width: 48,
                height: 48,
                child: Center(child: leadingWidget),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle ??
                        AppTypography.screenTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              ...actions!,
            ],
          ],
        ),
      ),
    );
  }
}
