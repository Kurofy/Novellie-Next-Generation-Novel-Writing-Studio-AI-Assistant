import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/characters/application/character_providers.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';
import 'package:novellie/features/characters/presentation/screens/character_detail_screen.dart';
import 'package:novellie/features/characters/presentation/widgets/character_avatar.dart';
import 'package:novellie/features/tools/application/family_tree_providers.dart';
import 'package:novellie/features/tools/data/repositories/family_tree_repository.dart';
import 'package:novellie/features/tools/domain/models/family_tree_models.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required String characterId,
    CharacterModel? character,
    List<CharacterRelationshipModel>? relationships,
    List<FamilyTree>? familyTrees,
    bool hasError = false,
  }) {
    return ProviderScope(
      overrides: [
        characterDetailStreamProvider(characterId).overrideWith((ref) {
          if (hasError) {
            return Stream.error(Exception('Failed to load character'));
          }
          return Stream.value(character);
        }),
        characterRelationshipsStreamProvider(characterId).overrideWith(
          (ref) => Stream.value(relationships ?? []),
        ),
        familyTreeRepositoryProvider.overrideWithValue(FamilyTreeRepository(null)),
        if (character != null)
          familyTreesProvider(character.novelId).overrideWith(
            (ref) => _FakeFamilyTreesNotifier(familyTrees ?? []),
          ),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CharacterDetailScreen(
          characterId: characterId,
        ),
      ),
    );
  }

  testWidgets(
      'CharacterDetailScreen renders successfully when portraitPath is null without blank screen or crash',
      (tester) async {
    final now = DateTime.now().toUtc();
    final character = CharacterModel(
      id: 'char-1',
      novelId: 'novel-1',
      name: 'Johnathan Doe',
      nickname: 'Johnny',
      role: CharacterRole.protagonist,
      gender: 'male',
      race: 'Human',
      portraitPath: null,
      goal: 'Find the truth',
      flaw: 'Too trusting',
      fear: 'Drowning',
      secret: 'Stole a pocket watch',
      appearance: 'Tall with dark hair',
      backstory: 'Grew up on a farm',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      buildTestWidget(characterId: 'char-1', character: character),
    );
    await tester.pumpAndSettle();

    // Verify header and character details are displayed
    expect(find.text('Johnathan Doe'), findsWidgets);
    expect(find.text('"Johnny"'), findsOneWidget);
    expect(find.text('Protagonist'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Human'), findsOneWidget);

    // Verify fields are present
    expect(find.text('Find the truth'), findsOneWidget);
    expect(find.text('Too trusting'), findsOneWidget);
    expect(find.text('Drowning'), findsOneWidget);
    expect(find.text('Stole a pocket watch'), findsOneWidget);
    expect(find.text('Tall with dark hair'), findsOneWidget);
    expect(find.text('Grew up on a farm'), findsOneWidget);

    // Verify initials avatar placeholder is displayed (J for Johnathan)
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets(
      'CharacterDetailScreen displays gender and race badges and adaptive avatar colors',
      (tester) async {
    final now = DateTime.now().toUtc();
    final femaleElf = CharacterModel(
      id: 'char-2',
      novelId: 'novel-1',
      name: 'Sylvia Silverleaf',
      role: CharacterRole.supporting,
      gender: 'female',
      race: 'Elf',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      buildTestWidget(characterId: 'char-2', character: femaleElf),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sylvia Silverleaf'), findsWidgets);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Elf'), findsOneWidget);
    expect(find.byType(CharacterAvatar), findsWidgets);
  });

  testWidgets(
      'CharacterDetailScreen previews immediate family members when connected to Family Tree',
      (tester) async {
    final now = DateTime.now().toUtc();
    final protagonist = CharacterModel(
      id: 'char-hero',
      novelId: 'novel-lineage',
      name: 'Arthur Pendragon',
      role: CharacterRole.protagonist,
      gender: 'male',
      race: 'Human',
      createdAt: now,
      updatedAt: now,
    );

    final familyTree = FamilyTree(
      id: 'tree-1',
      novelId: 'novel-lineage',
      name: 'House of Pendragon',
      description: 'Royal Dynasty of Camelot',
      nodes: [
        const FamilyTreeNode(
          id: 'node-arthur',
          treeId: 'tree-1',
          characterId: 'char-hero',
          name: 'Arthur Pendragon',
          titleOrRole: 'High King',
          gender: 'male',
        ),
        const FamilyTreeNode(
          id: 'node-uther',
          treeId: 'tree-1',
          name: 'Uther Pendragon',
          titleOrRole: 'Former King',
          gender: 'male',
        ),
        const FamilyTreeNode(
          id: 'node-guinevere',
          treeId: 'tree-1',
          name: 'Guinevere',
          titleOrRole: 'Queen',
          gender: 'female',
        ),
      ],
      edges: [
        const FamilyTreeEdge(
          id: 'edge-1',
          treeId: 'tree-1',
          fromNodeId: 'node-uther',
          toNodeId: 'node-arthur',
          relationshipType: FamilyRelationshipType.parent,
        ),
        const FamilyTreeEdge(
          id: 'edge-2',
          treeId: 'tree-1',
          fromNodeId: 'node-arthur',
          toNodeId: 'node-guinevere',
          relationshipType: FamilyRelationshipType.spouse,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      buildTestWidget(
        characterId: 'char-hero',
        character: protagonist,
        familyTrees: [familyTree],
      ),
    );
    await tester.pumpAndSettle();

    // Verify family tree preview card is shown
    expect(find.text('Family Tree & Lineage'), findsOneWidget);
    expect(find.text('House of Pendragon'), findsOneWidget);
    expect(find.text('Immediate Family Preview'), findsOneWidget);
    expect(find.text('Uther Pendragon'), findsOneWidget);
    expect(find.text('Guinevere'), findsOneWidget);
    expect(find.text('View Full Lineage in Family Tree'), findsOneWidget);
  });

  testWidgets(
      'CharacterDetailScreen displays inter-character relationships',
      (tester) async {
    final now = DateTime.now().toUtc();
    final protagonist = CharacterModel(
      id: 'char-hero',
      novelId: 'novel-lineage',
      name: 'Arthur Pendragon',
      role: CharacterRole.protagonist,
      gender: 'male',
      race: 'Human',
      createdAt: now,
      updatedAt: now,
    );

    final relationship = CharacterRelationshipModel(
      id: 'rel-1',
      novelId: 'novel-lineage',
      characterAId: 'char-hero',
      characterBId: 'char-lancelot',
      targetCharacterName: 'Sir Lancelot',
      targetCharacterGender: 'male',
      type: 'Ally',
      customLabel: 'First Knight & Sworn Brother',
      description: 'Stands as the champion of the round table.',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      buildTestWidget(
        characterId: 'char-hero',
        character: protagonist,
        relationships: [relationship],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relationships'), findsOneWidget);
    expect(find.text('Sir Lancelot'), findsOneWidget);
    expect(find.text('First Knight & Sworn Brother'), findsOneWidget);
    expect(
      find.text('Stands as the champion of the round table.'),
      findsOneWidget,
    );
  });

  testWidgets('CharacterDetailScreen renders character not found state',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(characterId: 'non-existent', character: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Character Not Found'), findsOneWidget);
    expect(
        find.text('This character no longer exists in index.'), findsOneWidget,);
    expect(find.text('Go Back'), findsOneWidget);
  });

  testWidgets('CharacterDetailScreen renders error state when stream fails',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(characterId: 'error-char', hasError: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load character details'), findsOneWidget);
  });
}

class _FakeFamilyTreesNotifier
    extends StateNotifier<AsyncValue<List<FamilyTree>>>
    implements FamilyTreesNotifier {
  _FakeFamilyTreesNotifier(List<FamilyTree> trees)
      : super(AsyncValue.data(trees));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
