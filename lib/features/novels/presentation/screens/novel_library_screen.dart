import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../search/application/search_providers.dart';
import '../../application/novel_providers.dart';
import '../../domain/models/novel_model.dart';
import 'edit_novel_dialog.dart';

class NovelLibraryScreen extends ConsumerStatefulWidget {
  const NovelLibraryScreen({super.key});

  @override
  ConsumerState<NovelLibraryScreen> createState() => _NovelLibraryScreenState();
}

class _NovelLibraryScreenState extends ConsumerState<NovelLibraryScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, NovelModel novel) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteNovelQuestion ?? 'Delete Novel?'),
        content: Text(
          l10n?.deleteNovelWarning ??
              'Are you sure you want to delete "${novel.title}"? All chapters and world data will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(novelActionsControllerProvider)
                  .deleteNovel(novel.id);
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final novelsAsync = ref.watch(novelListStreamProvider);

    return Scaffold(
      appBar: NvAppBar(
        title: _isSearching ? '' : l10n.navNovels,
        subtitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Symbols.close : Symbols.search,
              size: 22,
              color: c.textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: _isSearching ? l10n.close : l10n.search,
          ),
        ],
      ),
      floatingActionButton: novelsAsync.maybeWhen(
        data: (novels) => novels.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => context.push(Routes.createNovel),
                backgroundColor: c.primaryFill,
                foregroundColor: c.onPrimary,
                icon: const Icon(Symbols.add),
                label: Text(l10n.newNovel),
              )
            : null,
        orElse: () => null,
      ),
      body: novelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: NvErrorState(
              title: l10n.failedToLoadLibrary,
              message: l10n.failedToLoadLibraryDesc,
              onRetry: () => ref.invalidate(novelListStreamProvider),
            ),
          ),
        ),
        data: (novels) {
          if (novels.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.menu_book,
                  title: l10n.emptyLibraryTitle,
                  body: l10n.emptyLibraryBody,
                  actionLabel: l10n.emptyLibraryAction,
                  onAction: () => context.push(Routes.createNovel),
                ),
              ),
            );
          }

          final matchingNovelIds = _searchQuery.isEmpty
              ? const <String>{}
              : ref.watch(matchingNovelIdsProvider(_searchQuery)).valueOrNull ??
                  const <String>{};

          final filteredNovels = _searchQuery.isEmpty
              ? novels
              : novels.where((n) {
                  final lowerQ = _searchQuery.toLowerCase();
                  final titleMatch = n.title.toLowerCase().contains(lowerQ);
                  final genreMatch =
                      n.genre?.toLowerCase().contains(lowerQ) ?? false;
                  final subMatch =
                      n.subtitle?.toLowerCase().contains(lowerQ) ?? false;
                  final descMatch =
                      n.description?.toLowerCase().contains(lowerQ) ?? false;
                  final contentMatch = matchingNovelIds.contains(n.id);
                  return titleMatch ||
                      genreMatch ||
                      subMatch ||
                      descMatch ||
                      contentMatch;
                }).toList();

          if (filteredNovels.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.noMatches(
                  icon: Symbols.search_off,
                  title: l10n.noMatchingNovels,
                  body: '$_searchQuery',
                  actionLabel: l10n.clearSearch,
                  onAction: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context) + 88.0,
            ),
            itemCount: filteredNovels.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final novel = filteredNovels[index];
              return _NovelCard(
                novel: novel,
                onTap: () {
                  ref.read(novelActionsControllerProvider).openNovel(novel.id);
                  context.push(Routes.novelWorkspace(novel.id));
                },
                onEdit: () => EditNovelDialog.show(context, novel),
                onDelete: () => _confirmDelete(context, novel),
              );
            },
          );
        },
      ),
    );
  }
}

class _NovelCard extends StatelessWidget {
  final NovelModel novel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NovelCard({
    required this.novel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);

    return NvCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Icon / Cover Tile
              NovelCoverImage(
                coverPath: novel.coverPath,
                width: 48,
                height: 64,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      style: AppTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (novel.subtitle != null &&
                        novel.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        novel.subtitle!,
                        style: AppTypography.bodySm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Builder(
                      builder: (context) {
                        final genres = novel.genre != null &&
                                novel.genre!.trim().isNotEmpty
                            ? novel.genre!
                                .split(RegExp(r',\s*'))
                                .where((s) => s.isNotEmpty)
                                .toList()
                            : <String>[];
                        final statusKind = novel.status == NovelStatus.completed
                            ? NvStatusTagKind.success
                            : (novel.status == NovelStatus.onHold
                                ? NvStatusTagKind.warning
                                : NvStatusTagKind.neutral);

                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            NvChip.status(
                              label: novel.status.getLabel(l10n),
                              statusKind: statusKind,
                            ),
                            for (final g in genres.take(2))
                              NvChip.status(
                                label: g,
                                statusKind: NvStatusTagKind.neutral,
                              ),
                            if (genres.length > 2)
                              NvChip.status(
                                label: '+${genres.length - 2}',
                                statusKind: NvStatusTagKind.neutral,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Symbols.more_vert, size: 20, color: c.textSecondary),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Symbols.edit_note, size: 18, color: c.textPrimary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n?.editDetails ?? 'Edit Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Symbols.delete, size: 18, color: c.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n?.deleteNovel ?? 'Delete Novel',
                          style: TextStyle(color: c.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: c.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${novel.totalWordCount} ${l10n?.words ?? "words"} · ${novel.chapterCount} ${l10n?.chaptersCount ?? "chapters"}',
                style: AppTypography.bodySm,
              ),
              Icon(
                Symbols.chevron_right,
                size: 18,
                color: c.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
