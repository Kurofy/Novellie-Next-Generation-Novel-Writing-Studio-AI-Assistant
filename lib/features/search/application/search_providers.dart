import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_search_repository.dart';
import '../domain/models/search_result_item.dart';
import '../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSearchRepository(db);
});

final searchCategoryFilterProvider =
    StateProvider<SearchResultType>((ref) => SearchResultType.all);

final globalSearchResultsProvider =
    FutureProvider.family<List<SearchResultItem>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return const [];
  final repo = ref.watch(searchRepositoryProvider);
  return repo.search(query: cleanQuery);
});

final matchingNovelIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return const {};
  final repo = ref.watch(searchRepositoryProvider);
  return repo.searchMatchingNovelIds(cleanQuery);
});
