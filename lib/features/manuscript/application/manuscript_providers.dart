import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_manuscript_repository.dart';
import '../domain/models/manuscript_models.dart';
import '../domain/repositories/manuscript_repository.dart';

final manuscriptRepositoryProvider = Provider<ManuscriptRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftManuscriptRepository(db);
});

final volumesStreamProvider =
    StreamProvider.family<List<VolumeModel>, String>((ref, novelId) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return repo.watchVolumes(novelId);
});

final arcsStreamProvider =
    StreamProvider.family<List<ArcModel>, String>((ref, novelId) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return repo.watchArcs(novelId);
});

final chaptersStreamProvider =
    StreamProvider.family<List<ChapterModel>, String>((ref, novelId) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return repo.watchChapters(novelId);
});

final chapterDetailStreamProvider =
    StreamProvider.family<ChapterModel?, String>((ref, chapterId) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return repo.watchChapter(chapterId);
});

final chapterContentStreamProvider =
    StreamProvider.family<ChapterContentModel?, String>((ref, chapterId) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return repo.watchChapterContent(chapterId);
});

class ManuscriptActionsController {
  final ManuscriptRepository _repo;

  ManuscriptActionsController(this._repo);

  Future<VolumeModel> createVolume(String novelId, String title) {
    return _repo.createVolume(novelId, title);
  }

  Future<ArcModel> createArc(String novelId, String volumeId, String title) {
    return _repo.createArc(novelId, volumeId, title);
  }

  Future<ChapterModel> createChapter(
    String novelId, {
    String? arcId,
    String? title,
  }) {
    return _repo.createChapter(novelId, arcId: arcId, title: title);
  }

  Future<void> updateChapter(ChapterModel chapter) {
    return _repo.updateChapter(chapter);
  }

  Future<void> deleteChapter(String chapterId) {
    return _repo.deleteChapter(chapterId);
  }

  Future<void> saveChapterContent(
    String chapterId, {
    required String deltaJson,
    required String plainText,
    required int wordCount,
    required int charCount,
  }) {
    return _repo.saveChapterContent(
      chapterId,
      deltaJson: deltaJson,
      plainText: plainText,
      wordCount: wordCount,
      charCount: charCount,
    );
  }
}

final manuscriptActionsControllerProvider =
    Provider<ManuscriptActionsController>((ref) {
  final repo = ref.watch(manuscriptRepositoryProvider);
  return ManuscriptActionsController(repo);
});
