import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../ai/presentation/screens/ai_index_screen.dart';
import '../../../characters/presentation/screens/character_list_screen.dart';
import '../../../characters/presentation/screens/create_character_dialog.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../manuscript/domain/models/manuscript_models.dart';
import '../../../outline/presentation/screens/create_event_dialog.dart';
import '../../../world/presentation/screens/create_world_entry_dialog.dart';
import '../../../world/presentation/screens/world_encyclopedia_screen.dart';
import '../../application/novel_providers.dart';
import '../../domain/models/novel_model.dart';
import 'edit_novel_dialog.dart';

class NovelWorkspaceScreen extends ConsumerStatefulWidget {
  final String novelId;

  const NovelWorkspaceScreen({
    super.key,
    required this.novelId,
  });

  @override
  ConsumerState<NovelWorkspaceScreen> createState() =>
      _NovelWorkspaceScreenState();
}

class _NovelWorkspaceScreenState extends ConsumerState<NovelWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.novelId.isNotEmpty) {
        if (ref.read(activeNovelIdProvider) != widget.novelId) {
          ref.read(activeNovelIdProvider.notifier).state = widget.novelId;
          ref.read(novelActionsControllerProvider).openNovel(widget.novelId);
        }
      }
    });
  }

  @override
  void didUpdateWidget(NovelWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novelId != widget.novelId && widget.novelId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (ref.read(activeNovelIdProvider) != widget.novelId) {
            ref.read(activeNovelIdProvider.notifier).state = widget.novelId;
            ref.read(novelActionsControllerProvider).openNovel(widget.novelId);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeleteNovel(
    BuildContext context,
    WidgetRef ref,
    NovelModel novel,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteNovelQuestion ?? 'Delete Novel?'),
        content: Text(
          l10n?.localeName == 'id'
              ? 'Apakah Anda yakin ingin menghapus "${novel.title}"? Semua bab dan data dunia akan dipindahkan ke tempat sampah.'
              : 'Are you sure you want to delete "${novel.title}"? All chapters and world data will be moved to trash.',
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
              if (context.mounted) {
                context.go(Routes.novels);
              }
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
    final l10n = AppLocalizations.of(context);

    if (widget.novelId.trim().isEmpty) {
      return Scaffold(
        appBar: NvAppBar(
          title: l10n?.novelWorkspace ?? 'Novel Workspace',
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.novels),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n?.localeName == 'id' ? 'ID novel tidak valid.' : 'Invalid novel ID.'),
              const SizedBox(height: AppSpacing.lg),
              NvButton(
                label: l10n?.backToLibrary ?? 'Back to Library',
                onPressed: () => context.go(Routes.novels),
              ),
            ],
          ),
        ),
      );
    }

    final novelAsync = ref.watch(novelDetailStreamProvider(widget.novelId));
    final cachedNovel = ref.read(activeNovelIdProvider) == widget.novelId
        ? ref.read(activeNovelProvider).valueOrNull
        : null;
    final novel = novelAsync.valueOrNull ?? cachedNovel;

    if (novel == null) {
      if (novelAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Symbols.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(Routes.novels);
                }
              },
              tooltip: 'Back to Library',
            ),
            title: const Text('Novel Workspace'),
            backgroundColor: c.surface,
            foregroundColor: c.textPrimary,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                backgroundColor: c.surfaceSecondary,
                color: c.primary,
                minHeight: 2,
              ),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (novelAsync.hasError) {
        return Scaffold(
          appBar: NvAppBar(
            title: 'Novel Workspace',
            showBack: true,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.novels),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
              child: NvErrorState(
                title: 'Failed to load novel',
                message:
                    'An error occurred while loading this novel: ${novelAsync.error.toString().replaceFirst(RegExp(r"^Exception:\s*"), "")}',
                onRetry: () =>
                    ref.invalidate(novelDetailStreamProvider(widget.novelId)),
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: NvAppBar(
          title: 'Not Found',
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.novels),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                    'This novel could not be found or has been removed.',),
                const SizedBox(height: AppSpacing.lg),
                NvButton(
                  label: 'Back to Library',
                  onPressed: () => context.go(Routes.novels),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.novels);
            }
          },
          tooltip: 'Back to Library',
        ),
        title: Row(
          children: [
            if (novel.coverPath != null && novel.coverPath!.isNotEmpty) ...[
              NovelCoverImage(
                coverPath: novel.coverPath,
                width: 26,
                height: 36,
                borderRadius: 4,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                novel.title,
                style: AppTypography.screenTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.auto_awesome_motion, size: 20),
            tooltip: l10n?.aiIndexScanner ?? 'AI Index Scanner',
            onPressed: () => AiIndexScreen.show(context, novelId: novel.id),
          ),
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, size: 20, color: c.textSecondary),
            onSelected: (val) {
              if (val == 'ai_index') {
                AiIndexScreen.show(context, novelId: novel.id);
              } else if (val == 'edit') {
                EditNovelDialog.show(context, novel);
              } else if (val == 'delete') {
                _confirmDeleteNovel(context, ref, novel);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'ai_index',
                child: Row(
                  children: [
                    Icon(
                      Symbols.auto_awesome_motion,
                      size: 18,
                      color: c.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.aiIndexScanner ?? 'AI Index Scanner'),
                  ],
                ),
              ),
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
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.primary,
          labelColor: c.primary,
          unselectedLabelColor: c.textSecondary,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          tabs: [
            Tab(
              icon: const Icon(Symbols.edit_document, size: 20),
              text: l10n?.manuscript ?? 'Manuscript',
            ),
            Tab(
              icon: const Icon(Symbols.group, size: 20),
              text: l10n?.characters ?? 'Characters',
            ),
            Tab(
              icon: const Icon(Symbols.public, size: 20),
              text: l10n?.world ?? 'World',
            ),
            Tab(
              icon: const Icon(Symbols.timeline, size: 20),
              text: l10n?.planning ?? 'Planning',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManuscriptTab(novel: novel),
          CharacterListScreen(novelId: novel.id, showAppBar: false),
          WorldEncyclopediaScreen(novelId: novel.id, showAppBar: false),
          _NovelPlanningTab(novelId: novel.id),
        ],
      ),
    );
  }
}

