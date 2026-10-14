import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import 'family_tree_screen.dart';
import 'mind_map_screen.dart';
import 'name_generator_screen.dart';
import 'world_atlas_screen.dart';
import 'writer_notes_screen.dart';

class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndonesian = l10n?.localeName == 'id';

    return Scaffold(
      appBar: NvAppBar(
        title: l10n?.navTools ?? 'Tools',
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.lg,
        ),
        children: [
          // Header Description
          Text(
            l10n?.writersWorkshop ?? 'Writer’s Workshop',
            style: AppTypography.screenTitle.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),
          Text(
            l10n?.writersWorkshopDesc ??
                'Specialized worldbuilding instruments, plot generators, and utilities.',
            style: AppTypography.bodySm.copyWith(color: c.textSecondary),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Primary Active Tool: Names Generator
          _FeaturedToolCard(
            title: l10n?.namesGenerator ?? 'Names Generator',
            subtitle: l10n?.namesGeneratorDesc ??
                'Generate authentic character names across 14 cultural & fantasy origins, or craft deep mythic lore with AI (BYOK).',
            icon: Symbols.badge,
            accentColor: c.primary,
            badgeText: isIndonesian ? 'Aktif' : 'Active',
            buttonLabel: l10n?.openGenerator ?? 'Open Generator',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NameGeneratorScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Active Tool 2: Family Tree
          _FeaturedToolCard(
            title: l10n?.familyTree ?? 'Family Tree',
            subtitle: l10n?.familyTreeDesc ??
                'Create and visualize distinct multi-generational family trees, royal dynasties, and character lineages.',
            icon: Symbols.family_restroom,
            accentColor: const Color(0xFFD97706),
            badgeText: isIndonesian ? 'Aktif' : 'Active',
            buttonLabel: l10n?.openTool ?? 'Open Tool',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FamilyTreeScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Active Tool 3: Mind Map (Story Arcs & Brainstorming)
          _FeaturedToolCard(
            title: l10n?.mindMap ?? 'Mind Map',
            subtitle: l10n?.mindMapDesc ??
                'Brainstorm ideas, sequence narrative chapter progressions, plot story arcs, and link dramatic beats.',
            icon: Symbols.hub,
            accentColor: const Color(0xFF6366F1),
            badgeText: isIndonesian ? 'Aktif' : 'Active',
            buttonLabel: l10n?.openTool ?? 'Open Tool',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MindMapScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Active Tool 4: World Atlas
          _FeaturedToolCard(
            title: l10n?.worldAtlas ?? 'World Atlas',
            subtitle: isIndonesian
                ? 'Kartografi vektor interaktif dengan impor SVG Azgaar & Inkarnate, penanda lokasi Codex, dan pemetaan tempat tinggal karakter.'
                : 'Interactive vector cartography with Azgaar & Inkarnate SVG imports, Codex location markers, and character residency mapping.',
            icon: Symbols.map,
            accentColor: const Color(0xFF0284C7),
            badgeText: isIndonesian ? 'Aktif' : 'Active',
            buttonLabel: l10n?.openTool ?? 'Open Tool',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WorldAtlasScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Active Tool 5: Writer Notes (Google Keep style)
          _FeaturedToolCard(
            title: l10n?.writersNotes ?? (isIndonesian ? 'Catatan Penulis' : 'Writer Notes'),
            subtitle: isIndonesian
                ? 'Catat dialog instan, ide plot, dan daftar periksa dalam kisi gaya Google Keep berwarna dengan tag dan tautan novel.'
                : 'Capture instant dialogues, plot ideas, and checklists in a colorful Google Keep-style grid with tags and novel links.',
            icon: Symbols.note_alt,
            accentColor: const Color(0xFFF59E0B),
            badgeText: isIndonesian ? 'Aktif' : 'Active',
            buttonLabel: l10n?.openTool ?? 'Open Tool',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WriterNotesScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.x4),
        ],
      ),
    );
  }
}

class _FeaturedToolCard extends StatelessWidget {
  const _FeaturedToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
    required this.onTap,
    this.buttonLabel = 'Open Tool',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final VoidCallback onTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return NvCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.cardTitle.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTypography.labelSm.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),


                      ],
                    ),
                  ),
                  Icon(Symbols.chevron_right, color: c.textMuted, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NvButton(
                    label: buttonLabel,
                    icon: Symbols.arrow_forward,
                    onPressed: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

