import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../application/planning_providers.dart';
import '../../domain/models/planning_models.dart';
import 'create_event_dialog.dart';
import 'create_scene_dialog.dart';

class PlanningHubScreen extends ConsumerStatefulWidget {
  const PlanningHubScreen({super.key});

  @override
  ConsumerState<PlanningHubScreen> createState() => _PlanningHubScreenState();
}

class _PlanningHubScreenState extends ConsumerState<PlanningHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNovelChooser(
    BuildContext context,
    List<NovelModel> novels,
    NovelModel? currentActiveNovel,
  ) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Symbols.auto_stories, color: c.primary, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.chooseNovel,
                              style: AppTypography.cardTitle,
                            ),
                            Text(
                              l10n.chooseNovelDesc,
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.close, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),

                // Create New Novel Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Symbols.add,
                      color: c.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    l10n.localeName == 'id' ? 'Buat Novel Baru' : 'Create New Novel',
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.identityAndDetailsDesc,
                    style: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Icon(
                    Symbols.chevron_right,
                    color: c.outlineVariant,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(Routes.createNovel);
                  },
                ),

                const Divider(height: 1),

                // Novels List
                Flexible(
                  child: novels.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              'No novels created yet.\nCreate your first novel to start planning.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: novels.length,
                          itemBuilder: (ctx, idx) {
                            final novel = novels[idx];
                            final isSelected =
                                novel.id == currentActiveNovel?.id;

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? c.primarySoft
                                      : c.surfaceSecondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Symbols.menu_book,
                                  color:
                                      isSelected ? c.primary : c.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                novel.title,
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (novel.genre != null &&
                                      novel.genre!.isNotEmpty)
                                    novel.genre!,
                                  novel.status.getLabel(l10n),
                                  '${novel.chapterCount} ${l10n.chaptersCount}',
                                ].join(' • '),
                                style: AppTypography.bodySm.copyWith(
                                  color: c.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: isSelected
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.primarySoft,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.pill,),
                                        border: Border.all(
                                          color:
                                              c.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Symbols.check,
                                            size: 14,
                                            color: c.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.active,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: c.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                ref.read(activeNovelIdProvider.notifier).state =
                                    novel.id;
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeNovelAsync = ref.watch(activeNovelProvider);
    final novelsAsync = ref.watch(novelListStreamProvider);
    final novels = novelsAsync.valueOrNull ?? <NovelModel>[];
    final c = context.colors;

    return activeNovelAsync.when(
      loading: () => Scaffold(
        appBar: NvAppBar(title: l10n.navPlanning),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: NvAppBar(title: l10n.navPlanning),
        body: Center(
          child: NvErrorState(
            title: 'Failed to load novel',
            message: 'An error occurred while loading active novel.',
            onRetry: () => ref.invalidate(activeNovelProvider),
          ),
        ),
      ),
      data: (NovelModel? activeNovel) {
        if (activeNovel == null) {
          if (novels.isNotEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.planningHub),
                backgroundColor: c.surface,
                foregroundColor: c.textPrimary,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Symbols.swap_horiz, size: 22),
                    tooltip: l10n.chooseNovel,
                    onPressed: () => _openNovelChooser(context, novels, null),
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                  child: NvEmptyState(
                    icon: Symbols.schema,
                    title: l10n.selectNovelToPlan,
                    body: l10n.selectNovelToPlanDesc,
                    actionLabel: l10n.chooseNovel,
                    onAction: () => _openNovelChooser(context, novels, null),
                  ),
                ),
              ),
            );
          }

          // No novel created yet
          return Scaffold(
            appBar: NvAppBar(title: l10n.navPlanning),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.schema,
                  title: l10n.emptyOutlineTitle,
                  body: l10n.emptyOutlineBody,
                  actionLabel: l10n.emptyOutlineAction,
                  onAction: () => context.push(Routes.createNovel),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: novels.isNotEmpty
                  ? () => _openNovelChooser(context, novels, activeNovel)
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child:
                          Icon(Symbols.menu_book, size: 18, color: c.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  activeNovel.title,
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (novels.length > 1) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Symbols.arrow_drop_down,
                                  size: 20,
                                  color: c.primary,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            l10n.planningHub,
                            style: AppTypography.labelSm.copyWith(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: c.surface,
            foregroundColor: c.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Symbols.swap_horiz, size: 22),
                tooltip: l10n.chooseNovel,
                onPressed: () =>
                    _openNovelChooser(context, novels, activeNovel),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: c.primary,
              labelColor: c.primary,
              unselectedLabelColor: c.textSecondary,
              tabs: [
                Tab(
                  icon: const Icon(Symbols.timeline, size: 20),
                  text: l10n.timeline,
                ),
                Tab(
                  icon: const Icon(Symbols.view_kanban, size: 20),
                  text: l10n.sceneCards,
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _TimelineTabView(novelId: activeNovel.id),
              _SceneCardsTabView(novelId: activeNovel.id),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTabView extends ConsumerWidget {
  final String novelId;

  const _TimelineTabView({required this.novelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(timelineEventsStreamProvider(novelId));
    final c = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateEventDialog.show(context, novelId),
        backgroundColor: c.primaryFill,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.add),
        label: Text(l10n?.newEvent ?? 'New Event'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: NvErrorState(
            title: l10n?.failedToLoadEvents ?? 'Failed to load timeline events',
            message: 'An error occurred while loading timeline events.',
            onRetry: () =>
                ref.invalidate(timelineEventsStreamProvider(novelId)),
          ),
        ),
        data: (List<TimelineEventModel> events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.timeline,
                  title: l10n?.noEventsYet ?? 'No timeline events yet',
                  body: l10n?.noEventsDesc ??
                      'Map chronological moments, historical lore, and plot turning points.',
                  actionLabel: l10n?.newEvent ?? 'Create Event',
                  onAction: () => CreateEventDialog.show(context, novelId),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context) + 88.0,
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NvTimelineNode(
                  isFirst: index == 0,
                  isLast: isLast,
                  state: NvTimelineNodeState.current,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () => CreateEventDialog.show(
                        context,
                        novelId,
                        eventToEdit: event,
                      ),
                      child: NvCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: AppTypography.cardTitle,
                                      ),
                                      if (event.dateText != null) ...[
                                        const SizedBox(height: 4),
                                        NvChip.status(
                                          label: event.dateText!,
                                          statusKind: NvStatusTagKind.neutral,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Symbols.more_vert,
                                    size: 18,
                                    color: c.textSecondary,
                                  ),
                                  tooltip: 'Event Options',
                                  padding: EdgeInsets.zero,
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      CreateEventDialog.show(
                                        context,
                                        novelId,
                                        eventToEdit: event,
                                      );
                                    } else if (val == 'delete') {
                                      _confirmDeleteEvent(context, ref, event);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Symbols.edit, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l10n?.editDetails ?? 'Edit Details'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Symbols.delete,
                                              size: 18, color: c.error,),
                                          const SizedBox(width: 8),
                                          Text(l10n?.delete ?? 'Delete',
                                              style:
                                                  TextStyle(color: c.error),),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (event.description != null &&
                                event.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                event.description!,
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteEvent(
    BuildContext context,
    WidgetRef ref,
    TimelineEventModel event,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.delete ?? 'Delete Timeline Event?'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(planningActionsControllerProvider)
                  .deleteEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Timeline event deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _SceneCardsTabView extends ConsumerWidget {
  final String novelId;

  const _SceneCardsTabView({required this.novelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(
      sceneCardsStreamProvider((novelId: novelId, chapterId: null)),
    );
    final c = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateSceneDialog.show(context, novelId),
        backgroundColor: c.primaryFill,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.add),
        label: Text(l10n?.newScene ?? 'New Scene'),
      ),
      body: scenesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: NvErrorState(
            title: l10n?.failedToLoadScenes ?? 'Failed to load scene cards',
            message: 'An error occurred while loading scene cards.',
            onRetry: () => ref.invalidate(
              sceneCardsStreamProvider((novelId: novelId, chapterId: null)),
            ),
          ),
        ),
        data: (List<SceneCardModel> scenes) {
          if (scenes.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.view_kanban,
                  title: l10n?.noScenesYet ?? 'No scene cards yet',
                  body: l10n?.noScenesDesc ??
                      'Plan key dramatic questions, character agendas, and value shifts.',
                  actionLabel: l10n?.newScene ?? 'Create Scene Card',
                  onAction: () => CreateSceneDialog.show(context, novelId),
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
            itemCount: scenes.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final scene = scenes[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => CreateSceneDialog.show(
                    context,
                    novelId,
                    sceneToEdit: scene,
                  ),
                  child: NvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scene.title,
                                    style: AppTypography.cardTitle,
                                  ),
                                  const SizedBox(height: 4),
                                  NvChip.status(
                                    label: scene.status.toUpperCase(),
                                    statusKind: NvStatusTagKind.neutral,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Symbols.more_vert,
                                size: 18,
                                color: c.textSecondary,
                              ),
                              tooltip: l10n?.moreOptions ?? 'Scene Options',
                              padding: EdgeInsets.zero,
                              onSelected: (val) {
                                if (val == 'edit') {
                                  CreateSceneDialog.show(
                                    context,
                                    novelId,
                                    sceneToEdit: scene,
                                  );
                                } else if (val == 'delete') {
                                  _confirmDeleteScene(context, ref, scene);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Symbols.edit, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n?.editDetails ?? 'Edit Scene Card'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Symbols.delete,
                                          size: 18, color: Colors.red,),
                                      const SizedBox(width: 8),
                                      Text(l10n?.delete ?? 'Delete Scene Card',
                                          style: const TextStyle(color: Colors.red),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (scene.dramaticQuestion != null &&
                            scene.dramaticQuestion!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Dramatic Question: ${scene.dramaticQuestion!}',
                            style: AppTypography.bodySm
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                        if (scene.purpose != null &&
                            scene.purpose!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Purpose: ${scene.purpose!}',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteScene(
    BuildContext context,
    WidgetRef ref,
    SceneCardModel scene,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n?.delete ?? 'Delete'} ${scene.title}?'),
        content: Text(
          'Are you sure you want to delete "${scene.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(planningActionsControllerProvider)
                  .deleteScene(scene.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scene card deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}
