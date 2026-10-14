import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/tools_providers.dart';
import '../../domain/models/name_models.dart';
import '../widgets/advanced_name_generator_view.dart';
import '../widgets/basic_name_generator_view.dart';
import '../widgets/name_result_card.dart';

class NameGeneratorScreen extends ConsumerStatefulWidget {
  const NameGeneratorScreen({
    super.key,
    this.initialMode,
  });

  final NameGeneratorMode? initialMode;

  @override
  ConsumerState<NameGeneratorScreen> createState() =>
      _NameGeneratorScreenState();
}

class _NameGeneratorScreenState extends ConsumerState<NameGeneratorScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeNameGenModeProvider.notifier).state =
            widget.initialMode!;
      });
    }
  }

  void _showInfoDialog(BuildContext context, bool isIndo) {
    final c = context.colors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          isIndo ? 'Mode Generator Nama' : 'Name Generator Modes',
          style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo ? 'Mode 1: Generator Dasar' : 'Mode 1: Basic Generator',
              style: AppTypography.cardTitle.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isIndo
                  ? 'Menghasilkan nama depan dan belakang acak langsung dari kumpulan data budaya & fantasi (Romawi, Yunani, Nordik, Elf, Iblis, dll.) tanpa mengubah ejaan.'
                  : 'Generates authentic random first and last names directly from curated cultural & fantasy datasets (Roman, Greek, Nordic, Elf, Demon, etc.) without modifying spellings.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isIndo
                  ? 'Mode 2: Generator Lanjutan dengan AI (BYOK)'
                  : 'Mode 2: Advanced Generator with AI (BYOK)',
              style: AppTypography.cardTitle.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),
            Text(
              isIndo
                  ? 'Menggabungkan fonetik dan suku kata dari dataset referensi dengan sifat karakter, estetika, atau latar belakang khusus untuk membuat nama baru lengkap dengan gelar, arti, dan latar belakang singkat.'
                  : 'Fuses phonetics and syllables from the reference dataset with your custom character traits, aesthetics, or hybrid backgrounds to synthesize new names with titles, meanings, and short backstories.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isIndo ? 'Mengerti' : 'Got it'),
          ),
        ],
      ),
    );
  }

  void _openFavoritesSheet(BuildContext context, bool isIndo) {
    showNvBottomSheet<void>(
      context: context,
      title: isIndo ? 'Nama Favorit Tersimpan' : 'Saved Favorite Names',
      subtitle: isIndo
          ? 'Markah di seluruh mode Dasar & Lanjutan'
          : 'Bookmarks across Basic & Advanced modes',
      child: const _FavoritesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final activeMode = ref.watch(activeNameGenModeProvider);
    final favCount = ref.watch(favoriteNamesProvider).length;

    return Scaffold(
      appBar: NvAppBar(
        title: isIndo ? 'Generator Nama' : 'Names Generator',
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Symbols.star, size: 22),
                if (favCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$favCount',
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: isIndo ? 'Nama Favorit' : 'Favorite Names',
            onPressed: () => _openFavoritesSheet(context, isIndo),
          ),
          IconButton(
            icon: const Icon(Symbols.help_outline, size: 22),
            tooltip: isIndo ? 'Info Mode' : 'Mode Info',
            onPressed: () => _showInfoDialog(context, isIndo),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Mode Selector
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin(context),
              vertical: AppSpacing.sm,
            ),
            child: NvSegmented<NameGeneratorMode>(
              selected: activeMode,
              segments: [
                NvSegment(
                  value: NameGeneratorMode.basic,
                  label: isIndo ? 'Mode 1: Dasar' : 'Mode 1: Basic',
                  icon: Symbols.menu_book,
                ),
                NvSegment(
                  value: NameGeneratorMode.advanced,
                  label: isIndo ? 'Mode 2: Lanjutan (AI)' : 'Mode 2: Advanced (AI)',
                  icon: Symbols.auto_awesome,
                ),
              ],
              onChanged: (mode) {
                ref.read(activeNameGenModeProvider.notifier).state = mode;
              },
            ),
          ),

          // Main View
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: activeMode == NameGeneratorMode.basic
                  ? const BasicNameGeneratorView(key: ValueKey('basic_mode'))
                  : const AdvancedNameGeneratorView(key: ValueKey('advanced_mode')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSheet extends ConsumerWidget {
  const _FavoritesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final favorites = ref.watch(favoriteNamesProvider);

    if (favorites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3, horizontal: AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(Symbols.star_outline, size: 48, color: c.textMuted),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isIndo ? 'Belum ada nama favorit' : 'No favorite names yet',
                style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
              ),

              const SizedBox(height: AppSpacing.xs),
              Text(
                isIndo
                    ? 'Beri bintang pada nama dari generator untuk meninjau atau menyimpannya nanti.'
                    : 'Star names from the generator to review or save them later.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = favorites[index];
          return NameResultCard(name: item);
        },
      ),
    );
  }
}
