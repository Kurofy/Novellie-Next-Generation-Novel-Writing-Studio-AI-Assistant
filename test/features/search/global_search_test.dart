import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/dashboard/presentation/screens/home_screen.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/search/application/search_providers.dart';
import 'package:novellie/features/search/domain/models/search_result_item.dart';
import 'package:novellie/features/search/domain/repositories/search_repository.dart';
import 'package:novellie/l10n/app_localizations.dart';

class _FakeSearchRepository implements SearchRepository {
  final List<SearchResultItem> allItems;

  _FakeSearchRepository(this.allItems);

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    SearchResultType typeFilter = SearchResultType.all,
    String? novelId,
  }) async {
    final lowerQ = query.trim().toLowerCase();
    if (lowerQ.isEmpty) return const [];

    return allItems.where((item) {
      final matchesQuery = item.title.toLowerCase().contains(lowerQ) ||
          (item.subtitle?.toLowerCase().contains(lowerQ) ?? false) ||
          (item.snippet?.toLowerCase().contains(lowerQ) ?? false);

      final matchesType =
          typeFilter == SearchResultType.all || item.type == typeFilter;
      final matchesNovel = novelId == null || item.novelId == novelId;

      return matchesQuery && matchesType && matchesNovel;
    }).toList();
  }

  @override
  Future<Set<String>> searchMatchingNovelIds(String query) async {
    final lowerQ = query.trim().toLowerCase();
    if (lowerQ.isEmpty) return const {};

    return allItems
        .where(
          (item) =>
              item.title.toLowerCase().contains(lowerQ) ||
              (item.snippet?.toLowerCase().contains(lowerQ) ?? false),
        )
        .map((item) => item.novelId ?? item.id)
        .toSet();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testItems = [
    const SearchResultItem(
      id: 'novel-1',
      type: SearchResultType.novel,
      title: 'Echoes of Eternity',
      subtitle: 'Fantasy · 12 chapters · 35,000 words',
      novelId: 'novel-1',
      novelTitle: 'Echoes of Eternity',
      tag: 'Fantasy',
    ),
    const SearchResultItem(
      id: 'chap-1',
      type: SearchResultType.chapter,
      title: 'Chapter 1: The Awakening',
      subtitle: 'in Echoes of Eternity · 3,200 words',
      snippet: 'Aria opened her eyes as the crystal began to hum.',
      novelId: 'novel-1',
      novelTitle: 'Echoes of Eternity',
      tag: 'drafting',
    ),
    const SearchResultItem(
      id: 'char-1',
      type: SearchResultType.character,
      title: 'Aria Vance',
      subtitle: 'in Echoes of Eternity · Protagonist',
      snippet: 'Goal: Discover the truth behind the lost kingdom.',
      novelId: 'novel-1',
      novelTitle: 'Echoes of Eternity',
      tag: 'Protagonist',
    ),
    const SearchResultItem(
      id: 'lore-1',
      type: SearchResultType.lore,
      title: 'Valoria Kingdom',
      subtitle: 'in Echoes of Eternity · Kingdoms & Cities',
      snippet: 'An ancient mountain citadel known for its arcane gates.',
      novelId: 'novel-1',
      novelTitle: 'Echoes of Eternity',
      tag: 'Kingdoms & Cities',
    ),
    const SearchResultItem(
      id: 'event-1',
      type: SearchResultType.event,
      title: 'The Great Eclipse of 1042',
      subtitle: 'in Echoes of Eternity · Year 1042',
      snippet: 'The cosmic phenomenon that shattered the magical barrier.',
      novelId: 'novel-1',
      novelTitle: 'Echoes of Eternity',
      tag: 'Timeline',
    ),
  ];

  Widget buildSubject({
    List<SearchResultItem>? items,
  }) {
    final repo = _FakeSearchRepository(items ?? testItems);

    return ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        novelListStreamProvider.overrideWith(
          (ref) => Stream.value(<NovelModel>[]),
        ),
        activeNovelProvider.overrideWithValue(
          const AsyncValue.data(null),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
  }

  group('Global Search Tests', () {
    test('SearchRepository finds chapters, characters, lore, and novels',
        () async {
      final repo = _FakeSearchRepository(testItems);

      // Search by character name
      final charResults = await repo.search(query: 'Aria');
      expect(charResults.length, 2); // Chapter 1 snippet mentions Aria, plus Aria Vance character
      expect(charResults.any((r) => r.type == SearchResultType.character), isTrue);
      expect(charResults.any((r) => r.type == SearchResultType.chapter), isTrue);

      // Search by lore
      final loreResults = await repo.search(query: 'Valoria');
      expect(loreResults.length, 1);
      expect(loreResults.first.type, SearchResultType.lore);
      expect(loreResults.first.title, 'Valoria Kingdom');

      // Search by chapter title
      final chapterResults = await repo.search(query: 'Awakening');
      expect(chapterResults.length, 1);
      expect(chapterResults.first.type, SearchResultType.chapter);

      // Search matching novel IDs
      final matchedIds = await repo.searchMatchingNovelIds('Valoria');
      expect(matchedIds, contains('novel-1'));
    });

    testWidgets(
        'Typing query in HomeScreen reveals multi-entity results with badges',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Find search TextField
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search query that matches multiple categories
      await tester.enterText(searchField, 'Eternity');
      await tester.pumpAndSettle();

      // Should display search results header
      expect(find.textContaining('Search Results'), findsOneWidget);

      // Verify category badges and items rendered
      expect(find.text('NOVEL'), findsOneWidget);
      expect(find.text('CHAPTER'), findsOneWidget);
      expect(find.text('CHARACTER'), findsOneWidget);
      expect(find.text('LORE'), findsOneWidget);
      expect(find.text('TIMELINE'), findsOneWidget);

      // Verify titles
      expect(find.text('Echoes of Eternity'), findsOneWidget);
      expect(find.text('Chapter 1: The Awakening'), findsOneWidget);
      expect(find.text('Aria Vance'), findsOneWidget);
      expect(find.text('Valoria Kingdom'), findsOneWidget);
    });

    testWidgets('Tapping category filter chip filters results', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Eternity');
      await tester.pumpAndSettle();

      // Filter chips should be present
      expect(find.textContaining('Lore'), findsWidgets);
      expect(find.textContaining('Characters'), findsWidgets);

      // Tap Characters chip
      await tester.tap(find.textContaining('Characters'));
      await tester.pumpAndSettle();

      // Should only show Character results
      expect(find.text('Aria Vance'), findsOneWidget);
      expect(find.text('NOVEL'), findsNothing);
      expect(find.text('LORE'), findsNothing);
    });

    testWidgets('Empty search shows helpful empty state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'nonexistentquery123');
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(
        find.textContaining('No novels, chapters, lore, or characters match'),
        findsOneWidget,
      );
    });

    testWidgets('Clear button resets search query', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Aria');
      await tester.pumpAndSettle();

      expect(find.textContaining('Search Results'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Search results header should disappear
      expect(find.textContaining('Search Results'), findsNothing);
    });
  });
}
