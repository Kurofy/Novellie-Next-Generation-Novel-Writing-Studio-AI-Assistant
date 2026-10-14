import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/constants/external_links.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../export/presentation/screens/export_novel_dialog.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../widgets/support_us_sheet.dart';
import 'diagnostics_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final activeNovelAsync = ref.watch(activeNovelProvider);

    return Scaffold(
      appBar: NvAppBar(
        title: l10n.navMore,
        actions: [
          IconButton(
            icon: SvgPicture.string(
              AppBrandSvgs.github,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(c.textPrimary, BlendMode.srcIn),
            ),
            tooltip: l10n.githubRepository,
            onPressed: () => AppExternalLinks.openUrl(
              context,
              AppExternalLinks.github,
            ),
          ),
          IconButton(
            icon: const Icon(
              Symbols.favorite,
              size: 22,
              color: Color(0xFFFF5E5B),
            ),
            tooltip: l10n.supportUs,
            onPressed: () => SupportUsSheet.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.xl,
        ),
        children: [
          Text(
            l10n.writing,
            style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _MoreMenuItem(
                  icon: Symbols.flag,
                  title: l10n.statisticsAndGoals,
                  description: l10n.statisticsAndGoalsDesc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MoreMenuItem(
                  icon: Symbols.sticky_note_2,
                  title: l10n.notes,
                  description: l10n.notesDesc,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.localeName == 'id'
                              ? 'Catatan dan riset dapat dilampirkan langsung pada karakter dan entri dunia.'
                              : 'Notes and research are attached directly to characters and world entries.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.dataSection,
            style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _MoreMenuItem(
                  icon: Symbols.download,
                  title: l10n.export,
                  description: l10n.exportDesc,
                  onTap: () {
                    final novel = activeNovelAsync.valueOrNull;
                    if (novel != null) {
                      ExportNovelDialog.show(context, novel);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.localeName == 'id'
                                ? 'Silakan buat atau pilih novel aktif terlebih dahulu.'
                                : 'Please create or select an active novel first.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MoreMenuItem(
                  icon: Symbols.backup,
                  title: l10n.backupAndRestore,
                  description: l10n.backupAndRestoreDesc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiagnosticsScreen(initialIndex: 0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.appSection,
            style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _MoreMenuItem(
                  icon: Symbols.tune,
                  title: l10n.settingsTitle,
                  description: l10n.settingsDesc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MoreMenuItem(
                  icon: Symbols.info,
                  title: l10n.aboutAndDiagnostics,
                  description: l10n.aboutAndDiagnosticsDesc,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiagnosticsScreen(initialIndex: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MoreMenuItem(
                  icon: Symbols.explore,
                  title: l10n.appTourWalkthrough,
                  description: l10n.appTourWalkthroughDesc,
                  onTap: () {
                    ref.read(onboardingProvider.notifier).restartWalkthrough();
                    context.go(Routes.home);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.supportAndCommunity,
            style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _MoreMenuItem(
                  icon: Symbols.favorite,
                  iconColor: const Color(0xFFFF5E5B),
                  title: l10n.supportUs,
                  description: l10n.supportUsDesc,
                  onTap: () => SupportUsSheet.show(context),
                ),
                const Divider(height: 1, indent: 56),
                _MoreMenuItem(
                  icon: Symbols.code,
                  brandSvg: AppBrandSvgs.github,
                  title: l10n.githubRepository,
                  description: l10n.githubRepositoryDesc,
                  onTap: () => AppExternalLinks.openUrl(
                    context,
                    AppExternalLinks.github,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    this.iconColor,
    this.brandSvg,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String? brandSvg;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final effectiveColor = iconColor ?? c.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Center(
                child: brandSvg != null
                    ? SvgPicture.string(
                        brandSvg!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          effectiveColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, size: 20, color: effectiveColor),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        AppTypography.cardTitle.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    description,
                    style:
                        AppTypography.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
