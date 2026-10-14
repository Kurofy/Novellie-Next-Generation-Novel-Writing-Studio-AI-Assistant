import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:novellie/core/theme/app_theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/tools/application/family_tree_providers.dart';
import 'package:novellie/features/tools/data/repositories/family_tree_repository.dart';
import 'package:novellie/features/tools/domain/models/family_tree_models.dart';
import 'package:novellie/features/tools/presentation/screens/family_tree_screen.dart';
import 'package:novellie/features/tools/presentation/widgets/family_tree_node_widget.dart';
import 'package:novellie/features/tools/presentation/widgets/family_tree_outline_view.dart';
import 'package:novellie/features/tools/presentation/widgets/family_tree_summary_dialog.dart';

void main() {
  group('FamilyTree Models & Multi-Tree Lineage Algorithms', () {
    test('FamilyTree json serialization and deserialization', () {
      final now = DateTime.now();

      const member1 = FamilyTreeNode(
        id: 'mem-1',
        treeId: 'tree-1',
        name: 'Lord Corlys',
        titleOrRole: 'Patriarch',
        generation: 0,
        years: '1020 - 1088',
        x: 100,
        y: 100,
      );

      const member2 = FamilyTreeNode(
        id: 'mem-2',
        treeId: 'tree-1',
        name: 'Princess Rhaenys',
        titleOrRole: 'The Queen Who Never Was',
        generation: 0,
        x: 350,
        y: 100,
      );

      const member3 = FamilyTreeNode(
        id: 'mem-3',
        treeId: 'tree-1',
        name: 'Laena Velaryon',
        titleOrRole: 'Heir',
        generation: 1,
        x: 220,
        y: 280,
      );

      const edgeMarriage = FamilyTreeEdge(
        id: 'edge-1',
        treeId: 'tree-1',
        fromNodeId: 'mem-1',
        toNodeId: 'mem-2',
        relationshipType: FamilyRelationshipType.spouse,
        isBidirectional: true,
      );

      const edgeParent = FamilyTreeEdge(
        id: 'edge-2',
        treeId: 'tree-1',
        fromNodeId: 'mem-1',
        toNodeId: 'mem-3',
        relationshipType: FamilyRelationshipType.child,
      );

      final tree = FamilyTree(
        id: 'tree-1',
        novelId: 'novel-1',
        name: 'House Velaryon',
        description: 'The Sea Snake dynasty',
        rootCharacterId: 'char-corlys',
        nodes: [member1, member2, member3],
        edges: [edgeMarriage, edgeParent],
        createdAt: now,
        updatedAt: now,
      );

      final json = tree.toJson();
      final restored = FamilyTree.fromJson(json);

      expect(restored.id, equals('tree-1'));
      expect(restored.name, equals('House Velaryon'));
      expect(restored.nodes.length, equals(3));
      expect(restored.edges.length, equals(2));
      expect(restored.nodes.first.name, equals('Lord Corlys'));
      expect(
        restored.edges.first.relationshipType,
        equals(FamilyRelationshipType.spouse),
      );
    });

    test('autoOrganizeTree arranges generations hierarchically', () {
      final repo = FamilyTreeRepository();
      final now = DateTime.now();

      final tree = FamilyTree(
        id: 'tree-stark',
        novelId: 'novel-1',
        name: 'House Stark',
        nodes: const [
          FamilyTreeNode(
            id: 'child',
            treeId: 'tree-stark',
            name: 'Robb Stark',
            generation: 1,
          ),
          FamilyTreeNode(
            id: 'parent',
            treeId: 'tree-stark',
            name: 'Eddard Stark',
            generation: 0,
          ),
          FamilyTreeNode(
            id: 'grandparent',
            treeId: 'tree-stark',
            name: 'Rickard Stark',
            generation: -1,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final organized = repo.autoOrganizeTree(tree);

      final grandParentNode =
          organized.nodes.firstWhere((FamilyTreeNode n) => n.id == 'grandparent');
      final parentNode =
          organized.nodes.firstWhere((FamilyTreeNode n) => n.id == 'parent');
      final childNode =
          organized.nodes.firstWhere((FamilyTreeNode n) => n.id == 'child');

      // Rickard (Gen -1) should be above Eddard (Gen 0)
      // Eddard (Gen 0) should be above Robb (Gen 1)
      expect(grandParentNode.y, lessThan(parentNode.y));
      expect(parentNode.y, lessThan(childNode.y));
    });
  });

  group('FamilyTreeNodeWidget UI Tests', () {
    testWidgets('renders lineage card with name, title, and generation badge',
        (tester) async {
      bool tapped = false;

      const member = FamilyTreeNode(
        id: 'mem-1',
        treeId: 't-1',
        name: 'Lady Genevieve',
        titleOrRole: 'High Matriarch',
        generation: 0,
        years: '1042 - 1105',
        status: 'alive',
        x: 40,
        y: 40,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                FamilyTreeNodeWidget(
                  node: member,
                  isSelected: true,
                  onTap: () => tapped = true,
                  onDoubleTap: () {},
                  onPanUpdate: (_) {},
                  onPanEnd: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Lady Genevieve'), findsOneWidget);
      expect(find.text('High Matriarch'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('1042 - 1105'), findsOneWidget);

      await tester.tap(find.text('Lady Genevieve'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tapped, isTrue);
    });
  });

  group('FamilyTreeSummaryDialog Tests', () {
    testWidgets('renders dynastic summary text with members and links',
        (tester) async {
      final now = DateTime.now();

      final tree = FamilyTree(
        id: 't-1',
        novelId: 'nov-1',
        name: 'Valerius Dynasty',
        nodes: const [
          FamilyTreeNode(
            id: 'n-1',
            treeId: 't-1',
            name: 'Emperor Valerius I',
            generation: 0,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: FamilyTreeSummaryDialog(
              tree: tree,
              novelTitle: 'Chronicles of Valerius',
            ),
          ),
        ),
      );

      expect(find.text('Valerius Dynasty Summary'), findsOneWidget);
      expect(find.text('Chronicles of Valerius'), findsOneWidget);
      expect(find.text('1 Members'), findsOneWidget);
    });
  });

  group('FamilyTreeScreen Navigation and Action Dock Tests', () {
    final testNovel = NovelModel(
      id: 'nov-1',
      title: 'Dynasty Chronicles',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testTree = FamilyTree(
      id: 'tree-1',
      novelId: 'nov-1',
      name: 'House Arryn',
      nodes: const [
        FamilyTreeNode(
          id: 'mem-1',
          treeId: 'tree-1',
          name: 'Jon Arryn',
          generation: 0,
          x: 200,
          y: 200,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets(
        'Add Member FAB hides when member is selected so navigation dock (+Child, +Spouse, +Parent) is not covered',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          novelListStreamProvider.overrideWith((ref) => Stream.value([testNovel])),
          activeNovelIdProvider.overrideWith((ref) => testNovel.id),
          familyTreesProvider(testNovel.id).overrideWith(
              (ref) => _MockFamilyTreesNotifier([testTree], ref),),
          currentFamilyTreeProvider(testNovel.id).overrideWith((ref) => testTree),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const FamilyTreeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no member is selected: FAB "Add Member" is visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Member'), findsNWidgets(2)); // FAB + toolbar button

      // Select the member
      container.read(selectedFamilyTreeNodeIdProvider.notifier).state = 'mem-1';
      await tester.pumpAndSettle();

      // FloatingActionButton must be HIDDEN so it doesn't cover the dock
      expect(find.byType(FloatingActionButton), findsNothing);

      // Quick action navigation dock is fully displayed and unobstructed
      expect(find.text('+ Child'), findsOneWidget);
      expect(find.text('+ Spouse'), findsOneWidget);
      expect(find.text('+ Parent'), findsOneWidget);
      expect(find.text('+ Sibling'), findsOneWidget);

      // Deselect member
      container.read(selectedFamilyTreeNodeIdProvider.notifier).state = null;
      await tester.pumpAndSettle();

      // Dock is gone and FAB returns
      expect(find.text('+ Child'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Switch to Dynasty Outline Mode using the segmented button
      expect(find.text('Dynasty Outline'), findsOneWidget);
      await tester.tap(find.text('Dynasty Outline'));
      await tester.pumpAndSettle();

      // Verify Outline view is active showing generations and member details
      expect(find.text('1 Members'), findsOneWidget);
      expect(find.text('Generation 0 — Founders & Progenitors'), findsOneWidget);
      expect(find.text('Jon Arryn'), findsOneWidget);
      expect(find.text('+ Add Relative'), findsOneWidget);
    });

    testWidgets(
        'Lineage navigation checklist button and search button have proper sizing and positioning',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          novelListStreamProvider
              .overrideWith((ref) => Stream.value([testNovel])),
          activeNovelIdProvider.overrideWith((ref) => testNovel.id),
          familyTreesProvider(testNovel.id).overrideWith(
              (ref) => _MockFamilyTreesNotifier([testTree], ref),),
          currentFamilyTreeProvider(testNovel.id)
              .overrideWith((ref) => testTree),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const FamilyTreeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check checklist button in lineage option navigation
      final checkIconFinder = find.byIcon(Symbols.check);
      expect(checkIconFinder, findsOneWidget);
      final checkIconWidget = tester.widget<Icon>(checkIconFinder);
      expect(checkIconWidget.size, equals(15));

      // Verify Dynasty Outline segment has checklist icon
      expect(find.byIcon(Symbols.checklist), findsOneWidget);

      // Verify search button position is clearly separated from novel title option
      final searchButtonFinder = find.byTooltip('Search Lineage');
      expect(searchButtonFinder, findsOneWidget);

      final novelTitleFinder = find.text(testNovel.title);
      expect(novelTitleFinder, findsOneWidget);

      final searchLeft = tester.getTopLeft(searchButtonFinder).dx;
      final novelRight = tester.getTopRight(novelTitleFinder).dx;

      // Ensure generous spacing exists between novel option dropdown and search button
      expect(searchLeft, greaterThan(novelRight + 16));
    });
  });

  group('FamilyTreeOutlineView & Pedigree Hierarchy Tests', () {
    testWidgets('renders generations, member relationship chips, and dynasty stats',
        (tester) async {
      final now = DateTime.now();

      const founder1 = FamilyTreeNode(
        id: 'f-1',
        treeId: 't-dynasty',
        name: 'Lord Corlys',
        titleOrRole: 'Lord of the Tides',
        generation: 0,
        years: '1020 - 1088',
        status: 'alive',
      );

      const founder2 = FamilyTreeNode(
        id: 'f-2',
        treeId: 't-dynasty',
        name: 'Princess Rhaenys',
        titleOrRole: 'The Queen Who Never Was',
        generation: 0,
        status: 'alive',
      );

      const heir = FamilyTreeNode(
        id: 'h-1',
        treeId: 't-dynasty',
        name: 'Laena Velaryon',
        titleOrRole: 'Dragonrider',
        generation: 1,
        status: 'alive',
      );

      const marriageEdge = FamilyTreeEdge(
        id: 'edge-m',
        treeId: 't-dynasty',
        fromNodeId: 'f-1',
        toNodeId: 'f-2',
        relationshipType: FamilyRelationshipType.spouse,
        isBidirectional: true,
      );

      const childEdge = FamilyTreeEdge(
        id: 'edge-c',
        treeId: 't-dynasty',
        fromNodeId: 'f-1',
        toNodeId: 'h-1',
        relationshipType: FamilyRelationshipType.child,
      );

      final tree = FamilyTree(
        id: 't-dynasty',
        novelId: 'nov-1',
        name: 'House Velaryon',
        nodes: const [founder1, founder2, heir],
        edges: const [marriageEdge, childEdge],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: FamilyTreeOutlineView(
                tree: tree,
                novelId: 'nov-1',
                onSelectNode: (_) {},
                onFocusOnCanvas: (_) {},
                onAddMember: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header stats strip
      expect(find.text('3 Members'), findsOneWidget);
      expect(find.text('2 Gen (Gen 0 to +1)'), findsOneWidget);
      expect(find.text('1 Unions'), findsOneWidget);

      // Generation Headers
      expect(find.text('Generation 0 — Founders & Progenitors'), findsOneWidget);
      expect(find.text('Generation +1 — Descendants & Heirs'), findsOneWidget);

      // Members displayed
      expect(find.text('Lord Corlys'), findsOneWidget);
      expect(find.text('Princess Rhaenys'), findsOneWidget);
      expect(find.text('Laena Velaryon'), findsOneWidget);

      // Relationship chips
      expect(find.text('Spouse: Princess Rhaenys'), findsOneWidget);
      expect(find.text('Children (1): Laena Velaryon'), findsOneWidget);
    });
  });

  group('FamilyTree Starter Dynasty Templates', () {
    test('applyStarterTemplate creates solo, couple, and dynasty templates correctly',
        () async {
      final fakeRepo = _FakeFamilyTreeRepository([]);
      final container = ProviderContainer(
        overrides: [
          familyTreeRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      final notifier = container.read(familyTreesProvider('nov-test').notifier);

      // Create an empty tree
      final tree = await notifier.createTree(name: 'House Targaryen');
      expect(tree.nodes, isEmpty);

      // Apply 'couple' template
      await notifier.applyStarterTemplate(
        tree.id,
        'couple',
        rootName: 'Aegon I',
        consortName: 'Visenya',
      );

      final trees = container.read(familyTreesProvider('nov-test')).value!;
      final updatedTree = trees.firstWhere((t) => t.id == tree.id);

      expect(updatedTree.nodes.length, equals(2));
      expect(updatedTree.edges.length, equals(1));
      expect(updatedTree.nodes.any((n) => n.name == 'Aegon I'), isTrue);
      expect(updatedTree.nodes.any((n) => n.name == 'Visenya'), isTrue);
      expect(
        updatedTree.edges.first.relationshipType,
        equals(FamilyRelationshipType.spouse),
      );
    });
  });
}

class _FakeFamilyTreeRepository extends Fake implements FamilyTreeRepository {
  List<FamilyTree> _trees;
  _FakeFamilyTreeRepository(this._trees);

  @override
  Future<List<FamilyTree>> loadTrees(String novelId) async => _trees;

  @override
  Future<FamilyTree> createTree({
    required String novelId,
    required String name,
    String? description,
    String? rootCharacterId,
    String? rootCharacterName,
    String? rootRole,
    String? rootGender,
    String? rootAvatarPath,
  }) async {
    final tree = FamilyTree(
      id: 'tree-created',
      novelId: novelId,
      name: name,
      nodes: const [],
      edges: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _trees = [..._trees, tree];
    return tree;
  }

  @override
  Future<void> saveTrees(String novelId, List<FamilyTree> trees) async {
    _trees = trees;
  }
}

class _MockFamilyTreesNotifier extends FamilyTreesNotifier {
  _MockFamilyTreesNotifier(List<FamilyTree> trees, Ref ref)
      : super(_FakeFamilyTreeRepository(trees), 'nov-1', ref) {
    state = AsyncValue.data(trees);
  }
}
