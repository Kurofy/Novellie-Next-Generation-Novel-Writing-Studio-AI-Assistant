import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class NvBottomNavItem {
  const NvBottomNavItem({
    required this.label,
    required this.icon,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final int? badgeCount;
}

class NvBottomNav extends StatelessWidget {
  const NvBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NvBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: AppShadows.resolve(context, AppShadows.navigation),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      height: 64 + bottomPadding,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavItemView(
                item: items[i],
                isSelected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NvBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isSelected ? c.primaryFill : c.textSecondary;

    return Semantics(
      selected: isSelected,
      label: item.label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: AppSpacing.xs,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: color,
                      fill: isSelected ? 1.0 : 0.0,
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        top: -2,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: c.primaryFill,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${item.badgeCount}',
                            style: AppTypography.labelSm.copyWith(
                              color: c.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTypography.labelMd.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

