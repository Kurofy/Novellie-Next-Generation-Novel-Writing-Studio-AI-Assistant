import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_planning_repository.dart';
import '../domain/models/planning_models.dart';
import '../domain/repositories/planning_repository.dart';

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftPlanningRepository(db);
});

final timelineEventsStreamProvider =
    StreamProvider.family<List<TimelineEventModel>, String>((ref, novelId) {
  final repo = ref.watch(planningRepositoryProvider);
  return repo.watchEvents(novelId);
});

final sceneCardsStreamProvider = StreamProvider.family<List<SceneCardModel>,
    ({String novelId, String? chapterId})>((ref, args) {
  final repo = ref.watch(planningRepositoryProvider);
  return repo.watchScenes(args.novelId, chapterId: args.chapterId);
});

class PlanningActionsController {
  final PlanningRepository _repo;

  PlanningActionsController(this._repo);

  Future<TimelineEventModel> createEvent({
    required String novelId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  }) {
    return _repo.createEvent(
      novelId: novelId,
      title: title,
      description: description,
      dateText: dateText,
      sortKey: sortKey,
      notes: notes,
    );
  }

  Future<TimelineEventModel> updateEvent({
    required String eventId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  }) {
    return _repo.updateEvent(
      eventId: eventId,
      title: title,
      description: description,
      dateText: dateText,
      sortKey: sortKey,
      notes: notes,
    );
  }

  Future<void> deleteEvent(String eventId) {
    return _repo.deleteEvent(eventId);
  }

  Future<SceneCardModel> createScene({
    required String novelId,
    String? chapterId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
  }) {
    return _repo.createScene(
      novelId: novelId,
      chapterId: chapterId,
      title: title,
      purpose: purpose,
      dramaticQuestion: dramaticQuestion,
    );
  }

  Future<SceneCardModel> updateScene({
    required String sceneId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
    String? status,
  }) {
    return _repo.updateScene(
      sceneId: sceneId,
      title: title,
      purpose: purpose,
      dramaticQuestion: dramaticQuestion,
      status: status,
    );
  }

  Future<void> deleteScene(String sceneId) {
    return _repo.deleteScene(sceneId);
  }
}

final planningActionsControllerProvider =
    Provider<PlanningActionsController>((ref) {
  final repo = ref.watch(planningRepositoryProvider);
  return PlanningActionsController(repo);
});
