import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/manuscript_providers.dart';

class VersionHistoryScreen extends ConsumerStatefulWidget {
  final String novelId;
  final String chapterId;

  const VersionHistoryScreen({
    super.key,
    required this.novelId,
    required this.chapterId,
  });

  @override
  ConsumerState<VersionHistoryScreen> createState() =>
      _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends ConsumerState<VersionHistoryScreen> {
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _createSnapshot() async {
    final label = _labelController.text.trim();
    final db = ref.read(appDatabaseProvider);
    final content = await ref
        .read(manuscriptRepositoryProvider)
        .getChapterContent(widget.chapterId);

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();
    final bytes = utf8.encode(content.deltaJson);

    await db.into(db.chapterVersions).insert(
          ChapterVersionsCompanion(
            id: drift.Value(id),
            novelId: drift.Value(widget.novelId),
            chapterId: drift.Value(widget.chapterId),
            kind: const drift.Value('manual'),
            label: drift.Value(label.isNotEmpty ? label : 'Manual Snapshot'),
            deltaZlib: drift.Value(bytes),
            wordCount: drift.Value(content.wordCount),
            createdAt: drift.Value(now),
          ),
        );

    _labelController.clear();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot saved successfully')),
      );
    }
  }

  void _showCreateSnapshotDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Version Snapshot'),
        content: TextField(
          controller: _labelController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Before climax revision',
            labelText: 'Snapshot Label (Optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          NvButton(
            label: 'Save Snapshot',
            onPressed: _createSnapshot,
          ),
        ],
      ),
    );
  }

  Future<void> _restoreVersion(ChapterVersion version) async {
    // 1. Safety snapshot of current content before restore (rules.md §2.7, §2.11)
    final db = ref.read(appDatabaseProvider);
    final current = await ref
        .read(manuscriptRepositoryProvider)
        .getChapterContent(widget.chapterId);

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.into(db.chapterVersions).insert(
          ChapterVersionsCompanion(
            id: drift.Value(generateUuid()),
            novelId: drift.Value(widget.novelId),
            chapterId: drift.Value(widget.chapterId),
            kind: const drift.Value('pre_restore'),
            label: const drift.Value('Safety Snapshot (Before Restore)'),
            deltaZlib: drift.Value(utf8.encode(current.deltaJson)),
            wordCount: drift.Value(current.wordCount),
            createdAt: drift.Value(now),
          ),
        );

    // 2. Restore past content
    final restoredDelta = utf8.decode(version.deltaZlib);
    await ref.read(manuscriptActionsControllerProvider).saveChapterContent(
          widget.chapterId,
          deltaJson: restoredDelta,
          plainText: '',
          wordCount: version.wordCount,
          charCount: restoredDelta.length,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restored version successfully. Safety backup created.'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final db = ref.watch(appDatabaseProvider);

    final versionsStream = (db.select(db.chapterVersions)
          ..where((tbl) => tbl.chapterId.equals(widget.chapterId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.createdAt)]))
        .watch();

    return Scaffold(
      appBar: NvAppBar(
        title: 'Version History',
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_circle),
            onPressed: _showCreateSnapshotDialog,
            tooltip: 'Take Snapshot',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSnapshotDialog,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.bookmark_add),
        label: const Text('Take Snapshot'),
      ),
      body: StreamBuilder<List<ChapterVersion>>(
        stream: versionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final versions = snapshot.data ?? [];

          if (versions.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                child: NvEmptyState.nothingYet(
                  icon: Symbols.history,
                  title: 'No snapshots yet',
                  body:
                      'Take snapshots to capture revisions, milestones, or explore alternative directions.',
                  actionLabel: 'Take First Snapshot',
                  onAction: _showCreateSnapshotDialog,
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
            itemCount: versions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final version = versions[index];
              final dateStr = DateFormat.yMMMd().add_jm().format(
                    DateTime.fromMillisecondsSinceEpoch(
                      version.createdAt,
                      isUtc: true,
                    ).toLocal(),
                  );

              return NvCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.inset),
                      ),
                      child: Icon(
                        Symbols.history_edu,
                        color: c.primary,
                        size: 22,
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
                                  version.label ?? 'Version Snapshot',
                                  style: AppTypography.cardTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              NvChip.status(
                                label: version.kind.toUpperCase(),
                                statusKind: NvStatusTagKind.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$dateStr · ${version.wordCount} words',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: () => _restoreVersion(version),
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
