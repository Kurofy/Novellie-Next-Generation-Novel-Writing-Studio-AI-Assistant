import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final novelsAsync = ref.watch(novelListStreamProvider);

    return Scaffold(
      appBar: NvAppBar(
        title: l10n?.statisticsAndGoals ?? 'Statistics & Goals',
      ),
      body: novelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: NvErrorState(
            title: l10n?.localeName == 'id'
                ? 'Gagal memuat statistik'
                : 'Failed to load statistics',
            message: l10n?.localeName == 'id'
                ? 'Terjadi kesalahan saat memuat data penulisan.'
                : 'An error occurred while loading writing data.',
            onRetry: () => ref.invalidate(novelListStreamProvider),
          ),
        ),
        data: (novels) {
          if (novels.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.query_stats,
                  title: l10n?.localeName == 'id'
                      ? 'Belum Ada Statistik Penulisan'
                      : 'No Writing Statistics Yet',
                  body: l10n?.localeName == 'id'
                      ? 'Buat novel dan mulailah menulis bab untuk melacak kata, laju, dan target.'
                      : 'Create a novel and start drafting chapters to track words, pacing, and goals.',
                  actionLabel: l10n?.createFirstNovel ?? 'Create First Novel',
                  onAction: () => Navigator.of(context).pop(),
                ),
              ),
            );
          }

          final totalWords =
              novels.fold<int>(0, (sum, n) => sum + n.totalWordCount);
          final totalChapters =
              novels.fold<int>(0, (sum, n) => sum + n.chapterCount);
          final primaryNovel = novels.first;
          final target = primaryNovel.novelWordTarget ?? 50000;
          final progress =
              (primaryNovel.totalWordCount / target).clamp(0.0, 1.0);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin(context),
              vertical: AppSpacing.xl,
            ),
            children: [
              // Goal Card
              Text(l10n?.primaryTarget ?? 'Primary Target', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              NvCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            primaryNovel.title,
                            style: AppTypography.cardTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        NvChip.status(
                          label: '${(progress * 100).toInt()}% ${l10n?.localeName == 'id' ? 'Selesai' : 'Done'}',
                          statusKind: progress >= 1.0
                              ? NvStatusTagKind.success
                              : NvStatusTagKind.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NvProgressBar(value: progress),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${primaryNovel.totalWordCount} ${l10n?.wordsWritten ?? 'words written'}',
                          style: AppTypography.bodySm,
                        ),
                        Text(
                          '${l10n?.localeName == 'id' ? 'Target' : 'Goal'}: $target ${l10n?.words ?? 'words'}',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Macro Stats Grid
              Text(l10n?.writingTotals ?? 'Writing Totals', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Symbols.menu_book, color: c.primary, size: 24),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '$totalWords',
                            style: AppTypography.headlineHeroMobile.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(l10n?.totalWords ?? 'Total Words', style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: NvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Symbols.article, color: c.primary, size: 24),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '$totalChapters',
                            style: AppTypography.headlineHeroMobile.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(l10n?.chaptersDrafted ?? 'Chapters Drafted', style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.library_books,
                            color: c.primary,
                            size: 24,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${novels.length}',
                            style: AppTypography.headlineHeroMobile.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(l10n?.novelsInLibrary ?? 'Novels in Library', style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: NvCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.speed,
                            color: c.primary,
                            size: 24,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            totalChapters > 0
                                ? '${(totalWords / totalChapters).toInt()}'
                                : '0',
                            style: AppTypography.headlineHeroMobile.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            l10n?.avgWordsPerChapter ?? 'Avg Words / Chapter',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Breakdown by Novel
              Text(l10n?.novelsBreakdown ?? 'Novels Breakdown', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              ...novels.map((novel) {
                final nTarget = novel.novelWordTarget ?? 50000;
                final nProgress =
                    (novel.totalWordCount / nTarget).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: NvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(novel.title, style: AppTypography.cardTitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${novel.chapterCount} ${l10n?.chaptersCount ?? 'chapters'} • ${novel.totalWordCount} ${l10n?.words ?? 'words'}',
                          style: AppTypography.bodySm,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        NvProgressBar(value: nProgress),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
