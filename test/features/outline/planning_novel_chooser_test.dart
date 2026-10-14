import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/outline/application/planning_providers.dart';
import 'package:novellie/features/outline/domain/models/planning_models.dart';
import 'package:novellie/features/outline/presentation/screens/planning_hub_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final novel1 = NovelModel(
    id: 'novel-1',
    title: 'Echoes of Eternity',
    genre: 'Fantasy',
    status: NovelStatus.drafting,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final novel2 = NovelModel(
    id: 'novel-2',
    title: 'The Cyber Chronicles',
    genre: 'Sci-Fi',
    status: NovelStatus.planning,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildSubject({
    List<NovelModel> novels = const [],
    NovelModel? activeNovel,
    Override? activeIdOverride,
  }) {
    return ProviderScope(
      overrides: [
        novelListStreamProvider.overrideWith(
          (ref) => Stream.value(novels),
        ),
        activeNovelProvider.overrideWithValue(
          AsyncValue.data(activeNovel),
        ),
        timelineEventsStreamProvider('novel-1').overrideWith(
          (ref) => Stream.value(<TimelineEventModel>[]),
        ),
        timelineEventsStreamProvider('novel-2').overrideWith(
          (ref) => Stream.value(<TimelineEventModel>[]),
        ),
        sceneCardsStreamProvider(
          (novelId: 'novel-1', chapterId: null),
        ).overrideWith(
          (ref) => Stream.value(<SceneCardModel>[]),
        ),
        sceneCardsStreamProvider(
          (novelId: 'novel-2', chapterId: null),
        ).overrideWith(
          (ref) => Stream.value(<SceneCardModel>[]),
        ),
        if (activeIdOverride != null) activeIdOverride,
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PlanningHubScreen(),
      ),
    );
  }

  group('PlanningHubScreen Novel Chooser Navigation Tests', () {
    testWidgets(
        'Renders active novel title, dropdown chevron, and Choose Novel action button',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          novels: [novel1, novel2],
          activeNovel: novel1,
        ),
      );
      await tester.pumpAndSettle();

      // Verify active novel title and Planning Hub label in AppBar navigation
      expect(find.text('Echoes of Eternity'), findsOneWidget);
      expect(find.text('Planning Hub'), findsOneWidget);

      // Verify dropdown arrow indicator
      expect(find.byIcon(Symbols.arrow_drop_down), findsOneWidget);

      // Verify Choose Novel action button in AppBar
      expect(find.byTooltip('Choose Novel'), findsOneWidget);
    });

    testWidgets('Tapping Choose Novel action opens bottom sheet with novels',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          novels: [novel1, novel2],
          activeNovel: novel1,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Choose Novel icon button in AppBar
      await tester.tap(find.byTooltip('Choose Novel'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title
      expect(find.text('Choose Novel'), findsOneWidget);
      expect(
        find.text('Select which novel to plan and outline'),
        findsOneWidget,
      );

      // Verify both novels are listed
      expect(find.text('Echoes of Eternity'), findsNWidgets(2)); // in bar and sheet
      expect(find.text('The Cyber Chronicles'), findsOneWidget);

      // Verify active indicator
      expect(find.text('Active'), findsOneWidget);

      // Verify Create New Novel button is present
      expect(find.text('Create New Novel'), findsOneWidget);
    });

    testWidgets('Tapping novel title in AppBar also opens novel picker sheet',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          novels: [novel1, novel2],
          activeNovel: novel1,
        ),
      );
      await tester.pumpAndSettle();

      // Tap active novel title
      await tester.tap(find.text('Echoes of Eternity'));
      await tester.pumpAndSettle();

      // Verify picker opened
      expect(find.text('Choose Novel'), findsOneWidget);
      expect(find.text('The Cyber Chronicles'), findsOneWidget);
    });

    testWidgets('Selecting a novel updates activeNovelIdProvider and dismisses sheet',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          novelListStreamProvider.overrideWith(
            (ref) => Stream.value([novel1, novel2]),
          ),
          activeNovelProvider.overrideWithValue(
            AsyncValue.data(novel1),
          ),
          timelineEventsStreamProvider('novel-1').overrideWith(
            (ref) => Stream.value(<TimelineEventModel>[]),
          ),
          timelineEventsStreamProvider('novel-2').overrideWith(
            (ref) => Stream.value(<TimelineEventModel>[]),
          ),
          sceneCardsStreamProvider(
            (novelId: 'novel-1', chapterId: null),
          ).overrideWith(
            (ref) => Stream.value(<SceneCardModel>[]),
          ),
          sceneCardsStreamProvider(
            (novelId: 'novel-2', chapterId: null),
          ).overrideWith(
            (ref) => Stream.value(<SceneCardModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PlanningHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open novel chooser
      await tester.tap(find.byTooltip('Choose Novel'));
      await tester.pumpAndSettle();

      // Tap second novel
      await tester.tap(find.text('The Cyber Chronicles'));
      await tester.pumpAndSettle();

      // Verify state was updated to novel-2
      expect(container.read(activeNovelIdProvider), 'novel-2');

      // Verify sheet was dismissed
      expect(
        find.text('Select which novel to plan and outline'),
        findsNothing,
      );
    });

    testWidgets('Empty state offers Choose Novel when novels exist but none active',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          novels: [novel1, novel2],
          activeNovel: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select a Novel to Plan'), findsOneWidget);
      expect(find.text('Choose Novel'), findsWidgets);

      // Tap action button in empty state
      await tester.tap(find.text('Choose Novel').first);
      await tester.pumpAndSettle();

      // Picker opens
      expect(find.text('Select which novel to plan and outline'), findsOneWidget);
      expect(find.text('Echoes of Eternity'), findsOneWidget);
      expect(find.text('The Cyber Chronicles'), findsOneWidget);
    });
  });
}
