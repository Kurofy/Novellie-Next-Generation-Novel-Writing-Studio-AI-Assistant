import '../models/world_models.dart';

abstract class WorldRepository {
  Stream<List<WorldCategoryModel>> watchCategories(String novelId);
  Stream<List<WorldEntryModel>> watchEntries(
    String novelId, {
    String? categoryId,
  });
  Stream<WorldEntryModel?> watchEntry(String entryId);
  Future<WorldEntryModel?> getEntry(String entryId);
  Future<WorldEntryModel> createEntry({
    required String novelId,
    required String categoryId,
    required String name,
    String? subtitle,
    String? summary,
    bool verifiedCanon = false,
  });
  Future<void> updateEntry(WorldEntryModel entry);
  Future<void> deleteEntry(String entryId);
}
