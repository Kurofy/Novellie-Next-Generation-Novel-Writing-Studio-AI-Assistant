import '../models/planning_models.dart';

abstract class PlanningRepository {
  // Timeline Events
  Stream<List<TimelineEventModel>> watchEvents(String novelId);
  Future<TimelineEventModel> createEvent({
    required String novelId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  });
  Future<TimelineEventModel> updateEvent({
    required String eventId,
    required String title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
  });
  Future<void> deleteEvent(String eventId);

  // Scene Cards
  Stream<List<SceneCardModel>> watchScenes(String novelId, {String? chapterId});
  Future<SceneCardModel> createScene({
    required String novelId,
    String? chapterId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
  });
  Future<SceneCardModel> updateScene({
    required String sceneId,
    required String title,
    String? purpose,
    String? dramaticQuestion,
    String? status,
  });
  Future<void> deleteScene(String sceneId);
}
