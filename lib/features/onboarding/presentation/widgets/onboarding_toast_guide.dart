import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai/application/ai_providers.dart';
import '../../../ai/domain/models/ai_models.dart';
import '../../../ai/presentation/screens/ai_config_dialog.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../application/onboarding_providers.dart';
import '../../domain/models/onboarding_step_model.dart';

/// Walkthrough guide with an authentic Apple iPhone Setup Assistant UI.
class OnboardingToastGuide extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const OnboardingToastGuide({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<OnboardingToastGuide> createState() =>
      _OnboardingToastGuideState();
}

class _OnboardingToastGuideState extends ConsumerState<OnboardingToastGuide> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    if (!onboardingState.isActive) return const SizedBox.shrink();

    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = onboardingState.currentStep;
    final currentLanguage = ref.watch(appLanguageProvider);
    final aiConfig = ref.watch(aiConfigProvider).valueOrNull;
    final hasAiKey = (aiConfig != null && aiConfig.apiKey.trim().isNotEmpty);

    if (_isMinimized) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildMinimizedPill(c, isDark, step, onboardingState, l10n),
        ),
      );
    }

    return _buildIPhoneSetupWalkthrough(
      context,
      c,
      isDark,
      step,
      onboardingState,
      hasAiKey,
      aiConfig,
      currentLanguage,
      l10n,
    );
  }

  /// Minimized Apple Dynamic Island floating pill
  Widget _buildMinimizedPill(
    AppColors c,
    bool isDark,
    OnboardingStep step,
    OnboardingState state,
    AppLocalizations? l10n,
  ) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
                  : c.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: step.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Step Icon in Apple squircle
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: step.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(step.icon, size: 14, color: step.accentColor),
                ),
                const SizedBox(width: 8),

                // Step Title & Label (Tap to expand)
                InkWell(
                  onTap: () => setState(() => _isMinimized = false),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.getStepLabel(l10n),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Symbols.expand_less,
                            size: 16, color: step.accentColor,),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                Container(
                    width: 1,
                    height: 18,
                    color: c.outlineVariant.withValues(alpha: 0.6),),
                const SizedBox(width: 4),

                // Next Mini Button
                IconButton(
                  icon: Icon(
                    state.isLastStep ? Symbols.check : Symbols.arrow_forward,
                    size: 16,
                    color: step.accentColor,
                  ),
                  tooltip: state.isLastStep
                      ? (l10n?.getStarted ?? 'Get Started')
                      : (l10n?.next ?? 'Next Step'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _handleNext(state),
                ),

                const SizedBox(width: 6),

                // Close / Skip Button
                IconButton(
                  icon: const Icon(Symbols.close, size: 16),
                  tooltip: l10n?.skipTour ?? 'Skip Tour',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).skipWalkthrough();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full-screen Apple iPhone Setup Walkthrough
  Widget _buildIPhoneSetupWalkthrough(
    BuildContext context,
    AppColors c,
    bool isDark,
    OnboardingStep step,
    OnboardingState state,
    bool hasAiKey,
    AiConfigModel? aiConfig,
    AppLanguage currentLanguage,
    AppLocalizations? l10n,
  ) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final dragDistance = details.velocity.pixelsPerSecond.dx;
        if (dragDistance < -280) {
          _handleNext(state);
        } else if (dragDistance > 280 && !state.isFirstStep) {
          _handlePrevious(state);
        }
      },
      child: Container(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF2F2F7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: SafeArea(
            child: Column(
              children: [
                // Apple Setup Top Navigation Bar
                _buildIPhoneTopBar(c, isDark, step, state, l10n),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Apple Hero Squircle Glyph
                        _buildAppleHeroGlyph(step),
                        const SizedBox(height: 18),

                        // Step Counter Capsule & Badge
                        _buildAppleStepPill(c, isDark, step, l10n),
                        const SizedBox(height: 14),

                        // Big Bold Apple Title
                        Text(
                          step.getTitle(l10n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: c.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Elegant Subtitle / Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            step.getDescription(l10n),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // iOS Inset Grouped Feature & Setup Cards
                        _buildAppleFeatureCard(
                          context,
                          c,
                          isDark,
                          step,
                          hasAiKey,
                          aiConfig,
                          currentLanguage,
                          l10n,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Apple Bottom Dock (Pagination + Full Width Continue Button + Secondary Actions)
                _buildAppleBottomDock(c, isDark, step, state, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Apple Setup Top Navigation Bar
  Widget _buildIPhoneTopBar(
    AppColors c,
    bool isDark,
    OnboardingStep step,
    OnboardingState state,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          if (!state.isFirstStep)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                Symbols.chevron_left,
                size: 20,
                color: c.primary,
              ),
              label: Text(
                l10n?.back ?? 'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
              onPressed: () => _handlePrevious(state),
            )
          else
            const SizedBox(width: 60),

          // Dynamic Island Minimize Pill Button
          Tooltip(
            message: 'Minimize Guide',
            child: InkWell(
              onTap: () => setState(() => _isMinimized = true),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: c.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.unfold_less,
                      size: 14,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.tourMode ?? 'Tour Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Skip Tour Button
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              ref.read(onboardingProvider.notifier).skipWalkthrough();
            },
            child: Text(
              l10n?.skipTour ?? 'Skip Tour',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apple Hero Squircle with vibrant frosted gradient
  Widget _buildAppleHeroGlyph(OnboardingStep step) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.accentColor,
            step.accentColor.withValues(alpha: 0.76),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: step.accentColor.withValues(alpha: 0.38),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          step.icon,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Apple Step Counter Pill
  Widget _buildAppleStepPill(
    AppColors c,
    bool isDark,
    OnboardingStep step,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: step.accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: step.accentColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(step.icon, size: 14, color: step.accentColor),
          const SizedBox(width: 6),
          Text(
            step.getStepLabel(l10n),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: step.accentColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: step.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            step.getBadgeLabel(l10n),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// iOS Inset Grouped Feature List & Setup Details
  Widget _buildAppleFeatureCard(
    BuildContext context,
    AppColors c,
    bool isDark,
    OnboardingStep step,
    bool hasAiKey,
    AiConfigModel? aiConfig,
    AppLanguage currentLanguage,
    AppLocalizations? l10n,
  ) {
    final actionLabel = step.getActionButtonLabel(l10n);
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
            : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Core Capability
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: step.accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(step.icon, size: 18, color: step.accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.coreStudioCapability ?? 'Core Studio Capability',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.getDescription(l10n),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.25)),

          // Row 2: Pro Tip / Writer Insight
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Symbols.lightbulb,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${l10n?.proTipLabel ?? 'Pro Tip'}: ${step.getProTip(l10n)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: c.textPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 3: Special Interactive Action
          if (step == OnboardingStep.chooseLanguage) ...[
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildLanguageSelectorWidget(c, isDark, currentLanguage, l10n),
            ),
          ] else if (step == OnboardingStep.aiKeyPrompt) ...[
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildAiKeySpecialWidget(c, hasAiKey, aiConfig, l10n),
            ),
          ] else if (actionLabel != null) ...[
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.25)),
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              onTap: () {
                if (step == OnboardingStep.settingsTab) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                } else if (step.targetBranchIndex != null) {
                  widget.navigationShell.goBranch(step.targetBranchIndex!);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(step.icon, size: 16, color: step.accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: step.accentColor,
                        ),
                      ),
                    ),
                    Icon(
                      Symbols.arrow_outward,
                      size: 16,
                      color: step.accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Apple Bottom Action Dock
  Widget _buildAppleBottomDock(
    AppColors c,
    bool isDark,
    OnboardingStep step,
    OnboardingState state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141416).withValues(alpha: 0.9)
            : c.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Apple Pagination Capsules
          _buildInteractiveProgressTrack(step, state, c, l10n),
          const SizedBox(height: 14),

          // Full Width Apple Primary Continue Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: step.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                elevation: 3,
                shadowColor: step.accentColor.withValues(alpha: 0.45),
              ),
              onPressed: () => _handleNext(state),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isLastStep
                        ? (l10n?.getStarted ?? 'Get Started')
                        : (l10n?.next ?? 'Next'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    state.isLastStep ? Symbols.check : Symbols.arrow_forward,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apple Interactive Progress Capsules
  Widget _buildInteractiveProgressTrack(
    OnboardingStep step,
    OnboardingState state,
    AppColors c,
    AppLocalizations? l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        state.totalSteps,
        (index) {
          final isCurrent = index == state.currentStepIndex;
          final isPast = index < state.currentStepIndex;
          final targetStep = OnboardingStep.values[index];

          return Tooltip(
            message: targetStep.getTitle(l10n),
            child: InkWell(
              onTap: () {
                if (targetStep.targetBranchIndex != null) {
                  widget.navigationShell
                      .goBranch(targetStep.targetBranchIndex!);
                }
                ref.read(onboardingProvider.notifier).goToStep(targetStep);
              },
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? step.accentColor
                      : isPast
                          ? step.accentColor.withValues(alpha: 0.45)
                          : c.outlineVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: step.accentColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Page 1: Language Selector Card in Apple iOS style
  Widget _buildLanguageSelectorWidget(
    AppColors c,
    bool isDark,
    AppLanguage currentLanguage,
    AppLocalizations? l10n,
  ) {
    final languages = [
      (
        lang: AppLanguage.system,
        title: l10n?.languageSystem ?? 'System Default',
        subtitle: 'Follow device settings · Ikuti sistem',
        badge: 'AUTO',
        icon: Symbols.settings_suggest,
      ),
      (
        lang: AppLanguage.english,
        title: l10n?.languageEnglish ?? 'English',
        subtitle: 'English (United States)',
        badge: 'EN',
        icon: Symbols.language,
      ),
      (
        lang: AppLanguage.indonesian,
        title: l10n?.languageIndonesian ?? 'Bahasa Indonesia',
        subtitle: 'Bahasa Indonesia (ID)',
        badge: 'ID',
        icon: Symbols.translate,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Symbols.translate, size: 14, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                l10n?.selectApplicationLanguage ?? 'Select Application Language',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...languages.map((item) {
          final isSelected = currentLanguage == item.lang;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref.read(appLanguageProvider.notifier).setLanguage(item.lang);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.22 : 0.12)
                        : isDark
                            ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
                            : c.surfaceSecondary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : c.outlineVariant.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : isDark
                                  ? const Color(0xFF3A3A3C)
                                  : c.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            item.badge,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : c.outlineVariant.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Symbols.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Step 2: AI Provider Status Card in Apple iOS style
  Widget _buildAiKeySpecialWidget(
    AppColors c,
    bool hasAiKey,
    AiConfigModel? aiConfig,
    AppLocalizations? l10n,
  ) {
    final isIndonesian = l10n?.localeName == 'id';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasAiKey
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAiKey
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: hasAiKey
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAiKey ? Symbols.verified : Symbols.key,
              size: 20,
              color:
                  hasAiKey ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAiKey
                      ? (isIndonesian
                          ? 'Kunci AI Aktif & Siap (${aiConfig?.provider.label ?? "BYOK"})'
                          : 'AI Key Active & Ready (${aiConfig?.provider.label ?? "BYOK"})')
                      : (l10n?.aiKeyNotConfigured ?? 'AI Provider Key not yet configured'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: hasAiKey
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasAiKey
                      ? (l10n?.aiKeyConfiguredDesc ??
                          'Free Gemini / OpenAI / Claude keys power worldbuilding & drafting')
                      : (l10n?.aiKeyRequiredDesc ??
                          'Free Gemini 1.5 Flash keys or OpenAI/Claude required for AI tools'),
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: hasAiKey
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () => AiConfigDialog.show(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.tune,
                  size: 14,
                  color: hasAiKey
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  hasAiKey
                      ? (l10n?.changeKey ?? 'Change Key')
                      : (l10n?.configureKey ?? 'Configure Key'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: hasAiKey
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(OnboardingState state) {
    if (state.isLastStep) {
      ref.read(onboardingProvider.notifier).completeWalkthrough();
    } else {
      final nextIndex = state.currentStepIndex + 1;
      final nextStep = OnboardingStep.values[nextIndex];
      if (nextStep.targetBranchIndex != null) {
        widget.navigationShell.goBranch(nextStep.targetBranchIndex!);
      }
      ref.read(onboardingProvider.notifier).nextStep();
    }
  }

  void _handlePrevious(OnboardingState state) {
    if (state.isFirstStep) return;
    final prevIndex = state.currentStepIndex - 1;
    final prevStep = OnboardingStep.values[prevIndex];
    if (prevStep.targetBranchIndex != null) {
      widget.navigationShell.goBranch(prevStep.targetBranchIndex!);
    }
    ref.read(onboardingProvider.notifier).previousStep();
  }
}
