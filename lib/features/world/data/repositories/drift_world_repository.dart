import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/world_models.dart';
import '../../domain/repositories/world_repository.dart';

class DriftWorldRepository implements WorldRepository {
  final AppDatabase _db;

  DriftWorldRepository(this._db);

  WorldCategoryModel _categoryToDomain(WorldCategory row) {
    return WorldCategoryModel(
      id: row.id,
      novelId: row.novelId,
      key: row.key,
      name: row.name,
      icon: row.icon,
      position: row.position,
      isBuiltin: row.isBuiltin,
    );
  }

  WorldEntryModel _entryToDomain(WorldEntry row) {
    return WorldEntryModel(
      id: row.id,
      novelId: row.novelId,
      categoryId: row.categoryId,
      parentId: row.parentId,
      name: row.name,
      subtitle: row.subtitle,
      summary: row.summary,
      coverPath: row.coverPath,
      verifiedCanon: row.verifiedCanon,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  @override
  Stream<List<WorldCategoryModel>> watchCategories(String novelId) {
    final query = _db.select(_db.worldCategories)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]);
    return query.watch().map((rows) => rows.map(_categoryToDomain).toList());
  }

  @override
  Stream<List<WorldEntryModel>> watchEntries(
    String novelId, {
    String? categoryId,
  }) {
    final query = _db.select(_db.worldEntries)
      ..where((tbl) {
        var expr = tbl.novelId.equals(novelId) & tbl.deletedAt.isNull();
        if (categoryId != null) {
          expr = expr & tbl.categoryId.equals(categoryId);
        }
        return expr;
      })
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch().map((rows) => rows.map(_entryToDomain).toList());
  }

  @override
  Stream<WorldEntryModel?> watchEntry(String entryId) {
    final query = _db.select(_db.worldEntries)
      ..where((tbl) => tbl.id.equals(entryId) & tbl.deletedAt.isNull());
    return query
        .watchSingleOrNull()
        .map((row) => row != null ? _entryToDomain(row) : null);
  }

  @override
  Future<WorldEntryModel?> getEntry(String entryId) async {
    final query = _db.select(_db.worldEntries)
      ..where((tbl) => tbl.id.equals(entryId) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _entryToDomain(row) : null;
  }

  @override
  Future<WorldEntryModel> createEntry({
    required String novelId,
    required String categoryId,
    required String name,
    String? subtitle,
    String? summary,
    bool verifiedCanon = false,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();

    await _db.into(_db.worldEntries).insert(
          WorldEntriesCompanion(
            id: Value(id),
            novelId: Value(novelId),
            categoryId: Value(categoryId),
            name: Value(name.trim()),
            subtitle: Value(subtitle?.trim()),
            summary: Value(summary?.trim()),
            verifiedCanon: Value(verifiedCanon),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final created = await getEntry(id);
    return created!;
  }

  @override
  Future<void> updateEntry(WorldEntryModel entry) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.worldEntries)..where((tbl) => tbl.id.equals(entry.id)))
        .write(
      WorldEntriesCompanion(
        categoryId: Value(entry.categoryId),
        name: Value(entry.name),
        subtitle: Value(entry.subtitle),
        summary: Value(entry.summary),
        verifiedCanon: Value(entry.verifiedCanon),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.worldEntries)..where((tbl) => tbl.id.equals(entryId)))
        .write(
      WorldEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
