import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../ai/presentation/screens/ai_config_dialog.dart';
import '../../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentThemeColor = ref.watch(themeColorProvider);
    final currentFontSize = ref.watch(editorFontSizeProvider);
    final currentFontFamily = ref.watch(editorFontFamilyProvider);
    final currentLanguage = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: NvAppBar(
        title: l10n?.settingsTitle ?? 'Settings',
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.xl,
        ),
        children: [
          // Theme Section
          Text(l10n?.settingsAppearance ?? 'Appearance', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.settingsThemeMode ?? 'Theme Mode', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n?.settingsThemeModeDesc ?? 'Choose how Novellie looks on your device',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return c.primarySoft;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return c.textPrimary;
                      }
                      return c.textSecondary;
                    }),
                    iconColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return c.textPrimary;
                      }
                      return c.textSecondary;
                    }),
                  ),
                  selectedIcon:
                      Icon(Symbols.check, size: 18, color: c.textPrimary),
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n?.settingsThemeSystem ?? 'System'),
                      icon: const Icon(Symbols.settings_suggest, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n?.settingsThemeLight ?? 'Light'),
                      icon: const Icon(Symbols.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n?.settingsThemeDark ?? 'Dark'),
                      icon: const Icon(Symbols.dark_mode, size: 18),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (newSelection) {
                    ref.read(themeModeProvider.notifier).state =
                        newSelection.first;
                  },
                ),
                const Divider(height: AppSpacing.xl),
                Text(l10n?.settingsColorTheme ?? 'Primary Color Theme', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n?.settingsColorThemeDesc ??
                      'The current color is the primary default. Choose an accent color to customize buttons, tags, and highlights.',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 460;
                    final itemWidth = isWide
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: AppThemeColor.values.map((color) {
                        final isSelected = currentThemeColor == color;
                        return SizedBox(
                          width: itemWidth,
                          child: _ColorThemeTile(
                            color: color,
                            isSelected: isSelected,
                            onTap: () {
                              ref.read(themeColorProvider.notifier).state =
                                  color;
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.palette, color: c.primary, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n?.activePreview ?? 'Active Preview',
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            currentThemeColor.displayName,
                            style: AppTypography.labelSm.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: NvButton(
                              label: l10n?.localeName == 'id' ? 'Utama' : 'Primary',
                              size: NvButtonSize.compact,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: NvButton.tonal(
                              label: l10n?.localeName == 'id' ? 'Aksen Tonal' : 'Tonal Accent',
                              size: NvButtonSize.compact,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const NvProgressBar.compact(value: 0.65),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Editor Preferences Section
          Text(l10n?.writingEditor ?? 'Writing Editor', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n?.settingsEditorFontSize ?? 'Editor Font Size', style: AppTypography.cardTitle),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(
                          color: c.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${currentFontSize.toInt()} pt',
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n?.editorFontSizeDesc ??
                      'Adjust the text size in the writing workspace and reading mode',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.remove, size: 20),
                      tooltip: 'Decrease font size',
                      onPressed: currentFontSize > 12.0
                          ? () {
                              ref
                                  .read(editorFontSizeProvider.notifier)
                                  .setFontSize(currentFontSize - 1.0);
                            }
                          : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: currentFontSize.clamp(12.0, 28.0),
                        min: 12.0,
                        max: 28.0,
                        divisions: 16,
                        label: '${currentFontSize.toInt()} pt',
                        onChanged: (val) {
                          ref
                              .read(editorFontSizeProvider.notifier)
                              .setFontSize(val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.add, size: 20),
                      tooltip: 'Increase font size',
                      onPressed: currentFontSize < 28.0
                          ? () {
                              ref
                                  .read(editorFontSizeProvider.notifier)
                                  .setFontSize(currentFontSize + 1.0);
                            }
                          : null,
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Text(l10n?.settingsEditorTypeface ?? 'Editor Typeface', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n?.editorTypefaceDesc ??
                      'Select your preferred typography family for drafting',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children:
                      AppEditorTypography.availableFontFamilies.map((font) {
                    final isSelected = currentFontFamily == font;
                    final fontStyle = AppEditorTypography.resolveTextStyle(
                      fontSize: 14,
                      fontFamily: font,
                      color: isSelected ? c.primary : c.textPrimary,
                    );
                    return ChoiceChip(
                      label: Text(font, style: fontStyle),
                      selected: isSelected,
                      selectedColor: c.primarySoft,
                      backgroundColor: c.surfaceSecondary,
                      checkmarkColor: c.textPrimary,
                      onSelected: (_) {
                        ref
                            .read(editorFontFamilyProvider.notifier)
                            .setFontFamily(font);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Live interactive sample preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.menu_book, size: 18, color: c.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n?.liveManuscriptPreview ?? 'Live Manuscript Preview',
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$currentFontFamily • ${currentFontSize.toInt()} pt',
                            style: AppTypography.labelSm.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: AppEditorTypography.resolveTextStyle(
                          fontSize: currentFontSize,
                          fontFamily: currentFontFamily,
                          color: c.textPrimary,
                          height: 1.6,
                        ),
                        child: Text(
                          l10n?.localeName == 'id'
                              ? 'Tinta di atas perkamen baru saja mengering ketika lonceng mulai berdentang. Julian berhenti sejenak, pena di tangan, menyaksikan kisah terbentang kata demi kata.'
                              : 'The ink had barely dried on the parchment when the bells began to chime. Julian paused, quill in hand, watching the story unfold word by word.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Language Section
          Text(
            l10n?.settingsLanguage ?? 'Language',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            onTap: () => _showLanguageSelectionSheet(context, ref),
            child: Row(
              children: [
                Icon(Symbols.translate, color: c.primary, size: 28),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.settingsLanguage ?? 'Language',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n?.settingsLanguageDesc ??
                            'Choose your preferred application language',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _getLanguageLabel(currentLanguage, l10n),
                    style: AppTypography.labelSm.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Symbols.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // AI Provider Section
          Text(l10n?.aiAssistantByok ?? 'AI Assistant (BYOK)', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          NvCard(
            onTap: () => AiConfigDialog.show(context),
            child: Row(
              children: [
                Icon(Symbols.auto_awesome, color: c.primary, size: 28),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.configureProvider ?? 'Configure Provider',
                        style: AppTypography.cardTitle,
                      ),
                      Text(
                        l10n?.configureProviderDesc ??
                            'Set up Gemini, OpenAI, Claude, or local Ollama API keys',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getLanguageLabel(AppLanguage lang, AppLocalizations? l10n) {
    switch (lang) {
      case AppLanguage.system:
        return l10n?.languageSystem ?? 'System Default';
      case AppLanguage.english:
        return l10n?.languageEnglish ?? 'English';
      case AppLanguage.indonesian:
        return l10n?.languageIndonesian ?? 'Bahasa Indonesia';
    }
  }

  static void _showLanguageSelectionSheet(
    BuildContext context,
    WidgetRef ref,
  ) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final selectedLang = sheetRef.watch(appLanguageProvider);

            return NvBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.translate, color: c.primary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n?.settingsLanguage ?? 'Language',
                        style: AppTypography.sectionTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n?.settingsLanguageDesc ??
                        'Choose your preferred application language',
                    style:
                        AppTypography.bodySm.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = selectedLang == lang;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: InkWell(
                        onTap: () {
                          sheetRef
                              .read(appLanguageProvider.notifier)
                              .setLanguage(lang);
                          Navigator.of(sheetContext).pop();
                        },
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? c.primarySoft : c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: isSelected
                                  ? c.primaryFill
                                  : c.outlineVariant.withValues(alpha: 0.35),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                lang == AppLanguage.system
                                    ? Symbols.settings_suggest
                                    : Symbols.language,
                                color: isSelected ? c.primary : c.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getLanguageLabel(lang, l10n),
                                      style: AppTypography.cardTitle.copyWith(
                                        color: c.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (lang == AppLanguage.system)
                                      Text(
                                        l10n?.localeName == 'id'
                                            ? 'Ikuti pengaturan bahasa perangkat'
                                            : 'Follow system device locale',
                                        style: AppTypography.bodySm.copyWith(
                                          color: c.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (lang == AppLanguage.english)
                                      Text(
                                        l10n?.localeName == 'id'
                                            ? 'Bahasa Inggris (Amerika Serikat)'
                                            : 'English (United States)',
                                        style: AppTypography.bodySm.copyWith(
                                          color: c.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (lang == AppLanguage.indonesian)
                                      Text(
                                        l10n?.localeName == 'id'
                                            ? 'Bahasa Indonesia (ID)'
                                            : 'Indonesian (Indonesia)',
                                        style: AppTypography.bodySm.copyWith(
                                          color: c.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Symbols.check_circle,
                                  color: c.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ColorThemeTile extends StatelessWidget {
  const _ColorThemeTile({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeColor color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${color.displayName}${color.isDefault ? ', Primary Default' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? c.primarySoft : c.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: isSelected
                    ? c.primaryFill
                    : c.outlineVariant.withValues(alpha: 0.35),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.previewColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.previewColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Symbols.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              color.displayName,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: c.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (color.isDefault) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? c.primaryFill : c.surfaceHigh,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Primary',
                                style: AppTypography.labelSm.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? c.onPrimary
                                      : c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        color.description,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: c.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
