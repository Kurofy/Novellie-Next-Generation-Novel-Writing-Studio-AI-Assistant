import 'package:drift/drift.dart';
import 'novel_tables.dart';

class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get name => text()();
  TextColumn get nickname => text().nullable()();
  TextColumn get ageText => text().nullable()();
  IntColumn get ageYears => integer().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get pronouns => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('supporting'))();
  TextColumn get moralAlignment =>
      text().withDefault(const Constant('unspecified'))();
  TextColumn get status => text().withDefault(const Constant('alive'))();
  TextColumn get statusNote => text().nullable()();
  TextColumn get appearance => text().nullable()();
  TextColumn get personality => text().nullable()();
  TextColumn get motivation => text().nullable()();
  TextColumn get goal => text().nullable()();
  TextColumn get fear => text().nullable()();
  TextColumn get secret => text().nullable()();
  TextColumn get flaw => text().nullable()();
  TextColumn get strengths => text().nullable()();
  TextColumn get weaknesses => text().nullable()();
  TextColumn get backstory => text().nullable()();
  TextColumn get arcType => text().nullable()();
  TextColumn get arcSummary => text().nullable()();
  TextColumn get firstAppearanceChapterId => text().nullable()();
  TextColumn get lastAppearanceChapterId => text().nullable()();
  TextColumn get portraitPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CharacterAliases extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text().references(Characters, #id)();
  TextColumn get alias => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class CharacterRelationships extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get characterAId => text().references(Characters, #id)();
  TextColumn get characterBId => text().references(Characters, #id)();
  TextColumn get type => text()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get aToBLabel => text().nullable()();
  TextColumn get bToALabel => text().nullable()();
  IntColumn get strength => integer().nullable()();
  IntColumn get tension => integer().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get startDateText => text().nullable()();
  TextColumn get endDateText => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