class _ManuscriptTab extends ConsumerWidget {
  final NovelModel novel;

  const _ManuscriptTab({required this.novel});

  Future<void> _handleCreateChapter(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final chapter = await ref
        .read(manuscriptActionsControllerProvider)
        .createChapter(novel.id);
    if (context.mounted) {
      unawaited(context.push(Routes.chapterEditor(novel.id, chapter.id)));
    }
  }

  void _confirmDeleteChapter(
    BuildContext context,
    WidgetRef ref,
    ChapterModel chapter,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter?'),
        content: Text(
          'Are you sure you want to delete "${chapter.displayTitle}"? It can be restored from trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(manuscriptActionsControllerProvider)
                  .deleteChapter(chapter.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameChapterDialog(
    BuildContext context,
    WidgetRef ref,
    ChapterModel chapter,
  ) {
    final controller = TextEditingController(text: chapter.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chapter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Chapter Title',
            hintText: 'e.g. The Awakening',
          ),
          onSubmitted: (val) async {
            if (val.trim().isNotEmpty) {
              Navigator.of(ctx).pop();
              final updated = ChapterModel(
                id: chapter.id,
                novelId: chapter.novelId,
                arcId: chapter.arcId,
                title: val.trim(),
                position: chapter.position,
                sequenceNumber: chapter.sequenceNumber,
                status: chapter.status,
                wordCount: chapter.wordCount,
                createdAt: chapter.createdAt,
                updatedAt: DateTime.now().toUtc(),
              );
              await ref
                  .read(manuscriptActionsControllerProvider)
                  .updateChapter(updated);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.of(ctx).pop();
                final updated = ChapterModel(
                  id: chapter.id,
                  novelId: chapter.novelId,
                  arcId: chapter.arcId,
                  title: newTitle,
                  position: chapter.position,
                  sequenceNumber: chapter.sequenceNumber,
                  status: chapter.status,
                  wordCount: chapter.wordCount,
                  createdAt: chapter.createdAt,
                  updatedAt: DateTime.now().toUtc(),
                );
                await ref
                    .read(manuscriptActionsControllerProvider)
                    .updateChapter(updated);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersStreamProvider(novel.id));
    final c = context.colors;

    final hasTarget =
        novel.novelWordTarget != null && novel.novelWordTarget! > 0;
    final progress = hasTarget
        ? (novel.totalWordCount / novel.novelWordTarget!).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _handleCreateChapter(context, ref),
        backgroundColor: c.primaryFill,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.add),
        label: const Text('Add Chapter'),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: NvErrorState(
            title: 'Failed to load chapters',
            message: 'An error occurred while loading chapter hierarchy.',
            onRetry: () => ref.invalidate(chaptersStreamProvider(novel.id)),
          ),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.menu_book,
                  title: 'No chapters yet',
                  body:
                      'Start drafting Chapter 1 or outline your manuscript structure.',
                  actionLabel: 'Create Chapter 1',
                  onAction: () => _handleCreateChapter(context, ref),
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context),
              AppSpacing.screenMargin(context) + 88.0,
            ),
            children: [
              // Novel Progress Summary Card
              NvCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${novel.totalWordCount} words',
                          style: AppTypography.screenTitle,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Builder(
                            builder: (context) {
                              final genres = novel.genre != null &&
                                      novel.genre!.trim().isNotEmpty
                                  ? novel.genre!
                                      .split(RegExp(r',\s*'))
                                      .where((s) => s.isNotEmpty)
                                      .toList()
                                  : <String>[];
                              final statusKind =
                                  novel.status == NovelStatus.completed
                                      ? NvStatusTagKind.success
                                      : (novel.status == NovelStatus.onHold
                                          ? NvStatusTagKind.warning
                                          : NvStatusTagKind.neutral);

                              return Wrap(
                                alignment: WrapAlignment.end,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  NvChip.status(
                                    label: novel.status.label,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hasTarget) ...[
                      NvProgressBar(value: progress),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Target: ${novel.novelWordTarget} words (${(progress * 100).toInt()}%)',
                        style: AppTypography.bodySm,
                      ),
                    ] else ...[
                      Text(
                        '${chapters.length} ${chapters.length == 1 ? "chapter" : "chapters"} drafted',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Chapters (${chapters.length})',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.sm),

              ...chapters.map(
                (chapter) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: NvCard(
                    onTap: () => context.push(
                      Routes.chapterEditor(novel.id, chapter.id),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.inset),
                          ),
                          child: Center(
                            child: Text(
                              '${chapter.sequenceNumber}',
                              style: AppTypography.labelMd
                                  .copyWith(color: c.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.displayTitle,
                                style: AppTypography.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${chapter.wordCount} words · ${chapter.status.label}',
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
                            if (val == 'rename') {
                              _showRenameChapterDialog(context, ref, chapter);
                            } else if (val == 'delete') {
                              _confirmDeleteChapter(context, ref, chapter);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(
                                    Symbols.edit_note,
                                    size: 18,
                                    color: c.textPrimary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Text('Rename / Edit Title'),
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
                                    'Delete Chapter',
                                    style: TextStyle(color: c.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Symbols.chevron_right,
                          size: 20,
                          color: c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NovelPlanningTab extends StatelessWidget {
  final String novelId;

  const _NovelPlanningTab({required this.novelId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),
              NvCard(
                onTap: () => CreateEventDialog.show(context, novelId),
                child: Row(
                  children: [
                    const Icon(Symbols.timeline, size: 28),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Timeline Event',
                            style: AppTypography.cardTitle,
                          ),
                          Text(
                            'Map chronological milestones and plot points',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Symbols.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              NvCard(
                onTap: () => CreateWorldEntryDialog.show(context, novelId),
                child: Row(
                  children: [
                    const Icon(Symbols.public, size: 28),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add World Lore',
                            style: AppTypography.cardTitle,
                          ),
                          Text(
                            'Catalog factions, locations, and magic systems',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Symbols.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              NvCard(
                onTap: () => CreateCharacterDialog.show(context, novelId),
                child: Row(
                  children: [
                    const Icon(Symbols.person_add, size: 28),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Character',
                            style: AppTypography.cardTitle,
                          ),
                          Text(
                            'Introduce heroes, villains, and allies',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Symbols.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
