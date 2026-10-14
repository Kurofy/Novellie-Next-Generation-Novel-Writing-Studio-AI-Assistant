import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/database/app_database.dart';
import 'package:novellie/features/settings/application/backup_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late BackupService backupService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novellie_backup_test_');
    // Create database backed by a file in tempDir so VACUUM INTO and ATTACH work properly
    final dbFile = File('${tempDir.path}/test_db.sqlite');
    db = AppDatabase(NativeDatabase(dbFile));
    backupService =
        BackupService(db, overrideBackupsDirectory: Directory('${tempDir.path}/backups'));
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('createBackup creates real SQLite backup file and registers record in database', () async {
    // 1. Insert sample novel
    await db.into(db.novels).insert(
          NovelsCompanion.insert(
            id: 'novel-backup-1',
            title: 'Chronicles of Antigravity',
            genre: const Value('Sci-Fi'),
            status: const Value('drafting'),
            createdAt: 1000,
            updatedAt: 1000,
          ),
        );

    // 2. Perform backup
    final backup = await backupService.createBackup(note: 'Test automated backup');

    // 3. Verify backup file exists and has non-zero size
    final backupFile = File(backup.filePath);
    expect(await backupFile.exists(), isTrue);
    expect(await backupFile.length(), greaterThan(0));
    expect(backup.sizeBytes, greaterThan(0));
    expect(backup.note, 'Test automated backup');

    // 4. Verify backup record in database
    final recorded = await (db.select(db.backups)..where((t) => t.id.equals(backup.id))).getSingle();
    expect(recorded.filePath, backup.filePath);
  });

  test('restoreBackup restores project novels and characters from archive', () async {
    // 1. Insert initial data
    await db.into(db.novels).insert(
          NovelsCompanion.insert(
            id: 'novel-restore-original',
            title: 'The Lost Kingdom',
            genre: const Value('Fantasy'),
            status: const Value('drafting'),
            createdAt: 2000,
            updatedAt: 2000,
          ),
        );
    await db.into(db.characters).insert(
          CharactersCompanion.insert(
            id: 'char-1',
            novelId: 'novel-restore-original',
            name: 'Aria Silverwood',
            role: const Value('protagonist'),
            createdAt: 2000,
            updatedAt: 2000,
          ),
        );

    // 2. Create backup
    final backup = await backupService.createBackup(note: 'Snapshot before changes');

    // 3. Mutate data: delete character and add different novel
    await (db.delete(db.characters)..where((t) => t.id.equals('char-1'))).go();
    await (db.delete(db.novels)..where((t) => t.id.equals('novel-restore-original'))).go();
    await db.into(db.novels).insert(
          NovelsCompanion.insert(
            id: 'novel-different',
            title: 'Modern Mystery',
            genre: const Value('Mystery'),
            status: const Value('drafting'),
            createdAt: 3000,
            updatedAt: 3000,
          ),
        );

    // Verify changed state
    var currentNovels = await db.select(db.novels).get();
    expect(currentNovels.map((n) => n.id), contains('novel-different'));
    expect(currentNovels.map((n) => n.id), isNot(contains('novel-restore-original')));

    // 4. Restore from backup
    await backupService.restoreBackup(backup.filePath);

    // 5. Verify restored state
    currentNovels = await db.select(db.novels).get();
    expect(currentNovels.map((n) => n.id), contains('novel-restore-original'));
    expect(currentNovels.map((n) => n.id), isNot(contains('novel-different')));

    final currentCharacters = await db.select(db.characters).get();
    expect(currentCharacters.map((c) => c.id), contains('char-1'));
    expect(currentCharacters.first.name, 'Aria Silverwood');
  });

  test('deleteBackup removes both disk file and database record', () async {
    final backup = await backupService.createBackup(note: 'To be deleted');
    final backupFile = File(backup.filePath);
    expect(await backupFile.exists(), isTrue);

    await backupService.deleteBackup(backup);

    expect(await backupFile.exists(), isFalse);
    final count = await (db.select(db.backups)..where((t) => t.id.equals(backup.id))).get();
    expect(count, isEmpty);
  });

  test('importAndRestoreBackup copies external archive and restores content', () async {
    // 1. Create novel and backup
    await db.into(db.novels).insert(
          NovelsCompanion.insert(
            id: 'novel-external',
            title: 'External Galaxy',
            genre: const Value('Sci-Fi'),
            status: const Value('completed'),
            createdAt: 4000,
            updatedAt: 4000,
          ),
        );
    final backup = await backupService.createBackup(note: 'External source');

    // 2. Put backup in an "external" location
    final externalFile = File('${tempDir.path}/external_downloaded.db');
    await File(backup.filePath).copy(externalFile.path);

    // 3. Clear database novel
    await (db.delete(db.novels)..where((t) => t.id.equals('novel-external'))).go();
    expect(await db.select(db.novels).get(), isEmpty);

    // 4. Import and restore from external file
    final imported = await backupService.importAndRestoreBackup(externalFile.path);
    expect(imported.kind, 'imported');

    // 5. Verify restored
    final novels = await db.select(db.novels).get();
    expect(novels.length, 1);
    expect(novels.first.title, 'External Galaxy');
  });
}
