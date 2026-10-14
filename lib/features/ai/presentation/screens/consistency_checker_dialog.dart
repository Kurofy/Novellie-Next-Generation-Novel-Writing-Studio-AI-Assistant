import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../application/consistency_providers.dart';
import '../../domain/models/consistency_models.dart';

class ConsistencyCheckerDialog extends ConsumerStatefulWidget {
  final String novelId;

  const ConsistencyCheckerDialog({
    super.key,
    required this.novelId,
  });

  static Future<void> show(BuildContext context, String novelId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConsistencyCheckerDialog(novelId: novelId),
    );
  }

  @override
  ConsumerState<ConsistencyCheckerDialog> createState() =>
      _ConsistencyCheckerDialogState();
}

class _ConsistencyCheckerDialogState
    extends ConsumerState<ConsistencyCheckerDialog> {
  ConsistencyCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final scope = ref.watch(consistencyScopeProvider);
    final selectedChapters =
        ref.watch(selectedConsistencyChapterIdsProvider);
    final isAnalyzing = ref.watch(isAnalyzingConsistencyProvider);
    final report = ref.watch(consistencyReportProvider);
    final chaptersAsync = ref.watch(chaptersStreamProvider(widget.novelId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: Column(
        children: [
          // Header with Collision-safe Flex Alignment
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Symbols.fact_check, color: c.primary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isIndo ? 'Pemeriksa Konsistensi AI' : 'AI Consistency Checker',
                          style: AppTypography.screenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: isIndo ? 'Tutup' : 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scope Selector Section
                  Text(isIndo ? 'Cakupan Analisis' : 'Analysis Scope',
                      style: AppTypography.sectionTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isIndo
                        ? 'Pilih bab mana yang akan diperiksa terhadap acuan lore, garis waktu, dan karakter.'
                        : 'Select which chapters to inspect against the lore bible, timeline, and characters.',
                    style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(isIndo ? 'Semua Bab' : 'All Chapters'),
                        selected: scope == ConsistencyScope.allChapters,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(consistencyControllerProvider)
                                .setScope(ConsistencyScope.allChapters);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: Text(isIndo ? 'Pilih Bab Tertentu' : 'Select Specific Chapters'),
                        selected: scope == ConsistencyScope.selectedChapters,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(consistencyControllerProvider)
                                .setScope(ConsistencyScope.selectedChapters);
                          }
                        },
                      ),
                    ],
                  ),

                  // If specific chapters chosen, display selection list
                  if (scope == ConsistencyScope.selectedChapters) ...[
                    const SizedBox(height: AppSpacing.md),
                    chaptersAsync.maybeWhen(
                      data: (chapters) {
                        if (chapters.isEmpty) {
                          return Text(
                            isIndo ? 'Belum ada bab yang dibuat.' : 'No chapters created yet.',
                            style: AppTypography.bodySm,
                          );
                        }
                        return Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: chapters.map((ch) {
                            final isSel = selectedChapters.contains(ch.id);
                            return FilterChip(
                              label: Text(ch.displayTitle),
                              selected: isSel,
                              onSelected: (_) {
                                ref
                                    .read(consistencyControllerProvider)
                                    .toggleChapter(ch.id);
                              },
                            );
                          }).toList(),
                        );
                      },
                      orElse: () => const CircularProgressIndicator(),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Launch Button
                  SizedBox(
                    width: double.infinity,
                    child: NvButton(
                      label: isAnalyzing
                          ? (isIndo ? 'Menganalisis Konsistensi...' : 'Analyzing Consistency...')
                          : (isIndo ? 'Jalankan Analisis Konsistensi' : 'Run Consistency Analysis'),
                      icon: Symbols.auto_awesome,
                      variant: NvButtonVariant.primary,
                      isLoading: isAnalyzing,
                      onPressed: isAnalyzing
                          ? null
                          : () {
                              ref
                                  .read(consistencyControllerProvider)
                                  .runAnalysis(widget.novelId);
                            },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Report Dashboard
                  if (report != null) ...[
                    _buildReportDashboard(report, c, isIndo),
                  ] else if (!isAnalyzing) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Symbols.playlist_add_check_circle,
                              size: 48,
                              color: c.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isIndo
                                  ? 'Siap memeriksa naskah Anda untuk celah kontinuitas, detail karakter yang bertentangan, dan pelanggaran garis waktu.'
                                  : 'Ready to inspect your novel for continuity gaps, contradictory character details, and timeline breaks.',
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDashboard(
    ConsistencyReport report,
    AppColors c,
    bool isIndo,
  ) {
    final filteredIssues = _filterCategory == null
        ? report.issues
        : report.issues.where((i) => i.category == _filterCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isIndo ? 'Laporan Kontinuitas' : 'Continuity Report',
            style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),

        // Score Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: c.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIndo ? 'Skor Konsistensi' : 'Consistency Score',
                        style: AppTypography.labelSm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.consistencyScore.toInt()}%',
                        style: AppTypography.numeric.copyWith(
                          color: report.consistencyScore >= 80
                              ? Colors.green
                              : (report.consistencyScore >= 60
                                  ? Colors.orange
                                  : c.error),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isIndo ? 'Indeks Inkonsistensi' : 'Inconsistency Index',
                        style: AppTypography.labelSm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.inconsistencyScore.toStringAsFixed(1)}%',
                        style: AppTypography.screenTitle.copyWith(
                          color: report.inconsistencyScore > 20
                              ? c.error
                              : c.textPrimary,
                        ),
                      ),
                      Text(
                        isIndo
                            ? '${report.totalIssues} masalah ditemukan'
                            : '${report.totalIssues} issues found',
                        style: AppTypography.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: (report.consistencyScore / 100.0).clamp(0.0, 1.0),
                backgroundColor: c.outlineVariant,
                valueColor: AlwaysStoppedAnimation(
                  report.consistencyScore >= 80
                      ? Colors.green
                      : (report.consistencyScore >= 60
                          ? Colors.orange
                          : c.error),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                report.summary,
                style: AppTypography.bodySm,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Category Filter Chips
        Text(isIndo ? 'Filter berdasarkan Kategori' : 'Filter by Category',
            style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(isIndo
                    ? 'Semua (${report.issues.length})'
                    : 'All (${report.issues.length})'),
                selected: _filterCategory == null,
                onSelected: (_) => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: AppSpacing.xs),
              ...ConsistencyCategory.values.map((cat) {
                final count =
                    report.issues.where((i) => i.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text('${cat.localizedLabel(isIndo)} ($count)'),
                    selected: _filterCategory == cat,
                    onSelected: (_) =>
                        setState(() => _filterCategory = cat),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Issues List
        Text(
          isIndo
              ? 'Masalah Kontinuitas (${filteredIssues.length})'
              : 'Continuity Issues (${filteredIssues.length})',
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),

        if (filteredIssues.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Center(
              child: Text(
                isIndo
                    ? 'Tidak ada masalah ditemukan dalam kategori ini.'
                    : 'No issues found in this category.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        ] else ...[
          ...filteredIssues.map((issue) => _buildIssueCard(issue, c, isIndo)),
        ],
      ],
    );
  }

  Widget _buildIssueCard(ConsistencyIssue issue, AppColors c, bool isIndo) {
    Color severityColor;
    switch (issue.severity) {
      case ConsistencySeverity.high:
        severityColor = c.error;
        break;
      case ConsistencySeverity.medium:
        severityColor = Colors.orange;
        break;
      case ConsistencySeverity.low:
        severityColor = c.primary;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: severityColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isIndo
                        ? 'Prioritas ${issue.severity.localizedLabel(true)}'
                        : '${issue.severity.label} Priority',
                    style: AppTypography.labelSm.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    issue.category.localizedLabel(isIndo),
                    style: AppTypography.labelSm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  issue.chapterTitle,
                  style: AppTypography.bodySm.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(issue.title, style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.xs),

            // Cited Excerpt
            if (issue.citedExcerpt.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.inset),
                  border: Border(
                    left: BorderSide(color: severityColor, width: 3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.format_quote,
                      size: 16,
                      color: severityColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        issue.citedExcerpt,
                        style: AppTypography.bodySm.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Issue Breakdown
            Text(
              isIndo ? 'Rincian Masalah:' : 'Issue Breakdown:',
              style: AppTypography.labelSm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(issue.issueBreakdown, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),

            // Suggested Correction
            Text(
              isIndo ? 'Saran Perbaikan:' : 'Suggested Correction:',
              style: AppTypography.labelSm.copyWith(color: c.primary),
            ),
            const SizedBox(height: 2),
            Text(
              issue.suggestedCorrection,
              style: AppTypography.body.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Action: Copy suggested correction
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Symbols.content_copy, size: 16),
                label: Text(isIndo ? 'Salin Perbaikan' : 'Copy Correction'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: issue.suggestedCorrection),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isIndo
                          ? 'Saran perbaikan disalin ke papan klip!'
                          : 'Copied correction to clipboard!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
