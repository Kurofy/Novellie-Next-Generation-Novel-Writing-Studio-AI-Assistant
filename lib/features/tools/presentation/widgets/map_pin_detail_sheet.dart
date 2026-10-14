import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../characters/application/character_providers.dart';
import '../../../characters/presentation/screens/character_detail_screen.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../world/application/world_providers.dart';
import '../../../world/presentation/screens/world_entry_detail_screen.dart';
import '../../application/world_map_providers.dart';
import '../../domain/models/world_map_models.dart';
import 'map_pin_dialog.dart';

class MapPinDetailSheet extends ConsumerWidget {
  final String novelId;
  final String mapId;
  final MapPin pin;

  const MapPinDetailSheet({
    super.key,
    required this.novelId,
    required this.mapId,
    required this.pin,
  });

  static Future<void> show(
    BuildContext context, {
    required String novelId,
    required String mapId,
    required MapPin pin,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapPinDetailSheet(
        novelId: novelId,
        mapId: mapId,
        pin: pin,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus Penanda Peta?' : 'Delete Map Marker?'),
        content: Text(
          isIndo
              ? 'Apakah Anda yakin ingin menghapus "${pin.title}" dari peta ini?'
              : 'Are you sure you want to remove "${pin.title}" from this map?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isIndo ? 'Hapus' : 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(worldMapProvider(novelId).notifier).deletePin(pin.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    Navigator.of(context).pop();
    await MapPinDialog.show(
      context,
      novelId: novelId,
      mapId: mapId,
      x: pin.x,
      y: pin.y,
      pinToEdit: pin,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final cat = pin.category;

    final codexEntriesAsync = ref.watch(
      worldEntriesStreamProvider(
        (novelId: novelId, categoryId: null),
      ),
    );
    final charactersAsync = ref.watch(charactersStreamProvider(novelId));
    final chaptersAsync = ref.watch(chaptersStreamProvider(novelId));

    return NvBottomSheet(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Category Chip and Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cat.color, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 14, color: cat.color),
                                const SizedBox(width: 6),
                                Text(
                                  cat.localizedLabel(isIndo),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cat.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pin.x * 100).toStringAsFixed(1)}% · ${(pin.y * 100).toStringAsFixed(1)}%',
                            style: AppTypography.bodySm
                                .copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        pin.title,
                        style: AppTypography.screenTitle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.edit),
                  tooltip: isIndo ? 'Ubah Penanda' : 'Edit Marker',
                  onPressed: () => _handleEdit(context),
                ),
                IconButton(
                  icon: Icon(Symbols.delete, color: c.error),
                  tooltip: isIndo ? 'Hapus Penanda' : 'Delete Marker',
                  onPressed: () => _handleDelete(context, ref),
                ),
                IconButton(
                  icon: const Icon(Symbols.close),
                  tooltip: isIndo ? 'Tutup' : 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            if (pin.description != null && pin.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                pin.description!,
                style: AppTypography.body.copyWith(
                  color: c.textSecondary,
                  height: 1.45,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Linked Codex Entry Section
            if (pin.linkedEntryId != null) ...[
              Text(
                isIndo ? 'Lokasi Kodeks Tertaut' : 'Linked Codex Location',
                style: AppTypography.labelMd.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              codexEntriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (entries) {
                  final entry = entries
                      .where((e) => e.id == pin.linkedEntryId)
                      .firstOrNull;
                  if (entry == null) {
                    return Text(
                      isIndo
                          ? 'Entri kodeks yang dirujuk sudah tidak ada.'
                          : 'Referenced codex entry no longer exists.',
                      style: AppTypography.bodySm.copyWith(color: c.textMuted),
                    );
                  }

                  return NvCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              WorldEntryDetailScreen(entryId: entry.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Symbols.auto_stories,
                              color: c.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.name,
                                    style: AppTypography.cardTitle,
                                  ),
                                  if (entry.verifiedCanon) ...[
                                    const SizedBox(width: 6),
                                    Icon(Symbols.verified,
                                        size: 14, color: c.primary),
                                  ],
                                ],
                              ),
                              if (entry.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  entry.subtitle!,
                                  style: AppTypography.bodySm
                                      .copyWith(color: c.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Symbols.chevron_right,
                            color: c.textMuted, size: 18),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Linked Characters Section
            if (pin.linkedCharacterIds.isNotEmpty) ...[
              Text(
                isIndo
                    ? 'Karakter di Lokasi Ini (${pin.linkedCharacterIds.length})'
                    : 'Characters at this Location (${pin.linkedCharacterIds.length})',
                style: AppTypography.labelMd.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              charactersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (characters) {
                  final linked = characters
                      .where((ch) => pin.linkedCharacterIds.contains(ch.id))
                      .toList();

                  if (linked.isEmpty) return const SizedBox.shrink();

                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: linked.map((ch) {
                      return ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: c.primary.withValues(alpha: 0.2),
                          child: Text(
                            ch.name.isNotEmpty ? ch.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 10, color: c.primary),
                          ),
                        ),
                        label: Text(ch.name),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CharacterDetailScreen(characterId: ch.id),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Linked Chapters Section
            if (pin.linkedChapterIds.isNotEmpty) ...[
              Text(
                isIndo
                    ? 'Tampil dalam Bab (${pin.linkedChapterIds.length})'
                    : 'Featured in Chapters (${pin.linkedChapterIds.length})',
                style: AppTypography.labelMd.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              chaptersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (chapters) {
                  final linked = chapters
                      .where((ch) => pin.linkedChapterIds.contains(ch.id))
                      .toList();

                  if (linked.isEmpty) return const SizedBox.shrink();

                  return Column(
                    children: linked.map((ch) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Symbols.menu_book, size: 18, color: c.primary),
                        title:
                            Text(ch.displayTitle, style: AppTypography.bodySm),
                        subtitle: Text(
                          isIndo ? '${ch.wordCount} kata' : '${ch.wordCount} words',
                          style: AppTypography.labelSm,
                        ),
                        trailing: Icon(Symbols.chevron_right,
                            size: 16, color: c.textMuted),
                        onTap: () {
                          context.push(Routes.chapterEditor(novelId, ch.id));
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
