import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_world_repository.dart';
import '../domain/models/world_models.dart';
import '../domain/repositories/world_repository.dart';

final worldRepositoryProvider = Provider<WorldRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftWorldRepository(db);
});

final worldCategoriesStreamProvider =
    StreamProvider.family<List<WorldCategoryModel>, String>((ref, novelId) {
  final repo = ref.watch(worldRepositoryProvider);
  return repo.watchCategories(novelId);
});

final worldEntriesStreamProvider = StreamProvider.family<List<WorldEntryModel>,
    ({String novelId, String? categoryId})>((ref, args) {
  final repo = ref.watch(worldRepositoryProvider);
  return repo.watchEntries(args.novelId, categoryId: args.categoryId);
});

final worldEntryDetailStreamProvider =
    StreamProvider.family<WorldEntryModel?, String>((ref, entryId) {
  final repo = ref.watch(worldRepositoryProvider);
  return repo.watchEntry(entryId);
});

class WorldActionsController {
  final WorldRepository _repo;

  WorldActionsController(this._repo);

  Future<WorldEntryModel> createEntry({
    required String novelId,
    required String categoryId,
    required String name,
    String? subtitle,
    String? summary,
    bool verifiedCanon = false,
  }) {
    return _repo.createEntry(
      novelId: novelId,
      categoryId: categoryId,
      name: name,
      subtitle: subtitle,
      summary: summary,
      verifiedCanon: verifiedCanon,
    );
  }

  Future<void> updateEntry(WorldEntryModel entry) {
    return _repo.updateEntry(entry);
  }

  Future<void> deleteEntry(String entryId) {
    return _repo.deleteEntry(entryId);
  }
}

final worldActionsControllerProvider = Provider<WorldActionsController>((ref) {
  final repo = ref.watch(worldRepositoryProvider);
  return WorldActionsController(repo);
});
