import 'package:drift/drift.dart';
import 'novel_tables.dart';

class TimelinePeriods extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get name => text()();
  RealColumn get startSort => real().nullable()();
  RealColumn get endSort => real().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get periodId =>
      text().nullable().references(TimelinePeriods, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get dateText => text().nullable()();
  RealColumn get sortKey => real()();
  RealColumn get endSortKey => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EntityLinks extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get kind => text().withDefault(const Constant('related'))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EntityMentions extends Table {
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get chapterId => text().references(Chapters, #id)();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get mentionCount => integer()();
  TextColumn get source => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {chapterId, entityType, entityId, source};
}
