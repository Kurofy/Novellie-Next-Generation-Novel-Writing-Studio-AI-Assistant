import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/characters/application/character_providers.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';
import 'package:novellie/features/characters/presentation/screens/character_list_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required List<CharacterModel> characters,
    bool hasError = false,
  }) {
    return ProviderScope(
      overrides: [
        charactersStreamProvider('novel-1').overrideWith((ref) {
          if (hasError) {
            return Stream.error(Exception('Failed query'));
          }
          return Stream.value(characters);
        }),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CharacterListScreen(
          novelId: 'novel-1',
          showAppBar: false,
        ),
      ),
    );
  }

  testWidgets('CharacterListScreen renders empty state when no characters', (tester) async {
    await tester.pumpWidget(buildTestWidget(characters: []));
    await tester.pumpAndSettle();

    expect(find.text('No characters yet'), findsOneWidget);
    expect(find.text('Create Character'), findsOneWidget);
  });

  testWidgets('CharacterListScreen renders character cards when characters exist', (tester) async {
    final now = DateTime.now().toUtc();
    final chars = [
      CharacterModel(
        id: 'c1',
        novelId: 'novel-1',
        name: 'Arthur Pendragon',
        role: CharacterRole.protagonist,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(buildTestWidget(characters: chars));
    await tester.pumpAndSettle();

    expect(find.text('Arthur Pendragon'), findsOneWidget);
    expect(find.text('Protagonist'), findsAtLeastNWidgets(1));
    expect(find.text('Add Character'), findsOneWidget);
  });
}
