import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../tools/presentation/screens/mind_map_screen.dart';
import '../../application/world_providers.dart';
import '../../domain/models/world_models.dart';
import 'create_world_entry_dialog.dart';
import 'world_entry_detail_screen.dart';

class WorldEncyclopediaScreen extends ConsumerStatefulWidget {
  final String novelId;
  final bool showAppBar;

  const WorldEncyclopediaScreen({
    super.key,
    required this.novelId,
    this.showAppBar = false,
  });

  @override
  ConsumerState<WorldEncyclopediaScreen> createState() =>
      _WorldEncyclopediaScreenState();
}

class _WorldEncyclopediaScreenState
    extends ConsumerState<WorldEncyclopediaScreen>
    with AutomaticKeepAliveClientMixin {
  String? _selectedCategoryId;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final categoriesAsync =
        ref.watch(worldCategoriesStreamProvider(widget.novelId));
    final entriesAsync = ref.watch(
      worldEntriesStreamProvider(
        (novelId: widget.novelId, categoryId: _selectedCategoryId),
      ),
    );

    return Scaffold(
      backgroundColor: widget.showAppBar ? c.surface : Colors.transparent,
      appBar: widget.showAppBar
          ? NvAppBar(
              title: l10n?.worldEncyclopedia ?? 'World Encyclopedia',
              actions: [
                IconButton(
                  icon: const Icon(Symbols.hub),
                  tooltip: isIndo ? 'Peta Pikiran Cerita' : 'Story Mind Map',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MindMapScreen(initialNovelId: widget.novelId),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => CreateWorldEntryDialog.show(
          context,
          widget.novelId,
          categoryId: _selectedCategoryId,
        ),
        backgroundColor: c.primaryFill,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.add_location_alt),
        label: Text(l10n?.addEntry ?? 'Add Entry'),
      ),
      body: entriesAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: NvErrorState(
              title: isIndo ? 'Gagal memuat entri dunia' : 'Failed to load world entries',
              message: isIndo ? 'Terjadi kesalahan saat memuat ensiklopedia dunia.' : 'An error occurred while loading world encyclopedia.',
              onRetry: () => ref.invalidate(
                worldEntriesStreamProvider(
                  (novelId: widget.novelId, categoryId: _selectedCategoryId),
                ),
              ),
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty && _selectedCategoryId == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.public,
                  title: l10n?.noWorldLoreYet ?? 'No world lore yet',
                  body: l10n?.noWorldLoreBody ??
                      'Catalog places, factions, magic, and history so your story stays consistent.',
                  actionLabel: l10n?.addFirstEntry ?? 'Create Entry',
                  onAction: () => CreateWorldEntryDialog.show(
                    context,
                    widget.novelId,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Categories Horizontal Scroll
              categoriesAsync.maybeWhen(
                data: (categories) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) {
                          final isSelected = _selectedCategoryId == null;
                          return ChoiceChip(
                            label: Text(l10n?.allCategories ?? 'All'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategoryId = null);
                              }
                            },
                            selectedColor: c.primarySoft,
                            backgroundColor: c.surfaceSecondary,
                            labelStyle: TextStyle(
                              color: isSelected ? c.primary : c.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected ? cat.id : null;
                              });
                            },
                            selectedColor: c.primarySoft,
                            backgroundColor: c.surfaceSecondary,
                            labelStyle: TextStyle(
                              color: isSelected ? c.primary : c.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: NvEmptyState.noMatches(
                          icon: Symbols.search_off,
                          title: isIndo ? 'Tidak ada entri yang cocok' : 'No matching entries',
                          body: isIndo ? 'Tidak ada entri yang ditemukan dalam kategori ini.' : 'No entries found in this category.',
                          actionLabel: l10n?.allCategories ?? 'Show All',
                          onAction: () =>
                              setState(() => _selectedCategoryId = null),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context) + 88.0,
                        ),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _WorldEntryCard(
                            entry: entry,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => WorldEntryDetailScreen(
                                    entryId: entry.id,
                                  ),
                                ),
                              );
                            },
                            onEdit: () => _handleEditEntry(entry),
                            onDelete: () => _handleDeleteEntry(entry),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEditEntry(WorldEntryModel entry) async {
    await CreateWorldEntryDialog.show(
      context,
      widget.novelId,
      entryToEdit: entry,
    );
  }

  Future<void> _handleDeleteEntry(WorldEntryModel entry) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n?.delete ?? 'Delete'} ${entry.name}?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus "${entry.name}"? Anda dapat memulihkannya dari tempat sampah dalam 30 hari.'
              : 'Are you sure you want to delete "${entry.name}"? You can restore it from trash within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(worldActionsControllerProvider).deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Entri dunia "${entry.name}" dihapus.'
                  : 'World entry "${entry.name}" deleted.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _WorldEntryCard extends StatelessWidget {
  final WorldEntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorldEntryCard({
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return NvCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Icon(
              Symbols.language,
              color: c.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: AppTypography.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.verifiedCanon)
                      NvChip.status(
                        label: isIndo ? 'Kanon' : 'Canon',
                        statusKind: NvStatusTagKind.success,
                      ),
                  ],
                ),
                if (entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.subtitle!,
                    style: AppTypography.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.summary != null && entry.summary!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.summary!,
                    style: AppTypography.bodySm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, size: 20, color: c.textSecondary),
            tooltip: l10n?.moreOptions ?? 'Options',
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Symbols.edit, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.editDetails ?? 'Edit Lore Entry'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Symbols.delete, size: 18, color: c.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.delete ?? 'Delete', style: TextStyle(color: c.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
