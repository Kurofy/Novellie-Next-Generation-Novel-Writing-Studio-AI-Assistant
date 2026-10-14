import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/novels/domain/repositories/novel_repository.dart';
import 'package:novellie/features/novels/presentation/screens/create_novel_screen.dart';
import 'package:novellie/features/novels/presentation/screens/edit_novel_dialog.dart';
import 'package:novellie/features/novels/presentation/screens/novel_library_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

class MockNovelRepository extends Mock implements NovelRepository {}

class FakeNovelModel extends Fake implements NovelModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNovelModel());
  });

  final testNovel = NovelModel(
    id: 'novel-1',
    title: 'Original Title',
    subtitle: 'Original Subtitle',
    genre: 'Fantasy',
    description: 'Original synopsis',
    status: NovelStatus.drafting,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('CreateNovelScreen shows custom genre "+" button and adds custom genre',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockNovelRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          novelRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CreateNovelScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Add Cover is displayed
    expect(find.text('Add Cover'), findsOneWidget);

    // Verify Custom genre chip is displayed
    expect(find.text('Custom'), findsOneWidget);

    // Tap the Custom genre chip
    await tester.ensureVisible(find.text('Custom'));
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Add Custom Genre'), findsOneWidget);

    // Enter a new genre
    await tester.enterText(find.byType(TextField).last, 'Cyberpunk');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // The new genre chip should be in the list
    expect(find.text('Cyberpunk'), findsOneWidget);
  });

  testWidgets('EditNovelDialog displays fields and saves changes',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockNovelRepository();
    when(() => mockRepo.updateNovel(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          novelRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditNovelDialog.show(ctx, testNovel),
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Novel Details'), findsOneWidget);
    expect(find.text('Original Title'), findsOneWidget);

    // Change title
    await tester.enterText(find.widgetWithText(TextField, 'Original Title'), 'Updated Title');

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.updateNovel(
        any(
          that: isA<NovelModel>().having(
            (m) => m.title,
            'title',
            'Updated Title',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('NovelLibraryScreen ":" menu shows Edit Details and Delete options',
      (tester) async {
    final mockRepo = MockNovelRepository();
    when(() => mockRepo.watchNovels()).thenAnswer((_) => Stream.value([testNovel]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          novelRepositoryProvider.overrideWithValue(mockRepo),
          novelListStreamProvider.overrideWith((ref) => Stream.value([testNovel])),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NovelLibraryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap more_vert button on the novel card
    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();

    // Verify popup menu items
    expect(find.text('Edit Details'), findsOneWidget);
    expect(find.text('Delete Novel'), findsOneWidget);
  });

  testWidgets('EditNovelDialog supports selecting multiple genres', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final multiGenreNovel = testNovel.copyWith(genre: 'Fantasy, Sci-Fi');
    final mockRepo = MockNovelRepository();
    when(() => mockRepo.updateNovel(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          novelRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditNovelDialog.show(ctx, multiGenreNovel),
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Edit'));
    await tester.pumpAndSettle();

    // Tap another genre to add it (e.g., Mystery)
    await tester.ensureVisible(find.text('Mystery'));
    await tester.tap(find.text('Mystery'));
    await tester.pumpAndSettle();

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.updateNovel(
        any(
          that: isA<NovelModel>().having(
            (m) => m.genre,
            'genre',
            contains('Mystery'),
          ),
        ),
      ),
    ).called(1);
  });
}
