import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/planning_models.dart';
import '../../domain/repositories/planning_repository.dart';

class DriftPlanningRepository implements PlanningRepository {
  final AppDatabase _db;

  DriftPlanningRepository(this._db);

  TimelineEventModel _eventToDomain(Event row) {
    return TimelineEventModel(
      id: row.id,
      novelId: row.novelId,
      periodId: row.periodId,
      title: row.title,
      description: row.description,
      dateText: row.dateText,
      sortKey: row.sortKey,
      notes: row.notes,
      color: row.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  SceneCardModel _sceneToDomain(Scene row) {
    return SceneCardModel(
      id: row.id,
      novelId: row.novelId,
      arcId: row.arcId,
      chapterId: row.chapterId,
      title: row.title,
      purpose: row.purpose,
      status: row.status,
      dramaticQuestion: row.dramaticQuestion,
      openingValue: row.openingValue,
      closingValue: row.closingValue,
      desiredOutcome: row.desiredOutcome,
      notes: row.notes,
      position: row.position,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  @override
  Stream<List<TimelineEventModel>> watchEvents(String novelId) {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortKey)]);
    return query.watch().map((rows) => rows.map(_eventToDomain).toList());
  }

  @override
  Future<TimelineEventModel> createEvent({
    required String novelId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();
    final effectiveSortKey = sortKey ?? now.toDouble();

    await _db.into(_db.events).insert(
          EventsCompanion(
            id: Value(id),
            novelId: Value(novelId),
            title: Value(title.trim()),
            description: Value(description?.trim()),
            dateText: Value(dateText?.trim()),
            sortKey: Value(effectiveSortKey),
            notes: Value(notes?.trim()),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final row = await (_db.select(_db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _eventToDomain(row);
  }

  @override
  Future<TimelineEventModel> updateEvent({
    required String eventId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(eventId)))
        .write(
      EventsCompanion(
        title: Value(title.trim()),
        description: Value(description?.trim()),
        dateText: Value(dateText?.trim()),
        sortKey: sortKey != null ? Value(sortKey) : const Value.absent(),
        notes: Value(notes?.trim()),
        updatedAt: Value(now),
      ),
    );

    final row = await (_db.select(_db.events)
          ..where((tbl) => tbl.id.equals(eventId)))
        .getSingle();
    return _eventToDomain(row);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(eventId)))
        .write(
      EventsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Stream<List<SceneCardModel>> watchScenes(String novelId, {String? chapterId}) {
    final query = _db.select(_db.scenes)
      ..where((tbl) {
        var expr = tbl.novelId.equals(novelId) & tbl.deletedAt.isNull();
        if (chapterId != null) {
          expr = expr & tbl.chapterId.equals(chapterId);
        }
        return expr;
      })
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]);
    return query.watch().map((rows) => rows.map(_sceneToDomain).toList());
  }

  @override
  Future<SceneCardModel> createScene({
    required String novelId,
    String? chapterId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();

    final existingScenes = await (_db.select(_db.scenes)
          ..where(
            (tbl) =>
                tbl.novelId.equals(novelId) & tbl.deletedAt.isNull(),
          ))
        .get();

    final position = existingScenes.length;

    await _db.into(_db.scenes).insert(
          ScenesCompanion(
            id: Value(id),
            novelId: Value(novelId),
            chapterId: Value(chapterId),
            title: Value(title.trim()),
            purpose: Value(purpose?.trim()),
            dramaticQuestion: Value(dramaticQuestion?.trim()),
            position: Value(position),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final row = await (_db.select(_db.scenes)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _sceneToDomain(row);
  }

  @override
  Future<SceneCardModel> updateScene({
    required String sceneId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
    String? status,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.scenes)..where((tbl) => tbl.id.equals(sceneId)))
        .write(
      ScenesCompanion(
        title: Value(title.trim()),
        purpose: Value(purpose?.trim()),
        dramaticQuestion: Value(dramaticQuestion?.trim()),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );

    final row = await (_db.select(_db.scenes)
          ..where((tbl) => tbl.id.equals(sceneId)))
        .getSingle();
    return _sceneToDomain(row);
  }

  @override
  Future<void> deleteScene(String sceneId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.scenes)..where((tbl) => tbl.id.equals(sceneId)))
        .write(
      ScenesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
