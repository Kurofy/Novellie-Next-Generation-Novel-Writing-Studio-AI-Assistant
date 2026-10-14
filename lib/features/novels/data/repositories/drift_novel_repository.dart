import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/novel_model.dart';
import '../../domain/repositories/novel_repository.dart';

const _builtinCategories = [
  (key: 'countries', name: 'Countries', icon: 'flag'),
  (key: 'cities', name: 'Cities', icon: 'location_city'),
  (key: 'regions', name: 'Regions', icon: 'map'),
  (key: 'locations', name: 'Locations', icon: 'pin_drop'),
  (key: 'organizations', name: 'Organizations', icon: 'corporate_fare'),
  (key: 'factions', name: 'Factions', icon: 'shield'),
  (key: 'religions', name: 'Religions', icon: 'church'),
  (key: 'languages', name: 'Languages', icon: 'translate'),
  (key: 'races', name: 'Races & Species', icon: 'groups'),
  (key: 'magic_systems', name: 'Magic Systems', icon: 'auto_awesome'),
  (key: 'technology', name: 'Technology', icon: 'memory'),
  (key: 'currency', name: 'Currency & Economy', icon: 'payments'),
  (key: 'governments', name: 'Governments', icon: 'account_balance'),
  (key: 'historical_events', name: 'Historical Events', icon: 'history_edu'),
  (key: 'important_objects', name: 'Important Objects', icon: 'diamond'),
  (key: 'creatures', name: 'Creatures & Beasts', icon: 'pets'),
  (key: 'concepts', name: 'Concepts & Lore', icon: 'lightbulb'),
];

class DriftNovelRepository implements NovelRepository {
  final AppDatabase _db;

  DriftNovelRepository(this._db);

  NovelModel _toDomain(Novel row) {
    return NovelModel(
      id: row.id,
      title: row.title,
      subtitle: row.subtitle,
      author: row.author,
      coverPath: row.coverPath,
      description: row.description,
      genre: row.genre,
      status: NovelStatus.fromString(row.status),
      language: row.language,
      pov: row.pov,
      tense: row.tense,
      dialogueStyle: row.dialogueStyle,
      quotationStyle: row.quotationStyle,
      chapterWordTarget: row.chapterWordTarget,
      novelWordTarget: row.novelWordTarget,
      aiContextAllowed: row.aiContextAllowed,
      totalWordCount: row.totalWordCount,
      chapterCount: row.chapterCount,
      lastOpenedAt: row.lastOpenedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastOpenedAt!, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      archivedAt: row.archivedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true)
          : null,
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true)
          : null,
    );
  }

  @override
  Stream<List<NovelModel>> watchNovels() {
    final query = _db.select(_db.novels)
      ..where((tbl) => tbl.deletedAt.isNull() & tbl.archivedAt.isNull())
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<NovelModel>> getNovels() async {
    final query = _db.select(_db.novels)
      ..where((tbl) => tbl.deletedAt.isNull() & tbl.archivedAt.isNull())
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<NovelModel?> watchNovel(String id) {
    final query = _db.select(_db.novels)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull().map((row) => row != null ? _toDomain(row) : null);
  }

  @override
  Future<NovelModel?> getNovel(String id) async {
    final query = _db.select(_db.novels)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<NovelModel> createNovel({
    required String title,
    String? subtitle,
    String? author,
    String? description,
    String? genre,
    NovelStatus status = NovelStatus.idea,
    int? novelWordTarget,
    int? chapterWordTarget,
    String? coverPath,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final novelId = generateUuid();

    return await _db.transaction(() async {
      await _db.into(_db.novels).insert(
            NovelsCompanion(
              id: Value(novelId),
              title: Value(title.trim()),
              subtitle: Value(subtitle?.trim()),
              author: Value(author?.trim()),
              coverPath: Value(coverPath),
              description: Value(description?.trim()),
              genre: Value(genre?.trim()),
              status: Value(status.name),
              novelWordTarget: Value(novelWordTarget),
              chapterWordTarget: Value(chapterWordTarget),
              createdAt: Value(now),
              updatedAt: Value(now),
              lastOpenedAt: Value(now),
            ),
          );

      // Seed 17 built-in world categories (schema.md §17)
      for (var i = 0; i < _builtinCategories.length; i++) {
        final cat = _builtinCategories[i];
        await _db.into(_db.worldCategories).insert(
              WorldCategoriesCompanion(
                id: Value(generateUuid()),
                novelId: Value(novelId),
                key: Value(cat.key),
                name: Value(cat.name),
                icon: Value(cat.icon),
                position: Value(i),
                isBuiltin: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

      final created = await getNovel(novelId);
      return created!;
    });
  }

  @override
  Future<void> updateNovel(NovelModel novel) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.novels)..where((tbl) => tbl.id.equals(novel.id))).write(
      NovelsCompanion(
        title: Value(novel.title),
        subtitle: Value(novel.subtitle),
        author: Value(novel.author),
        coverPath: Value(novel.coverPath),
        description: Value(novel.description),
        genre: Value(novel.genre),
        status: Value(novel.status.name),
        novelWordTarget: Value(novel.novelWordTarget),
        chapterWordTarget: Value(novel.chapterWordTarget),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteNovel(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.novels)..where((tbl) => tbl.id.equals(id))).write(
      NovelsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> updateLastOpened(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.novels)..where((tbl) => tbl.id.equals(id))).write(
      NovelsCompanion(
        lastOpenedAt: Value(now),
      ),
    );
  }
}
