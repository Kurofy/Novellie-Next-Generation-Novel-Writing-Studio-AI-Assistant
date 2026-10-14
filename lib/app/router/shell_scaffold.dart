import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/widgets/onboarding_toast_guide.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onboardingState = ref.watch(onboardingProvider);
    final isTourActive = onboardingState.isActive;

    final navItems = [
      NvBottomNavItem(
        label: l10n.navHome,
        icon: Symbols.cottage,
      ),
      NvBottomNavItem(
        label: l10n.navNovels,
        icon: Symbols.menu_book,
      ),
      NvBottomNavItem(
        label: l10n.navPlanning,
        icon: Symbols.schema,
      ),
      NvBottomNavItem(
        label: l10n.navTools,
        icon: Symbols.handyman,
      ),
      NvBottomNavItem(
        label: l10n.navAi,
        icon: Symbols.auto_awesome,
      ),
      NvBottomNavItem(
        label: l10n.navMore,
        icon: Symbols.more_horiz,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          if (isTourActive)
            Positioned.fill(
              child: OnboardingToastGuide(navigationShell: navigationShell),
            ),
        ],
      ),
      bottomNavigationBar: isTourActive
          ? null
          : NvBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              items: navItems,
            ),
    );
  }
}
