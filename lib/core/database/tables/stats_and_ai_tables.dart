import 'package:drift/drift.dart';
import 'novel_tables.dart';

class WritingGoals extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().nullable().references(Novels, #id)();
  TextColumn get kind => text()();
  IntColumn get targetWords => integer().nullable()();
  IntColumn get deadlineAt => integer().nullable()();
  TextColumn get chapterId => text().nullable().references(Chapters, #id)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WritingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get activeSeconds => integer().withDefault(const Constant(0))();
  IntColumn get wordsAdded => integer().withDefault(const Constant(0))();
  IntColumn get wordsRemoved => integer().withDefault(const Constant(0))();
  IntColumn get netWords => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyWritingStats extends Table {
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get localDate => text()();
  IntColumn get utcOffsetMin => integer()();
  IntColumn get wordsWritten => integer().withDefault(const Constant(0))();
  IntColumn get activeSeconds => integer().withDefault(const Constant(0))();
  IntColumn get sessions => integer().withDefault(const Constant(0))();
  BoolColumn get goalMet => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {novelId, localDate};
}

class Backups extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get novelId => text().nullable().references(Novels, #id)();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get schemaVersion => integer()();
  TextColumn get appVersion => text()();
  BoolColumn get includesAiHistory =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
