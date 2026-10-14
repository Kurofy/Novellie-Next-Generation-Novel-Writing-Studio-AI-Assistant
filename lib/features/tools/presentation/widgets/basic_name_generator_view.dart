import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/tools_providers.dart';
import 'name_result_card.dart';

class BasicNameGeneratorView extends ConsumerStatefulWidget {
  const BasicNameGeneratorView({super.key});

  @override
  ConsumerState<BasicNameGeneratorView> createState() =>
      _BasicNameGeneratorViewState();
}

class _BasicNameGeneratorViewState extends ConsumerState<BasicNameGeneratorView> {
  bool _plainTextMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(basicResultsProvider).isEmpty) {
        ref.read(nameGeneratorControllerProvider).generateBasic();
      }
    });
  }

  void _copyAll(BuildContext context, List<String> names, bool isIndo) {
    if (names.isEmpty) return;
    Clipboard.setData(ClipboardData(text: names.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIndo
            ? 'Menyalin ${names.length} nama ke papan klip'
            : 'Copied ${names.length} names to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final categoriesAsync = ref.watch(nameCategoriesProvider);
    final selectedCategory = ref.watch(basicCategoryProvider);
    final selectedGender = ref.watch(basicGenderProvider);
    final selectedCount = ref.watch(basicCountProvider);
    final results = ref.watch(basicResultsProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin(context),
        vertical: AppSpacing.md,
      ),
      children: [
        // Section: Category
        Text(
          isIndo ? 'Kategori Asal / Tema' : 'Origin / Theme Category',
          style: AppTypography.labelMd.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        categoriesAsync.when(
          data: (categories) {
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: categories.map((cat) {
                final isSelected =
                    cat.category.toLowerCase() == selectedCategory.toLowerCase();
                return ChoiceChip(
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
                  labelStyle: AppTypography.labelMd.copyWith(
                    color: isSelected ? c.textPrimary : c.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    if (val) {
                      ref.read(basicCategoryProvider.notifier).state =
                          cat.category;
                    }
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Text(isIndo ? 'Gagal memuat kategori.' : 'Failed to load categories.'),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Section: Gender & Quantity Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIndo ? 'Jenis Kelamin' : 'Gender',
                    style: AppTypography.labelMd.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final g in ['male', 'female', 'unisex'])
                        ChoiceChip(
                          label: Text(
                            g == 'male'
                                ? (isIndo ? 'Pria' : 'Male')
                                : (g == 'female'
                                    ? (isIndo ? 'Wanita' : 'Female')
                                    : (isIndo ? 'Uniseks' : 'Unisex')),
                          ),
                          selected: selectedGender == g,
                          selectedColor: c.primarySoft,
                          backgroundColor: c.surfaceSecondary,
                          checkmarkColor: c.textPrimary,
                          side: BorderSide(
                            color: selectedGender == g ? c.primary : c.outlineVariant,
                          ),
                          labelStyle: AppTypography.labelSm.copyWith(
                            color: selectedGender == g ? c.textPrimary : c.textSecondary,
                            fontWeight:
                                selectedGender == g ? FontWeight.w600 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) {
                              ref.read(basicGenderProvider.notifier).state = g;
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity
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
                    children: [1, 5, 10, 20].map((cnt) {
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
                            ref.read(basicCountProvider.notifier).state = cnt;
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

        // Generate Button
        NvButton(
          label: isIndo
              ? 'Hasilkan $selectedCount Nama'
              : 'Generate $selectedCount Names',
          icon: Symbols.casino,
          onPressed: () {
            ref.read(nameGeneratorControllerProvider).generateBasic();
          },
        ),

        const SizedBox(height: AppSpacing.x2),

        // Results Header
        if (results.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isIndo
                    ? 'Nama yang Dihasilkan (${results.length})'
                    : 'Generated Names (${results.length})',
                style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _plainTextMode ? Symbols.grid_view : Symbols.list,
                  size: 20,
                  color: c.textSecondary,
                ),
                tooltip: _plainTextMode
                    ? (isIndo ? 'Tampilan Kartu' : 'Card View')
                    : (isIndo ? 'Tampilan Daftar Sederhana' : 'Simple List View'),
                onPressed: () {
                  setState(() => _plainTextMode = !_plainTextMode);
                },
              ),
              IconButton(
                icon: Icon(Symbols.content_copy, size: 20, color: c.textSecondary),
                tooltip: isIndo ? 'Salin semua nama' : 'Copy all names',
                onPressed: () =>
                    _copyAll(context, results.map((e) => e.fullName).toList(), isIndo),
              ),
              IconButton(
                icon: Icon(Symbols.refresh, size: 20, color: c.textSecondary),
                tooltip: isIndo ? 'Hasilkan Ulang' : 'Regenerate',
                onPressed: () {
                  ref.read(nameGeneratorControllerProvider).generateBasic();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Display
          if (_plainTextMode)
            NvCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Text(
                            '${i + 1}. ',
                            style: AppTypography.labelMd.copyWith(color: c.textMuted),
                          ),
                          Expanded(
                            child: SelectableText(
                              results[i].fullName,
                              style: AppTypography.cardTitle.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Symbols.content_copy,
                              size: 16,
                              color: c.textSecondary,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: results[i].fullName),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isIndo
                                      ? 'Menyalin "${results[i].fullName}"'
                                      : 'Copied "${results[i].fullName}"'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (i < results.length - 1)
                      Divider(color: c.outlineVariant, height: 1),
                  ],
                ],
              ),
            )
          else
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
