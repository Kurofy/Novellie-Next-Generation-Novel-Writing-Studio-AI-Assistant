import 'package:drift/drift.dart';
import 'novel_tables.dart';

class WorldCategories extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get position => integer()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorldEntries extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get categoryId => text().references(WorldCategories, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get attributesJson => text().withDefault(const Constant('{}'))();
  BoolColumn get verifiedCanon =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorldEntrySections extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(WorldEntries, #id)();
  TextColumn get kind => text().withDefault(const Constant('text'))();
  TextColumn get heading => text()();
  TextColumn get body => text().nullable()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
