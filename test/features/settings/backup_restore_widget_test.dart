import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:novellie/core/database/app_database.dart';
import 'package:novellie/core/database/database_provider.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/settings/application/backup_service.dart';
import 'package:novellie/features/settings/presentation/screens/diagnostics_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novellie_widget_test_');
    final dbFile = File('${tempDir.path}/widget_test.sqlite');
    db = AppDatabase(NativeDatabase(dbFile));
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupServiceProvider.overrideWithValue(
          BackupService(db,
              overrideBackupsDirectory: Directory('${tempDir.path}/backups'),),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DiagnosticsScreen(initialIndex: 0),
      ),
    );
  }

  testWidgets(
      'DiagnosticsScreen Backup & Restore view renders action buttons and empty state',
      (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsWidgets);
    expect(find.text('Project Archives'), findsOneWidget);
    expect(find.text('Create Backup Now'), findsOneWidget);
    expect(find.text('Import External Backup'), findsOneWidget);
    expect(find.text('No backups found'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets(
      'Displays backup list items and opens Restore Confirmation dialog',
      (tester) async {
    // 1. Insert an existing backup into the database
    await db.into(db.backups).insert(
          BackupsCompanion.insert(
            id: 'backup-widget-1',
            kind: 'manual',
            filePath: '${tempDir.path}/manual_snapshot.db',
            sizeBytes: 1048576, // 1 MB
            schemaVersion: 1,
            appVersion: '1.0.0+1',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            note: const drift.Value('Chapter 1 to 10 Snapshot'),
          ),
        );

    // 2. Render DiagnosticsScreen
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Verify backup appears in the history list
    expect(find.text('Chapter 1 to 10 Snapshot'), findsOneWidget);
    expect(find.textContaining('1024.0 KB'), findsOneWidget);
    expect(find.text('No backups found'), findsNothing);

    // 3. Open Popup Menu
    final moreButton = find.byIcon(Symbols.more_vert);
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    // Verify menu items
    expect(find.text('Restore Archive'), findsOneWidget);
    expect(find.text('Export Archive'), findsOneWidget);
    expect(find.text('Delete Backup'), findsOneWidget);

    // 4. Tap "Restore Archive"
    await tester.tap(find.text('Restore Archive'));
    await tester.pumpAndSettle();

    // Verify safety dialog is shown
    expect(find.text('Restore Archive?'), findsOneWidget);
    expect(
      find.text(
          'Restoring from this archive will replace all current manuscripts, chapters, lore entries, characters, and outlines.',),
      findsOneWidget,
    );
    expect(find.text('Restore Now'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // 5. Tap Cancel to dismiss safely
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Restore Archive?'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('Imported backups display Imported status chip',
      (tester) async {
    await db.into(db.backups).insert(
          BackupsCompanion.insert(
            id: 'backup-widget-2',
            kind: 'imported',
            filePath: '${tempDir.path}/imported_cloud.db',
            sizeBytes: 524288, // 512 KB
            schemaVersion: 1,
            appVersion: '1.0.0+1',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            note: const drift.Value('Imported from Drive'),
          ),
        );

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Imported from Drive'), findsOneWidget);
    expect(find.text('Imported'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
