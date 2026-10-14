import '../models/novel_model.dart';

abstract class NovelRepository {
  Stream<List<NovelModel>> watchNovels();
  Future<List<NovelModel>> getNovels();
  Stream<NovelModel?> watchNovel(String id);
  Future<NovelModel?> getNovel(String id);
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
  });
  Future<void> updateNovel(NovelModel novel);
  Future<void> deleteNovel(String id);
  Future<void> updateLastOpened(String id);
}
