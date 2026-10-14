import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/app_theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/tools/application/mind_map_providers.dart';
import 'package:novellie/features/tools/data/repositories/mind_map_repository.dart';
import 'package:novellie/features/tools/domain/models/mind_map_models.dart';
import 'package:novellie/features/tools/presentation/screens/mind_map_screen.dart';
import 'package:novellie/features/tools/presentation/widgets/mind_map_node_widget.dart';

void main() {
  group('MindMap Models & Layout Algorithms', () {
    test('MindMapGraph json serialization and deserialization', () {
      const node1 = MindMapNode(
        id: 'node-1',
        novelId: 'novel-1',
        type: MindMapNodeType.storyArc,
        title: 'Hero\'s Journey',
        description: 'Departure from ordinary world',
        storyArcName: 'Act I',
        sequenceOrder: 1,
        x: 100,
        y: 100,
      );

      const node2 = MindMapNode(
        id: 'node-2',
        novelId: 'novel-1',
        type: MindMapNodeType.chapterOrder,
        title: 'Chapter 1: The Inciting Signal',
        sequenceOrder: 2,
        x: 350,
        y: 100,
      );

      const edge = MindMapEdge(
        id: 'edge-1',
        fromNodeId: 'node-1',
        toNodeId: 'node-2',
        type: MindMapConnectionType.leadsTo,
      );

      const graph = MindMapGraph(
        novelId: 'novel-1',
        nodes: [node1, node2],
        edges: [edge],
      );

      final json = graph.toJson();
      final restored = MindMapGraph.fromJson(json);

      expect(restored.novelId, equals('novel-1'));
      expect(restored.nodes.length, equals(2));
      expect(restored.edges.length, equals(1));
      expect(restored.nodes.first.title, equals('Hero\'s Journey'));
      expect(restored.nodes.first.type, equals(MindMapNodeType.storyArc));
      expect(restored.edges.first.type, equals(MindMapConnectionType.leadsTo));
    });

    test('autoOrganizeStoryFlow sequences nodes in chronological grid', () {
      final repo = MindMapRepository();

      final nodes = [
        const MindMapNode(
          id: 'beat-3',
          novelId: 'n1',
          title: 'Climax Battle',
          sequenceOrder: 3,
        ),
        const MindMapNode(
          id: 'beat-1',
          novelId: 'n1',
          title: 'Inciting Incident',
          sequenceOrder: 1,
        ),
        const MindMapNode(
          id: 'beat-2',
          novelId: 'n1',
          title: 'Midpoint Reversal',
          sequenceOrder: 2,
        ),
      ];

      final graph = MindMapGraph(
        novelId: 'n1',
        nodes: nodes,
      );

      final organized = repo.autoOrganizeStoryFlow(graph);

      final beat1 =
          organized.nodes.firstWhere((MindMapNode n) => n.id == 'beat-1');
      final beat2 =
          organized.nodes.firstWhere((MindMapNode n) => n.id == 'beat-2');
      final beat3 =
          organized.nodes.firstWhere((MindMapNode n) => n.id == 'beat-3');

      // beat-1 should be left of beat-2
      expect(beat1.x, lessThan(beat2.x));
      expect(beat2.x, lessThan(beat3.x));
    });

    test('autoOrganizeBrainstorm positions nodes radially around origin', () {
      final repo = MindMapRepository();

      final nodes = List.generate(
        5,
        (i) => MindMapNode(
          id: 'node-$i',
          novelId: 'n1',
          title: 'Brainstorm Idea $i',
          type: MindMapNodeType.brainstorm,
        ),
      );

      final graph = MindMapGraph(
        novelId: 'n1',
        nodes: nodes,
      );

      final organized = repo.autoOrganizeBrainstorm(graph);

      // Node 0 is center
      expect(organized.nodes.first.x, equals(700.0));
      expect(organized.nodes.first.y, equals(600.0));

      for (int i = 1; i < organized.nodes.length; i++) {
        final dx = organized.nodes[i].x - 700.0;
        final dy = organized.nodes[i].y - 600.0;
        final distanceSquared = (dx * dx) + (dy * dy);
        expect(distanceSquared, greaterThan(100.0));
      }
    });
  });

  group('MindMapNodeWidget UI Tests', () {
    testWidgets('renders node card with title and category badge',
        (tester) async {
      bool tapped = false;

      const node = MindMapNode(
        id: 'arc-1',
        novelId: 'novel-1',
        type: MindMapNodeType.storyArc,
        title: 'Fall of the Empire Arc',
        storyArcName: 'Act II B',
        sequenceOrder: 4,
        description: 'Treason within the imperial court',
        x: 50,
        y: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                MindMapNodeWidget(
                  node: node,
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

      expect(find.text('Fall of the Empire Arc'), findsOneWidget);
      expect(find.text('Story Arc'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('Act II B'), findsOneWidget);

      await tester.tap(find.text('Fall of the Empire Arc'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tapped, isTrue);
    });
  });

  group('MindMapScreen Navigation and Action Dock Tests', () {
    final testNovel = NovelModel(
      id: 'nov-1',
      title: 'Plot Chronicles',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const testNode = MindMapNode(
      id: 'node-1',
      novelId: 'nov-1',
      type: MindMapNodeType.storyArc,
      title: 'Act I Inciting Incident',
      x: 200,
      y: 200,
    );

    const testGraph = MindMapGraph(
      novelId: 'nov-1',
      nodes: [testNode],
      edges: [],
    );

    testWidgets(
        'Add Node FAB hides when node is selected so navigation dock (+Next Beat, +Sub-Arc) is not obscured',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          novelListStreamProvider.overrideWith((ref) => Stream.value([testNovel])),
          activeNovelIdProvider.overrideWith((ref) => testNovel.id),
          mindMapGraphProvider(testNovel.id).overrideWith(
              (ref) => _MockMindMapNotifier(testGraph),),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const MindMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no node is selected: FAB "Add Node" is visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Node'), findsNWidgets(2)); // FAB + filter toolbar button

      // Select the node
      container.read(selectedMindMapNodeIdProvider.notifier).state = 'node-1';
      await tester.pumpAndSettle();

      // FloatingActionButton must be HIDDEN so it doesn't cover the dock
      expect(find.byType(FloatingActionButton), findsNothing);

      // Quick action navigation dock is fully displayed and unobstructed
      expect(find.text('+ Next Beat'), findsOneWidget);
      expect(find.text('+ Sub-Arc'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);

      // Deselect node
      container.read(selectedMindMapNodeIdProvider.notifier).state = null;
      await tester.pumpAndSettle();

      // Dock is gone and FAB returns
      expect(find.text('+ Next Beat'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}

class _FakeMindMapRepository extends Fake implements MindMapRepository {
  final MindMapGraph _graph;
  _FakeMindMapRepository(this._graph);

  @override
  Future<MindMapGraph> loadGraph(String novelId) async => _graph;
}

class _MockMindMapNotifier extends MindMapNotifier {
  _MockMindMapNotifier(MindMapGraph graph)
      : super(_FakeMindMapRepository(graph), 'nov-1') {
    state = AsyncValue.data(graph);
  }
}
