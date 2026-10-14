import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../ai/application/ai_providers.dart';
import '../../../ai/presentation/screens/ai_config_dialog.dart';
import '../../application/tools_providers.dart';
import 'name_result_card.dart';

class AdvancedNameGeneratorView extends ConsumerStatefulWidget {
  const AdvancedNameGeneratorView({super.key});

  @override
  ConsumerState<AdvancedNameGeneratorView> createState() =>
      _AdvancedNameGeneratorViewState();
}

class _AdvancedNameGeneratorViewState
    extends ConsumerState<AdvancedNameGeneratorView> {
  late TextEditingController _promptController;

  final List<String> _quickPresets = const [
    'A ruthless half-Demon, half-Nordic warlord who rules a frozen wasteland',
    'A celestial high-Elf archivist chronicling dying constellations',
    'A cyberpunk Indonesian netrunner with covert bio-implants',
    'An aristocratic Victorian Vampire diplomat with centuries of secrets',
    'A fiery Greek dragon-blooded gladiator seeking vengeance',
    'A melancholy Japanese spirit-blade craftsman in exile',
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: ref.read(advancedTraitsPromptProvider),
    );
    if (_promptController.text.isEmpty) {
      _promptController.text =
          'A ruthless half-Demon, half-Nordic warlord who rules a frozen wasteland';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(advancedTraitsPromptProvider.notifier).state =
            _promptController.text;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final configAsync = ref.watch(aiConfigProvider);
    final config = configAsync.valueOrNull;
    final isConfigured = config?.isConfigured ?? false;

    final categoriesAsync = ref.watch(nameCategoriesProvider);
    final selectedOrigins = ref.watch(advancedOriginTagsProvider);
    final selectedGender = ref.watch(advancedGenderProvider);
    final selectedCount = ref.watch(advancedCountProvider);
    final isGenerating = ref.watch(advancedIsGeneratingProvider);
    final error = ref.watch(advancedErrorProvider);
    final results = ref.watch(advancedResultsProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin(context),
        vertical: AppSpacing.md,
      ),
      children: [
        // BYOK Status Card
        if (!isConfigured)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Symbols.key, color: Colors.amber, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIndo
                            ? 'Kunci API AI Diperlukan (BYOK)'
                            : 'AI API Key Required (BYOK)',
                        style: AppTypography.labelMd.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isIndo
                            ? 'Masukkan kunci Google Gemini, OpenAI, atau Anthropic Anda untuk mengaktifkan pembuatan nama AI.'
                            : 'Provide your Google Gemini, OpenAI, or Anthropic key to enable creative AI generation.',
                        style: AppTypography.labelSm.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => AiConfigDialog.show(context),
                  child: Text(isIndo ? 'Atur Kunci' : 'Setup Key'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: c.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Symbols.check_circle, size: 16, color: c.success),
                const SizedBox(width: 6),
                Text(
                  isIndo
                      ? 'Terhubung ke ${config?.provider.label ?? "AI"} (${config?.model ?? ""})'
                      : 'Connected to ${config?.provider.label ?? "AI"} (${config?.model ?? ""})',
                  style: AppTypography.labelSm.copyWith(color: c.textSecondary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => AiConfigDialog.show(context),
                  child: Text(
                    isIndo ? 'Ubah' : 'Change',
                    style: AppTypography.labelSm.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Input Field: Traits, Aesthetic, Backstory
        Text(
          isIndo
              ? 'Sifat Karakter, Estetika & Latar Belakang'
              : 'Character Traits, Aesthetic & Background',
          style: AppTypography.labelMd.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _promptController,
          maxLines: 3,
          style: AppTypography.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: isIndo
                ? 'contoh: Seorang panglima perang setengah Iblis, setengah Nordik kejam yang menguasai gurun es…'
                : 'e.g. A ruthless half-Demon, half-Nordic warlord who rules a frozen wasteland…',
            hintStyle: AppTypography.bodySm.copyWith(color: c.textMuted),
            filled: true,
            fillColor: c.surfaceSecondary,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: BorderSide(color: c.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: BorderSide(color: c.primary, width: 1.5),
            ),
          ),
          onChanged: (val) {
            ref.read(advancedTraitsPromptProvider.notifier).state = val;
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Quick Preset Inspiration Chips
        Text(
          isIndo ? 'Inspirasi Cepat:' : 'Quick Inspirations:',
          style: AppTypography.labelSm.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickPresets.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(
                    preset.length > 32 ? '${preset.substring(0, 32)}…' : preset,
                  ),
                  tooltip: preset,
                  backgroundColor: c.surfaceSecondary,
                  side: BorderSide(color: c.outlineVariant),
                  labelStyle: AppTypography.labelSm.copyWith(color: c.textSecondary),
                  onPressed: () {
                    _promptController.text = preset;
                    ref.read(advancedTraitsPromptProvider.notifier).state = preset;
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Syllable / Cultural Origin Influences
        Text(
          isIndo
              ? 'Pengaruh Suku Kata & Budaya (Opsional)'
              : 'Syllable & Cultural Influences (Optional)',
          style: AppTypography.labelMd.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isIndo
              ? 'Pilih asal untuk mencocokkan suku kata fonetik dari kumpulan data nama'
              : 'Select origins to feed matching phonetic syllables from novellie_names_all.json',
          style: AppTypography.labelSm.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),

        categoriesAsync.when(
          data: (categories) {
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: categories.map((cat) {
                final isSelected = selectedOrigins.contains(cat.category);
                return FilterChip(
                  avatar: Icon(
                    cat.iconSymbol,
                    size: 16,
                    color: isSelected ? c.textPrimary : c.textSecondary,
                  ),
                  label: Text(cat.category),
                  selected: isSelected,
                  selectedColor: c.primarySoft,
                  backgroundColor: c.surfaceSecondary,
                  checkmarkColor: c.textPrimary,
                  side: BorderSide(
                    color: isSelected ? c.primary : c.outlineVariant,
                  ),
                  labelStyle: AppTypography.labelSm.copyWith(
                    color: isSelected ? c.textPrimary : c.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    final set = Set<String>.from(selectedOrigins);
                    if (val) {
                      set.add(cat.category);
                    } else {
                      set.remove(cat.category);
                    }
                    ref.read(advancedOriginTagsProvider.notifier).state = set;
                  },
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Gender & Quantity Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIndo ? 'Preferensi Jenis Kelamin' : 'Gender Preference',
                    style: AppTypography.labelMd.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    children: ['any', 'male', 'female', 'unisex'].map((g) {
                      final isSelected = selectedGender == g;
                      final labelText = g == 'any'
                          ? (isIndo ? 'Semua' : 'Any')
                          : (g == 'male'
                              ? (isIndo ? 'Pria' : 'Male')
                              : (g == 'female'
                                  ? (isIndo ? 'Wanita' : 'Female')
                                  : (isIndo ? 'Uniseks' : 'Unisex')));
                      return ChoiceChip(
                        label: Text(labelText),
                        selected: isSelected,
                        selectedColor: c.primarySoft,
                        backgroundColor: c.surfaceSecondary,
                        checkmarkColor: c.textPrimary,
                        side: BorderSide(
                          color: isSelected ? c.primary : c.outlineVariant,
                        ),
                        labelStyle: AppTypography.labelSm.copyWith(
                          color: isSelected ? c.textPrimary : c.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (val) {
                          if (val) {
                            ref.read(advancedGenderProvider.notifier).state = g;
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIndo ? 'Jumlah' : 'Count',
                    style: AppTypography.labelMd.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    children: [1, 3, 5].map((cnt) {
                      final isSelected = selectedCount == cnt;
                      return ChoiceChip(
                        label: Text('$cnt'),
                        selected: isSelected,
                        selectedColor: c.primarySoft,
                        backgroundColor: c.surfaceSecondary,
                        checkmarkColor: c.textPrimary,
                        side: BorderSide(
                          color: isSelected ? c.primary : c.outlineVariant,
                        ),
                        labelStyle: AppTypography.labelSm.copyWith(
                          color: isSelected ? c.textPrimary : c.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        onSelected: (val) {
                          if (val) {
                            ref.read(advancedCountProvider.notifier).state = cnt;
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Error message if any
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: c.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Symbols.error, color: c.error, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    error,
                    style: AppTypography.bodySm.copyWith(color: c.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Generate Button
        NvButton(
          label: isGenerating
              ? (isIndo ? 'Merangkai Lore & Nama…' : 'Crafting Lore & Names…')
              : (isIndo ? 'Hasilkan dengan AI' : 'Generate with AI'),
          icon: Symbols.auto_awesome,
          isLoading: isGenerating,
          onPressed: isGenerating
              ? null
              : () {
                  ref.read(nameGeneratorControllerProvider).generateAdvanced();
                },
        ),

        const SizedBox(height: AppSpacing.x2),

        // AI Generated Results
        if (results.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isIndo
                    ? 'Nama Hasil Karya AI (${results.length})'
                    : 'AI Crafted Names (${results.length})',
                style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Symbols.refresh, size: 20, color: c.textSecondary),
                tooltip: isIndo ? 'Hasilkan Ulang' : 'Regenerate',
                onPressed: isGenerating
                    ? null
                    : () {
                        ref
                            .read(nameGeneratorControllerProvider)
                            .generateAdvanced();
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...results.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: NameResultCard(name: name),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.x4),
      ],
    );
  }
}
