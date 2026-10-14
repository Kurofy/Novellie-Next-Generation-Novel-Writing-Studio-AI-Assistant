import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../shared/utils/uuid_generator.dart';

class BackupService {
  final AppDatabase _db;
  final Directory? _overrideBackupsDirectory;

  BackupService(this._db, {Directory? overrideBackupsDirectory})
      : _overrideBackupsDirectory = overrideBackupsDirectory;

  /// Returns the directory where backups are stored, creating it if needed.
  Future<Directory> getBackupsDirectory() async {
    if (_overrideBackupsDirectory != null) {
      if (!await _overrideBackupsDirectory.exists()) {
        await _overrideBackupsDirectory.create(recursive: true);
      }
      return _overrideBackupsDirectory;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(appDir.path, 'novellie_backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  /// Creates a real atomic backup of the database using SQLite's VACUUM INTO.
  Future<Backup> createBackup({String? note, String kind = 'manual'}) async {
    final backupsDir = await getBackupsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile =
        File(p.join(backupsDir.path, 'novellie_backup_$timestamp.db'));

    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    // Execute SQLite VACUUM INTO for a consistent, atomic snapshot
    final escapedPath =
        backupFile.path.replaceAll(r'\', '/').replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escapedPath';");

    final sizeBytes = await backupFile.length();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final backupId = generateUuid();
    final defaultNote =
        'Manual backup created on ${DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now())}';

    final companion = BackupsCompanion.insert(
      id: backupId,
      kind: kind,
      filePath: backupFile.path,
      sizeBytes: sizeBytes,
      schemaVersion: _db.schemaVersion,
      appVersion: '1.0.0+1',
      createdAt: nowMs,
      note: Value(note ?? defaultNote),
    );

    await _db.into(_db.backups).insert(companion);

    return Backup(
      id: backupId,
      kind: kind,
      filePath: backupFile.path,
      sizeBytes: sizeBytes,
      schemaVersion: _db.schemaVersion,
      appVersion: '1.0.0+1',
      includesAiHistory: false,
      createdAt: nowMs,
      note: note ?? defaultNote,
    );
  }

  /// Restores the database from a backup file path.
  Future<void> restoreBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (!await file.exists()) {
      throw Exception('Backup archive not found at: $backupFilePath');
    }
    final size = await file.length();
    if (size == 0) {
      throw Exception('Backup archive is empty (0 bytes).');
    }

    final escapedPath =
        backupFilePath.replaceAll(r'\', '/').replaceAll("'", "''");

    // 1. Disable foreign keys prior to attaching and restoring
    await _db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      // 2. Attach backup database
      await _db.customStatement("ATTACH DATABASE '$escapedPath' AS backup_db;");

      try {
        // 3. Quick integrity check of attached backup database
        final checkRows =
            await _db.customSelect('PRAGMA backup_db.quick_check;').get();
        final checkResult = checkRows.isNotEmpty
            ? checkRows.first.data.values.first?.toString()
            : 'ok';
        if (checkResult != 'ok') {
          throw Exception('Corrupted backup file: $checkResult');
        }

        // 4. Verify that tables exist in backup
        final tablesInBackup = await _db
            .customSelect(
                "SELECT name FROM backup_db.sqlite_master WHERE type='table';",)
            .get();
        final backupTableNames =
            tablesInBackup.map((r) => r.read<String>('name')).toSet();

        // 5. Tables to restore: creative, manuscript, and worldbuilding tables
        // Keep backups, app_settings, ai_provider_settings preserved
        const excludedTables = {'backups', 'app_settings', 'ai_provider_settings'};

        final tablesToRestore = _db.allTables.where((table) {
          final tableName = table.actualTableName;
          return !excludedTables.contains(tableName) &&
              backupTableNames.contains(tableName);
        }).toList();

        // 6. Restore each table inside a transaction
        await _db.transaction(() async {
          for (final table in tablesToRestore) {
            final tableName = table.actualTableName;

            // Determine common columns between active schema and backup schema
            final currentColsRows = await _db
                .customSelect('PRAGMA table_info("$tableName");')
                .get();
            final currentCols =
                currentColsRows.map((r) => r.read<String>('name')).toSet();

            final backupColsRows = await _db
                .customSelect('PRAGMA backup_db.table_info("$tableName");')
                .get();
            final backupCols =
                backupColsRows.map((r) => r.read<String>('name')).toSet();

            final commonCols = currentCols.intersection(backupCols).toList();

            // Clear active data in this table
            await _db.customStatement('DELETE FROM "$tableName";');

            // Insert matching columns from backup
            if (commonCols.isNotEmpty) {
              final colsSql = commonCols.map((c) => '"$c"').join(', ');
              await _db.customStatement(
                'INSERT INTO "$tableName" ($colsSql) SELECT $colsSql FROM backup_db."$tableName";',
              );
            }
          }
        });

        // 7. Notify Drift watchers so active UI streams update immediately
        final updates =
            tablesToRestore.map((table) => TableUpdate.onTable(table)).toSet();
        _db.notifyUpdates(updates);
      } finally {
        // Detach database
        await _db.customStatement('DETACH DATABASE backup_db;');
      }
    } finally {
      // Re-enable foreign keys
      await _db.customStatement('PRAGMA foreign_keys = ON;');
    }
  }

  /// Copies an external backup file to the app backups folder, registers it, and restores it.
  Future<Backup> importAndRestoreBackup(String externalPath) async {
    final sourceFile = File(externalPath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected backup file not found.');
    }

    final backupsDir = await getBackupsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final destFile =
        File(p.join(backupsDir.path, 'novellie_imported_$timestamp.db'));

    await sourceFile.copy(destFile.path);

    // Restore from the imported archive
    await restoreBackup(destFile.path);

    final sizeBytes = await destFile.length();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final backupId = generateUuid();
    final note =
        'Imported backup (${p.basename(externalPath)}) on ${DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now())}';

    final companion = BackupsCompanion.insert(
      id: backupId,
      kind: 'imported',
      filePath: destFile.path,
      sizeBytes: sizeBytes,
      schemaVersion: _db.schemaVersion,
      appVersion: '1.0.0+1',
      createdAt: nowMs,
      note: Value(note),
    );

    await _db.into(_db.backups).insert(companion);

    return Backup(
      id: backupId,
      kind: 'imported',
      filePath: destFile.path,
      sizeBytes: sizeBytes,
      schemaVersion: _db.schemaVersion,
      appVersion: '1.0.0+1',
      includesAiHistory: false,
      createdAt: nowMs,
      note: note,
    );
  }

  /// Deletes a backup file from storage and removes its record from the database.
  Future<void> deleteBackup(Backup backup) async {
    try {
      final file = File(backup.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    await (_db.delete(_db.backups)..where((t) => t.id.equals(backup.id))).go();
  }

  /// Prompts user to export the backup file to their desired destination.
  Future<String?> exportBackup(Backup backup) async {
    final sourceFile = File(backup.filePath);
    if (!await sourceFile.exists()) {
      throw Exception('Backup file does not exist at: ${backup.filePath}');
    }

    final defaultFileName = p.basename(backup.filePath);
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Export Backup Archive',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (outputPath != null) {
      await sourceFile.copy(outputPath);
      return outputPath;
    }
    return null;
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});
