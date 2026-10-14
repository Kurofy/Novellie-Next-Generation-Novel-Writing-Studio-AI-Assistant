import '../models/manuscript_models.dart';

abstract class ManuscriptRepository {
  Stream<List<VolumeModel>> watchVolumes(String novelId);
  Stream<List<ArcModel>> watchArcs(String novelId);
  Stream<List<ChapterModel>> watchChapters(String novelId);
  Stream<ChapterModel?> watchChapter(String chapterId);
  Future<ChapterModel?> getChapter(String chapterId);

  Future<VolumeModel> createVolume(String novelId, String title);
  Future<ArcModel> createArc(String novelId, String volumeId, String title);
  Future<ChapterModel> createChapter(
    String novelId, {
    String? arcId,
    String? title,
  });

  Future<void> updateChapter(ChapterModel chapter);
  Future<void> deleteChapter(String chapterId);

  Future<ChapterContentModel> getChapterContent(String chapterId);
  Stream<ChapterContentModel?> watchChapterContent(String chapterId);
  Future<void> saveChapterContent(
    String chapterId, {
    required String deltaJson,
    required String plainText,
    required int wordCount,
    required int charCount,
  });
}
