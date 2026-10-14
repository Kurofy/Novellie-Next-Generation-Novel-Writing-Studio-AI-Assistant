import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/characters/application/character_providers.dart';
import 'package:novellie/features/manuscript/application/manuscript_providers.dart';
import 'package:novellie/features/manuscript/domain/models/manuscript_models.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/novels/domain/repositories/novel_repository.dart';
import 'package:novellie/features/novels/presentation/screens/novel_workspace_screen.dart';
import 'package:novellie/features/world/application/world_providers.dart';
import 'package:novellie/l10n/app_localizations.dart';

class MockNovelRepository extends Mock implements NovelRepository {}

void main() {
  final testNovel = NovelModel(
    id: 'novel-1',
    title: 'Test Novel',
    status: NovelStatus.drafting,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockRepo = MockNovelRepository();
  when(() => mockRepo.updateLastOpened(any())).thenAnswer((_) async {});

  Widget createSubject({
    required String novelId,
    AsyncValue<NovelModel?>? novelOverride,
  }) {
    return ProviderScope(
      overrides: [
        novelRepositoryProvider.overrideWithValue(mockRepo),
        if (novelOverride != null)
          novelDetailStreamProvider(novelId).overrideWith(
            (ref) => novelOverride.when(
              data: (d) => Stream.value(d),
              error: (e, st) => Stream.error(e, st),
              loading: () => const Stream.empty(),
            ),
          )
        else
          novelDetailStreamProvider(novelId).overrideWith(
            (ref) => Stream.value(testNovel),
          ),
        chaptersStreamProvider(novelId).overrideWith(
          (ref) => Stream.value(<ChapterModel>[]),
        ),
        charactersStreamProvider(novelId).overrideWith(
          (ref) => Stream.value([]),
        ),
        worldCategoriesStreamProvider(novelId).overrideWith(
          (ref) => Stream.value([]),
        ),
        worldEntriesStreamProvider((novelId: novelId, categoryId: null))
            .overrideWith(
          (ref) => Stream.value([]),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NovelWorkspaceScreen(novelId: novelId),
      ),
    );
  }

  testWidgets('NovelWorkspaceScreen renders with data and popup menu',
      (tester) async {
    await tester.pumpWidget(createSubject(novelId: 'novel-1'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Test Novel'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('NovelWorkspaceScreen handles not-found novel fallback cleanly',
      (tester) async {
    await tester.pumpWidget(
      createSubject(
        novelId: 'non-existent',
        novelOverride: const AsyncValue.data(null),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Not Found'), findsOneWidget);
    expect(find.text('Back to Library'), findsOneWidget);
  });

  testWidgets('NovelWorkspaceScreen handles empty ID fallback cleanly',
      (tester) async {
    await tester.pumpWidget(createSubject(novelId: ''));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Invalid novel ID.'), findsOneWidget);
    expect(find.text('Back to Library'), findsOneWidget);
  });

  testWidgets('NovelWorkspaceScreen handles error state with retry cleanly',
      (tester) async {
    await tester.pumpWidget(
      createSubject(
        novelId: 'novel-error',
        novelOverride: AsyncValue.error(
          Exception('Database disk full'),
          StackTrace.empty,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Failed to load novel'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
