import 'package:drift/drift.dart';
import 'character_tables.dart';
import 'novel_tables.dart';
import 'world_tables.dart';

class Scenes extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get arcId => text().nullable().references(Arcs, #id)();
  TextColumn get chapterId => text().nullable().references(Chapters, #id)();
  TextColumn get title => text()();
  TextColumn get purpose => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get locationEntryId =>
      text().nullable().references(WorldEntries, #id)();
  TextColumn get povCharacterId =>
      text().nullable().references(Characters, #id)();
  TextColumn get timeOfDay => text().nullable()();
  TextColumn get storyTimeText => text().nullable()();
  IntColumn get tension => integer().nullable()();
  TextColumn get dramaticQuestion => text().nullable()();
  TextColumn get openingValue => text().nullable()();
  TextColumn get closingValue => text().nullable()();
  TextColumn get desiredOutcome => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get wordTarget => integer().nullable()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SceneCharacters extends Table {
  TextColumn get sceneId => text().references(Scenes, #id)();
  TextColumn get characterId => text().references(Characters, #id)();
  TextColumn get agenda => text().nullable()();
  TextColumn get agendaKind => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sceneId, characterId};
}

class SceneBeats extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text().references(Scenes, #id)();
  IntColumn get position => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
