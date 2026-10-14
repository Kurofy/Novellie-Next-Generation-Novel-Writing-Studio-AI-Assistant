import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/backup_service.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const DiagnosticsScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRunningCheck = false;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  String? _integrityResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runIntegrityCheck() async {
    setState(() => _isRunningCheck = true);
    final db = ref.read(appDatabaseProvider);

    try {
      final rows = await db.customSelect('PRAGMA integrity_check;').get();
      final result = rows.isNotEmpty
          ? rows.first.data.values.first?.toString() ?? 'ok'
          : 'ok';

      if (mounted) {
        setState(() {
          _integrityResult = result;
          _isRunningCheck = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _integrityResult = 'Error: $e';
          _isRunningCheck = false;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    final backupService = ref.read(backupServiceProvider);

    try {
      final backup = await backupService.createBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup saved successfully (${(backup.sizeBytes / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _confirmAndRestore(Backup b) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Icon(Symbols.warning, color: c.warning, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Restore Archive?',
                style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restoring from this archive will replace all current manuscripts, chapters, lore entries, characters, and outlines.',
              style: AppTypography.body.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.inset),
                border: Border.all(color: c.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.note ?? 'Archive snapshot',
                    style: AppTypography.body.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${(b.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This action cannot be undone. Are you sure you want to proceed?',
              style: AppTypography.bodySm.copyWith(
                color: c.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    final backupService = ref.read(backupServiceProvider);

    try {
      await backupService.restoreBackup(b.filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Project data restored successfully from archive!'),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore backup: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _importExternalBackup() async {
    final c = context.colors;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;
      final pickedPath = result.files.first.path;
      if (pickedPath == null || !File(pickedPath).existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not access selected file.'),
              backgroundColor: c.error,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final fileName = result.files.first.name;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Row(
            children: [
              Icon(Symbols.file_open, color: c.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Import & Restore Archive?',
                  style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restoring this file will import the archive into your backup history and overwrite current manuscripts and lore.',
                style: AppTypography.body.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.inset),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Text(
                  fileName,
                  style: AppTypography.body.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Are you sure you want to proceed?',
                style: AppTypography.bodySm.copyWith(
                  color: c.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import & Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isRestoring = true);
      final backupService = ref.read(backupServiceProvider);
      await backupService.importAndRestoreBackup(pickedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Archive "$fileName" successfully imported and restored!'),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import backup: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _deleteBackup(Backup b) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Delete Backup?',
          style: AppTypography.cardTitle.copyWith(color: c.textPrimary),
        ),
        content: Text(
          'This will permanently delete this backup file from your device.',
          style: AppTypography.body.copyWith(color: c.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(backupServiceProvider).deleteBackup(b);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup deleted.'),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete backup: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportBackup(Backup b) async {
    final c = context.colors;
    try {
      final savedPath = await ref.read(backupServiceProvider).exportBackup(b);
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported backup to ${p.basename(savedPath)}'),
            backgroundColor: c.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export backup: $e'),
            backgroundColor: c.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: NvAppBar(
        title: _tabController.index == 0
            ? (l10n?.backupAndRestore ?? 'Backup & Restore')
            : (l10n?.aboutAndDiagnostics ?? 'About & Diagnostics'),
        showBack: true,
      ),
      body: Column(
        children: [
          Container(
            color: c.surface,
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicatorColor: c.primary,
              labelColor: c.primary,
              unselectedLabelColor: c.textSecondary,
              labelStyle: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  icon: const Icon(Symbols.backup, size: 20),
                  text: l10n?.backupAndRestore ?? 'Backup & Restore',
                ),
                Tab(
                  icon: const Icon(Symbols.info, size: 20),
                  text: l10n?.aboutAndDiagnostics ?? 'About & Diagnostics',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 0: Backup & Restore View
                _buildBackupRestoreView(c, db, l10n),

                // TAB 1: About & Diagnostics View
                _buildDiagnosticsView(c, db, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestoreView(AppColors c, AppDatabase db, AppLocalizations? l10n) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin(context),
        vertical: AppSpacing.xl,
      ),
      children: [
        Text(l10n?.projectBackups ?? 'Project Backups', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        NvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.inset),
                    ),
                    child:
                        Icon(Symbols.cloud_upload, color: c.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.projectArchives ?? 'Project Archives',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.projectArchivesDesc ??
                              'Save or restore complete snapshots of novels, chapters, lore, characters, and outlines.',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isCreatingBackup || _isRestoring)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _isCreatingBackup
                          ? (l10n?.localeName == 'id'
                              ? 'Membuat snapshot basis data SQLite...'
                              : 'Creating SQLite snapshot...')
                          : (l10n?.localeName == 'id'
                              ? 'Memulihkan data proyek...'
                              : 'Restoring project data...'),
                      style: AppTypography.bodySm.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    NvButton(
                      label: l10n?.createBackupNow ?? 'Create Backup Now',
                      icon: Symbols.backup,
                      variant: NvButtonVariant.primary,
                      onPressed: _createBackup,
                    ),
                    NvButton(
                      label: l10n?.importExternalBackup ?? 'Import External Backup',
                      icon: Symbols.file_open,
                      variant: NvButtonVariant.secondary,
                      onPressed: _importExternalBackup,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text(l10n?.backupHistory ?? 'Backup History', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<Backup>>(
          stream: (db.select(db.backups)
                ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
              .watch(),
          builder: (ctx, snapshot) {
            final backups = snapshot.data ?? [];
            if (backups.isEmpty) {
              return NvCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(Symbols.cloud_off, size: 36, color: c.textMuted),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No backups found',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Create your first backup above to ensure your manuscripts are securely archived.',
                        style: AppTypography.bodySm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return NvCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final b = backups[idx];
                  final isImported = b.kind == 'imported';
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(b.createdAt);
                  final formattedDate =
                      DateFormat('MMM d, yyyy · h:mm a').format(date);
                  final sizeKb = (b.sizeBytes / 1024).toStringAsFixed(1);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isImported ? c.warningContainer : c.primarySoft,
                      child: Icon(
                        isImported
                            ? Symbols.file_download_done
                            : Symbols.inventory_2,
                        color: isImported ? c.warning : c.primary,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.note ?? 'Manual Archive',
                            style: AppTypography.body
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isImported) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const NvChip.status(
                            label: 'Imported',
                            statusKind: NvStatusTagKind.warning,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '$formattedDate · $sizeKb KB',
                      style: AppTypography.bodySm,
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Symbols.more_vert, color: c.textSecondary),
                      onSelected: (val) {
                        if (val == 'restore') {
                          _confirmAndRestore(b);
                        } else if (val == 'export') {
                          _exportBackup(b);
                        } else if (val == 'delete') {
                          _deleteBackup(b);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Symbols.restore, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Restore Archive')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Symbols.file_download, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Export Archive')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Symbols.delete, size: 18, color: c.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delete Backup',
                                  style: TextStyle(color: c.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiagnosticsView(AppColors c, AppDatabase db, AppLocalizations? l10n) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin(context),
        vertical: AppSpacing.xl,
      ),
      children: [
        // App Information
        Text(l10n?.systemInformation ?? 'System Information', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        NvCard(
          child: Column(
            children: [
              _DiagnosticRow(label: l10n?.application ?? 'Application', value: 'Novellie OS'),
              const Divider(height: 1),
              _DiagnosticRow(label: l10n?.version ?? 'Version', value: '1.0.0+1'),
              const Divider(height: 1),
              _DiagnosticRow(label: l10n?.databaseSchema ?? 'Database Schema', value: 'Version 1'),
              const Divider(height: 1),
              _DiagnosticRow(label: l10n?.journalMode ?? 'Journal Mode', value: 'WAL (Write-Ahead)'),
              const Divider(height: 1),
              _DiagnosticRow(label: l10n?.autosaveCadence ?? 'Autosave Cadence', value: '800ms debounce'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Database Integrity Check
        Text(l10n?.databaseIntegrity ?? 'Database Integrity', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        NvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.sqliteIntegrityCheck ?? 'SQLite Integrity Check',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n?.sqliteIntegrityDesc ?? 'Verify B-tree structure, index alignment, and table sanity',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ),
                  if (_integrityResult != null)
                    NvChip.status(
                      label: _integrityResult == 'ok'
                          ? (l10n?.integrityPassed ?? 'Passed')
                          : (l10n?.integrityAlert ?? 'Alert'),
                      statusKind: _integrityResult == 'ok'
                          ? NvStatusTagKind.success
                          : NvStatusTagKind.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isRunningCheck)
                const Center(child: CircularProgressIndicator())
              else
                NvButton.secondary(
                  label: _integrityResult == null
                      ? (l10n?.runIntegrityCheck ?? 'Run Integrity Check')
                      : (l10n?.reverifyDatabase ?? 'Re-verify Database'),
                  onPressed: _runIntegrityCheck,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Database Records
        Text(l10n?.storedRecords ?? 'Stored Records', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<int>>(
          future: Future.wait([
            (db.select(db.novels)..where((t) => t.deletedAt.isNull()))
                .get()
                .then((l) => l.length),
            (db.select(db.chapters)..where((t) => t.deletedAt.isNull()))
                .get()
                .then((l) => l.length),
            (db.select(db.characters)..where((t) => t.deletedAt.isNull()))
                .get()
                .then((l) => l.length),
            (db.select(db.worldEntries)..where((t) => t.deletedAt.isNull()))
                .get()
                .then((l) => l.length),
            (db.select(db.events)..where((t) => t.deletedAt.isNull()))
                .get()
                .then((l) => l.length),
            db.select(db.chapterVersions).get().then((l) => l.length),
          ]),
          builder: (ctx, snapshot) {
            final counts = snapshot.data ?? [0, 0, 0, 0, 0, 0];
            return NvCard(
              child: Column(
                children: [
                  _DiagnosticRow(label: l10n?.recordNovels ?? 'Novels', value: '${counts[0]}'),
                  const Divider(height: 1),
                  _DiagnosticRow(label: l10n?.recordChapters ?? 'Chapters', value: '${counts[1]}'),
                  const Divider(height: 1),
                  _DiagnosticRow(label: l10n?.recordCharacters ?? 'Characters', value: '${counts[2]}'),
                  const Divider(height: 1),
                  _DiagnosticRow(label: l10n?.recordWorldLore ?? 'World Lore', value: '${counts[3]}'),
                  const Divider(height: 1),
                  _DiagnosticRow(label: l10n?.recordTimelineEvents ?? 'Timeline Events', value: '${counts[4]}'),
                  const Divider(height: 1),
                  _DiagnosticRow(
                    label: l10n?.recordVersionSnapshots ?? 'Version Snapshots',
                    value: '${counts[5]}',
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
