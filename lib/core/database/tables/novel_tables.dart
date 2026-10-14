import 'package:drift/drift.dart';

class Novels extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('idea'))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  TextColumn get pov => text().nullable()();
  TextColumn get tense => text().nullable()();
  TextColumn get dialogueStyle => text().nullable()();
  TextColumn get quotationStyle => text().nullable()();
  IntColumn get chapterWordTarget => integer().nullable()();
  IntColumn get novelWordTarget => integer().nullable()();
  BoolColumn get aiContextAllowed =>
      boolean().withDefault(const Constant(false))();
  IntColumn get totalWordCount => integer().withDefault(const Constant(0))();
  IntColumn get chapterCount => integer().withDefault(const Constant(0))();
  IntColumn get lastOpenedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().nullable().references(Novels, #id)();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EntityTags extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {entityType, entityId, tagId};
}

class Volumes extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get position => integer()();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Arcs extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get position => integer()();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get arcId => text().references(Arcs, #id)();
  TextColumn get title => text().withDefault(const Constant(''))();
  IntColumn get position => integer()();
  IntColumn get sequenceNumber => integer()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get summary => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get authorNote => text().nullable()();
  TextColumn get chapterNote => text().nullable()();
  IntColumn get wordTarget => integer().nullable()();
  TextColumn get povCharacterId => text().nullable()();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChapterContents extends Table {
  TextColumn get chapterId => text().references(Chapters, #id)();
  TextColumn get deltaJson =>
      text().withDefault(const Constant('[{"insert":"\\n"}]'))();
  TextColumn get plainText => text().withDefault(const Constant(''))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  IntColumn get formatVersion => integer().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {chapterId};
}

class ChapterVersions extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text().references(Novels, #id)();
  TextColumn get chapterId => text().references(Chapters, #id)();
  TextColumn get kind => text()();
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();
  BlobColumn get deltaZlib => blob()();
  IntColumn get wordCount => integer()();
  IntColumn get wordDelta => integer().nullable()();
  TextColumn get parentVersionId => text().nullable()();
  IntColumn get createdAt => integer()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
