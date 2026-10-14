import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../characters/presentation/screens/character_detail_screen.dart';
import '../../../characters/presentation/screens/create_character_dialog.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../../novels/presentation/screens/edit_novel_dialog.dart';
import '../../../outline/presentation/screens/create_event_dialog.dart';
import '../../../search/application/search_providers.dart';
import '../../../search/domain/models/search_result_item.dart';
import '../../../world/presentation/screens/create_world_entry_dialog.dart';
import '../../../world/presentation/screens/world_entry_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  SearchResultType _selectedFilter = SearchResultType.all;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final activeNovelAsync = ref.watch(activeNovelProvider);
    final novelsAsync = ref.watch(novelListStreamProvider);
    final searchResultsAsync = _searchQuery.isNotEmpty
        ? ref.watch(globalSearchResultsProvider(_searchQuery))
        : null;

    return Scaffold(
      appBar: NvAppBar(
        title: l10n.navHome,
        actions: [
          IconButton(
            icon: Icon(Symbols.search, size: 22, color: c.textPrimary),
            onPressed: () {
              _searchFocusNode.requestFocus();
            },
            tooltip: l10n.search,
          ),
          IconButton(
            icon: Icon(Symbols.settings, size: 22, color: c.textPrimary),
            onPressed: () => context.go(Routes.more),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Global Search Bar directly above the statistics cards
            Container(
              decoration: BoxDecoration(
                color: c.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: c.outlineVariant),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: AppTypography.body.copyWith(color: c.textSecondary),
                  prefixIcon: Icon(Symbols.search, color: c.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Symbols.close, color: c.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedFilter = SearchResultType.all;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Live Search Results (if searching)
            if (_searchQuery.isNotEmpty && searchResultsAsync != null) ...[
              searchResultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: NvCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.failedToLoadSearch,
                        style: AppTypography.bodySm.copyWith(color: c.error),
                      ),
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: NvCard(
                        child: NvEmptyState.noMatches(
                          icon: Symbols.search_off,
                          title: l10n.noResultsFound,
                          body: l10n.localeName == 'id'
                              ? 'Tidak ada novel, bab, lore, atau karakter yang cocok dengan "$_searchQuery".'
                              : 'No novels, chapters, lore, or characters match "$_searchQuery".',
                          actionLabel: l10n.clearSearch,
                          onAction: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedFilter = SearchResultType.all;
                            });
                          },
                        ),
                      ),
                    );
                  }

                  final novelCount =
                      items.where((i) => i.type == SearchResultType.novel).length;
                  final chapterCount =
                      items.where((i) => i.type == SearchResultType.chapter).length;
                  final characterCount =
                      items.where((i) => i.type == SearchResultType.character).length;
                  final loreCount =
                      items.where((i) => i.type == SearchResultType.lore).length;
                  final eventCount =
                      items.where((i) => i.type == SearchResultType.event).length;
                  final sceneCount =
                      items.where((i) => i.type == SearchResultType.scene).length;

                  final filteredItems = _selectedFilter == SearchResultType.all
                      ? items
                      : items.where((i) => i.type == _selectedFilter).toList();

                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & count
                      Row(
                        children: [
                          Text(
                            '${l10n.searchResults} (${filteredItems.length})',
                            style: AppTypography.sectionTitle,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = SearchResultType.all;
                              });
                            },
                            child: Text(l10n.clear),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: '${l10n.filterAll} (${items.length})',
                              type: SearchResultType.all,
                              isDark: isDark,
                              c: c,
                            ),
                            if (novelCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterNovels} ($novelCount)',
                                type: SearchResultType.novel,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                            if (chapterCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterChapters} ($chapterCount)',
                                type: SearchResultType.chapter,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                            if (characterCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterCharacters} ($characterCount)',
                                type: SearchResultType.character,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                            if (loreCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterLore} ($loreCount)',
                                type: SearchResultType.lore,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                            if (eventCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterTimeline} ($eventCount)',
                                type: SearchResultType.event,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                            if (sceneCount > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip(
                                label: '${l10n.filterScenes} ($sceneCount)',
                                type: SearchResultType.scene,
                                isDark: isDark,
                                c: c,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Filtered results list
                      if (filteredItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            '${l10n.noResultsFound} (${_selectedFilter.getLabel(l10n)}).',
                            style: AppTypography.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...filteredItems.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _SearchResultCard(
                              item: item,
                              onTap: () => _handleResultTap(item),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
              ),
            ],
            // Active novel card (clean empty state by default)
            activeNovelAsync.maybeWhen(
              data: (activeNovel) {
                if (activeNovel == null) {
                  return NvCard(
                    child: NvEmptyState.nothingYet(
                      icon: Symbols.menu_book,
                      title: l10n.emptyActiveNovelTitle,
                      body: l10n.emptyActiveNovelBody,
                      actionLabel: l10n.emptyActiveNovelAction,
                      onAction: () => context.push(Routes.createNovel),
                    ),
                  );
                }
                return _ActiveNovelResumeCard(novel: activeNovel);
              },
              orElse: () => NvCard(
                child: NvEmptyState.nothingYet(
                  icon: Symbols.menu_book,
                  title: l10n.emptyActiveNovelTitle,
                  body: l10n.emptyActiveNovelBody,
                  actionLabel: l10n.emptyActiveNovelAction,
                  onAction: () => context.push(Routes.createNovel),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick actions section
            Text(
              l10n.quickActions,
              style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            NvCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _QuickActionTile(
                    icon: Symbols.article,
                    label: l10n.newChapter,
                    helperText: activeNovelAsync.valueOrNull != null
                        ? activeNovelAsync.valueOrNull!.title
                        : l10n.openNovelFirst,
                    onTap: () {
                      final novel = activeNovelAsync.valueOrNull;
                      if (novel != null) {
                        ref
                            .read(novelActionsControllerProvider)
                            .openNovel(novel.id);
                        context.push(Routes.novelWorkspace(novel.id));
                      } else {
                        context.go(Routes.novels);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _QuickActionTile(
                    icon: Symbols.person,
                    label: l10n.newCharacter,
                    helperText: activeNovelAsync.valueOrNull != null
                        ? activeNovelAsync.valueOrNull!.title
                        : l10n.openNovelFirst,
                    onTap: () {
                      final novel = activeNovelAsync.valueOrNull;
                      if (novel != null) {
                        CreateCharacterDialog.show(context, novel.id);
                      } else {
                        context.go(Routes.novels);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _QuickActionTile(
                    icon: Symbols.public,
                    label: l10n.newWorldEntry,
                    helperText: activeNovelAsync.valueOrNull != null
                        ? activeNovelAsync.valueOrNull!.title
                        : l10n.openNovelFirst,
                    onTap: () {
                      final novel = activeNovelAsync.valueOrNull;
                      if (novel != null) {
                        CreateWorldEntryDialog.show(context, novel.id);
                      } else {
                        context.go(Routes.novels);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _QuickActionTile(
                    icon: Symbols.timeline,
                    label: l10n.newTimelineEvent,
                    helperText: activeNovelAsync.valueOrNull != null
                        ? activeNovelAsync.valueOrNull!.title
                        : l10n.openNovelFirst,
                    onTap: () {
                      final novel = activeNovelAsync.valueOrNull;
                      if (novel != null) {
                        CreateEventDialog.show(context, novel.id);
                      } else {
                        context.go(Routes.novels);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent novels section
            Text(
              l10n.recentNovels,
              style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            novelsAsync.maybeWhen(
              data: (novels) {
                if (novels.isEmpty) {
                  return NvEmptyState.inline(
                    title: l10n.emptyRecentNovelsTitle,
                    body: l10n.emptyRecentNovelsBody,
                    actionLabel: l10n.emptyRecentNovelsAction,
                    onAction: () => context.go(Routes.novels),
                  );
                }
                return Column(
                  children: novels.take(3).map((novel) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: NvCard(
                        onTap: () {
                          ref
                              .read(novelActionsControllerProvider)
                              .openNovel(novel.id);
                          context.push(Routes.novelWorkspace(novel.id));
                        },
                        child: Row(
                          children: [
                            NovelCoverImage(
                              coverPath: novel.coverPath,
                              width: 36,
                              height: 48,
                              iconSize: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
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
                                  Text(
                                    '${novel.totalWordCount} ${l10n.words} · ${novel.chapterCount} ${l10n.chaptersCount}',
                                    style: AppTypography.bodySm,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Symbols.more_vert,
                                size: 20,
                                color: c.textSecondary,
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  EditNovelDialog.show(context, novel);
                                } else if (val == 'delete') {
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.deleteNovelQuestion),
                                      content: Text(
                                        l10n.deleteNovelWarning,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(ctx).pop();
                                            await ref
                                                .read(novelActionsControllerProvider)
                                                .deleteNovel(novel.id);
                                          },
                                          child: Text(
                                            l10n.delete,
                                            style: TextStyle(color: c.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Symbols.edit_note,
                                        size: 18,
                                        color: c.textPrimary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(l10n.editDetails),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Symbols.delete,
                                        size: 18,
                                        color: c.error,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        l10n.deleteNovel,
                                        style: TextStyle(color: c.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              orElse: () => NvEmptyState.inline(
                title: l10n.emptyRecentNovelsTitle,
                body: l10n.emptyRecentNovelsBody,
                actionLabel: l10n.emptyRecentNovelsAction,
                onAction: () => context.go(Routes.novels),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResultTap(SearchResultItem item) {
    final novelId = item.novelId ??
        (item.type == SearchResultType.novel ? item.id : null);
    if (novelId != null) {
      ref.read(activeNovelIdProvider.notifier).state = novelId;
    }

    switch (item.type) {
      case SearchResultType.novel:
        ref.read(novelActionsControllerProvider).openNovel(item.id);
        context.push(Routes.novelWorkspace(item.id));
        break;
      case SearchResultType.chapter:
        if (novelId != null) {
          context.push(Routes.chapterEditor(novelId, item.id));
        }
        break;
      case SearchResultType.character:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => CharacterDetailScreen(characterId: item.id),
          ),
        );
        break;
      case SearchResultType.lore:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => WorldEntryDetailScreen(entryId: item.id),
          ),
        );
        break;
      case SearchResultType.event:
      case SearchResultType.scene:
        context.go(Routes.planning);
        break;
      case SearchResultType.all:
        break;
    }
  }

  Widget _buildFilterChip({
    required String label,
    required SearchResultType type,
    required bool isDark,
    required AppColors c,
  }) {
    final isSelected = _selectedFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? type : SearchResultType.all;
        });
      },
      selectedColor: c.primarySoft,
      backgroundColor: c.surfaceSecondary,
      labelStyle: TextStyle(
        color: isSelected ? c.primary : c.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _ActiveNovelResumeCard extends ConsumerWidget {
  final NovelModel novel;

  const _ActiveNovelResumeCard({required this.novel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final hasTarget =
        novel.novelWordTarget != null && novel.novelWordTarget! > 0;
    final progress = hasTarget
        ? (novel.totalWordCount / novel.novelWordTarget!).clamp(0.0, 1.0)
        : 0.0;

    return NvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.currentProject ?? 'Current Project',
                style: AppTypography.labelSm.copyWith(color: c.primary),
              ),
              NvChip.status(
                label: novel.status.getLabel(l10n),
                statusKind: NvStatusTagKind.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NovelCoverImage(
                coverPath: novel.coverPath,
                width: 44,
                height: 60,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      style: AppTypography.screenTitle,
                    ),
                    if (novel.subtitle != null && novel.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(novel.subtitle!, style: AppTypography.bodySm),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasTarget) ...[
            NvProgressBar(value: progress),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${novel.totalWordCount} / ${novel.novelWordTarget} ${l10n?.words ?? "words"}',
                  style: AppTypography.bodySm,
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.labelMd,
                ),
              ],
            ),
          ] else ...[
            Text(
              '${novel.totalWordCount} ${l10n?.words ?? "words"} · ${novel.chapterCount} ${l10n?.chaptersCount ?? "chapters"}',
              style: AppTypography.bodySm,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          NvButton(
            label: l10n?.openWorkspace ?? 'Open Workspace',
            variant: NvButtonVariant.primary,
            icon: Symbols.arrow_forward,
            onPressed: () {
              ref.read(novelActionsControllerProvider).openNovel(novel.id);
              context.push(Routes.novelWorkspace(novel.id));
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.helperText,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

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
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        AppTypography.cardTitle.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    helperText,
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

class _SearchResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.item,
    required this.onTap,
  });

  Color _iconColor(SearchResultType type, AppColors c) {
    switch (type) {
      case SearchResultType.novel:
        return c.primary;
      case SearchResultType.chapter:
        return const Color(0xFF0D9488);
      case SearchResultType.character:
        return const Color(0xFF9333EA);
      case SearchResultType.lore:
        return const Color(0xFFD97706);
      case SearchResultType.event:
        return const Color(0xFF4F46E5);
      case SearchResultType.scene:
        return const Color(0xFF16A34A);
      case SearchResultType.all:
        return c.primary;
    }
  }

  Color _badgeTextColor(SearchResultType type, AppColors c, bool isDark) {
    if (isDark) {
      switch (type) {
        case SearchResultType.novel:
          return c.primary;
        case SearchResultType.chapter:
          return const Color(0xFF2DD4BF);
        case SearchResultType.character:
          return const Color(0xFFD8B4FE);
        case SearchResultType.lore:
          return const Color(0xFFFCD34D);
        case SearchResultType.event:
          return const Color(0xFFA5B4FC);
        case SearchResultType.scene:
          return const Color(0xFF86EFAC);
        case SearchResultType.all:
          return c.textPrimary;
      }
    }
    switch (type) {
      case SearchResultType.novel:
        return c.primary;
      case SearchResultType.chapter:
        return const Color(0xFF0F766E);
      case SearchResultType.character:
        return const Color(0xFF7E22CE);
      case SearchResultType.lore:
        return const Color(0xFFB45309);
      case SearchResultType.event:
        return const Color(0xFF4338CA);
      case SearchResultType.scene:
        return const Color(0xFF15803D);
      case SearchResultType.all:
        return c.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final iconColor = _iconColor(item.type, c);
    final badgeTextColor = _badgeTextColor(item.type, c, isDark);
    final badgeBgColor = badgeTextColor.withValues(alpha: isDark ? 0.16 : 0.12);

    return NvCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Icon(item.icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.type.getSingularLabel(l10n).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    if (item.tag != null && item.tag!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '· ${item.tag!}',
                        style: AppTypography.labelSm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.title,
                  style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style:
                        AppTypography.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
                if (item.snippet != null && item.snippet!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.cover),
                    ),
                    child: Text(
                      item.snippet!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: c.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Symbols.chevron_right, size: 20, color: c.textSecondary),
        ],
      ),
    );
  }
}

