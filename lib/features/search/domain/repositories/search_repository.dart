import '../models/search_result_item.dart';

abstract class SearchRepository {
  Future<List<SearchResultItem>> search({
    required String query,
    SearchResultType typeFilter = SearchResultType.all,
    String? novelId,
  });

  Future<Set<String>> searchMatchingNovelIds(String query);
}
