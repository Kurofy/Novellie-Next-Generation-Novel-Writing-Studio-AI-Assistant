import 'package:drift/drift.dart';

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

class UserProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get displayName => text().nullable()();
  TextColumn get penName => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AiProviderSettings extends Table {
  TextColumn get providerId => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get modelId => text().nullable()();
  RealColumn get temperature => real().nullable()();
  IntColumn get maxOutputTokens => integer().nullable()();
  BoolColumn get keyPresent => boolean().withDefault(const Constant(false))();
  IntColumn get lastTestAt => integer().nullable()();
  BoolColumn get lastTestOk => boolean().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {providerId};
}
