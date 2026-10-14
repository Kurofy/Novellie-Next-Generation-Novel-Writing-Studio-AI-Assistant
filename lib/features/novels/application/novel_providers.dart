import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_novel_repository.dart';
import '../domain/models/novel_model.dart';
import '../domain/repositories/novel_repository.dart';

final novelRepositoryProvider = Provider<NovelRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftNovelRepository(db);
});

final novelListStreamProvider = StreamProvider<List<NovelModel>>((ref) {
  final repo = ref.watch(novelRepositoryProvider);
  return repo.watchNovels();
});

final novelDetailStreamProvider =
    StreamProvider.family<NovelModel?, String>((ref, id) {
  final repo = ref.watch(novelRepositoryProvider);
  return repo.watchNovel(id);
});

final activeNovelIdProvider = StateProvider<String?>((ref) => null);

final activeNovelProvider = Provider<AsyncValue<NovelModel?>>((ref) {
  final activeId = ref.watch(activeNovelIdProvider);
  if (activeId == null) {
    // If not set explicitly, pick the most recently opened novel
    final novelsAsync = ref.watch(novelListStreamProvider);
    return novelsAsync.whenData((novels) {
      if (novels.isEmpty) return null;
      return novels.first;
    });
  }
  return ref.watch(novelDetailStreamProvider(activeId));
});

class NovelActionsController {
  final Ref _ref;

  NovelActionsController(this._ref);

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
    final repo = _ref.read(novelRepositoryProvider);
    final novel = await repo.createNovel(
      title: title,
      subtitle: subtitle,
      author: author,
      description: description,
      genre: genre,
      status: status,
      novelWordTarget: novelWordTarget,
      chapterWordTarget: chapterWordTarget,
      coverPath: coverPath,
    );
    _ref.read(activeNovelIdProvider.notifier).state = novel.id;
    return novel;
  }

  Future<void> updateNovel(NovelModel novel) async {
    final repo = _ref.read(novelRepositoryProvider);
    await repo.updateNovel(novel);
  }

  Future<void> deleteNovel(String id) async {
    final repo = _ref.read(novelRepositoryProvider);
    await repo.deleteNovel(id);
    if (_ref.read(activeNovelIdProvider) == id) {
      _ref.read(activeNovelIdProvider.notifier).state = null;
    }
    _ref.invalidate(novelListStreamProvider);
  }

  Future<void> openNovel(String id) async {
    final repo = _ref.read(novelRepositoryProvider);
    await repo.updateLastOpened(id);
    _ref.read(activeNovelIdProvider.notifier).state = id;
  }
}

final novelActionsControllerProvider = Provider<NovelActionsController>((ref) {
  return NovelActionsController(ref);
});
