import 'dart:convert';
import 'dart:math' as math;
import '../../../../core/database/app_database.dart';
import '../../domain/models/mind_map_models.dart';

class MindMapRepository {
  final AppDatabase? _db;

  MindMapRepository([this._db]);

  String _graphKey(String novelId) => 'mindmap_story_graph_$novelId';
  String _legacyKey(String novelId) => 'mindmap_graph_$novelId';

  Future<MindMapGraph> loadGraph(String novelId) async {
    final db = _db;
    if (db == null) {
      return MindMapGraph(
        novelId: novelId,
        nodes: [],
        edges: [],
      );
    }

    final key = _graphKey(novelId);
    try {
      final row = await (db.select(db.appSettings)
            ..where((tbl) => tbl.key.equals(key)))
          .getSingleOrNull();

      if (row != null && row.value.isNotEmpty) {
        final decoded = jsonDecode(row.value) as Map<String, dynamic>;
        return MindMapGraph.fromJson(decoded);
      }
    } catch (_) {}

    // Fallback: Check legacy key if exists
    try {
      final legacyRow = await (db.select(db.appSettings)
            ..where((tbl) => tbl.key.equals(_legacyKey(novelId))))
          .getSingleOrNull();

      if (legacyRow != null && legacyRow.value.isNotEmpty) {
        final decoded = jsonDecode(legacyRow.value) as Map<String, dynamic>;
        final graph = MindMapGraph.fromJson(decoded);
        return graph;
      }
    } catch (_) {}

    // Return empty default graph
    return MindMapGraph(
      novelId: novelId,
      nodes: [],
      edges: [],
    );
  }

  Future<void> saveGraph(MindMapGraph graph) async {
    final db = _db;
    if (db == null) return;

    final key = _graphKey(graph.novelId);
    final jsonStr = jsonEncode(graph.toJson());
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonStr,
            updatedAt: now,
          ),
        );
  }

  /// Auto-organizes the Story Sequence & Narrative Flow in chronological order
  MindMapGraph autoOrganizeStoryFlow(MindMapGraph graph) {
    if (graph.nodes.isEmpty) return graph;

    const double nodeWidth = 240.0;
    const double nodeHeight = 120.0;
    const double colSpacing = 100.0;
    const double rowSpacing = 80.0;
    const double startX = 160.0;
    const double startY = 160.0;

    // Group nodes by story arc name if available, otherwise sort by sequenceOrder
    final sortedNodes = List<MindMapNode>.from(graph.nodes);
    sortedNodes.sort((a, b) {
      final seqA = a.sequenceOrder ?? 999;
      final seqB = b.sequenceOrder ?? 999;
      if (seqA != seqB) return seqA.compareTo(seqB);
      return a.type.index.compareTo(b.type.index);
    });

    final List<MindMapNode> updatedNodes = [];
    int col = 0;
    int row = 0;
    const int maxCols = 4;

    for (int i = 0; i < sortedNodes.length; i++) {
      final node = sortedNodes[i];
      final x = startX + col * (nodeWidth + colSpacing);
      final y = startY + row * (nodeHeight + rowSpacing);
      updatedNodes.add(node.copyWith(x: x, y: y));

      col++;
      if (col >= maxCols) {
        col = 0;
        row++;
      }
    }

    return graph.copyWith(nodes: updatedNodes);
  }

  /// Auto-organizes Brainstorming & Ideation nodes in a radial constellation
  MindMapGraph autoOrganizeBrainstorm(MindMapGraph graph) {
    if (graph.nodes.isEmpty) return graph;

    const double centerX = 700.0;
    const double centerY = 600.0;

    if (graph.nodes.length == 1) {
      return graph.copyWith(
        nodes: [graph.nodes.first.copyWith(x: centerX, y: centerY)],
      );
    }

    // Center theme or first node
    final List<MindMapNode> updatedNodes = [];
    final centerNode = graph.nodes.first.copyWith(x: centerX, y: centerY);
    updatedNodes.add(centerNode);

    final remainingNodes = graph.nodes.sublist(1);
    final count = remainingNodes.length;

    final double radius = math.max(280.0, count * 40.0);
    final double angleStep = (2 * math.pi) / count;

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      updatedNodes.add(remainingNodes[i].copyWith(x: x, y: y));
    }

    return graph.copyWith(nodes: updatedNodes);
  }
}
