import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/mind_map_repository.dart';
import '../domain/models/mind_map_models.dart';

final mindMapRepositoryProvider = Provider<MindMapRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MindMapRepository(db);
});

final selectedMindMapNodeIdProvider = StateProvider<String?>((ref) => null);
final selectedMindMapEdgeIdProvider = StateProvider<String?>((ref) => null);
final mindMapSearchQueryProvider = StateProvider<String>((ref) => '');
final mindMapTypeFilterProvider = StateProvider<MindMapNodeType?>((ref) => null);

final mindMapGraphProvider = StateNotifierProvider.family<MindMapNotifier,
    AsyncValue<MindMapGraph>, String>((ref, novelId) {
  final repo = ref.watch(mindMapRepositoryProvider);
  return MindMapNotifier(repo, novelId);
});

class MindMapNotifier extends StateNotifier<AsyncValue<MindMapGraph>> {
  final MindMapRepository _repo;
  final String novelId;

  MindMapNotifier(this._repo, this.novelId)
      : super(const AsyncValue.loading()) {
    loadGraph();
  }

  Future<void> loadGraph() async {
    state = const AsyncValue.loading();
    try {
      final graph = await _repo.loadGraph(novelId);
      state = AsyncValue.data(graph);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNode(MindMapNode node) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      nodes: [...current.nodes, node],
    );
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> updateNode(MindMapNode node) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedNodes = current.nodes.map((n) {
      return n.id == node.id ? node : n;
    }).toList();

    final updated = current.copyWith(nodes: updatedNodes);
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> updateNodePosition(String nodeId, double x, double y,
      {bool save = true,}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedNodes = current.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(x: x, y: y) : n;
    }).toList();

    final updated = current.copyWith(nodes: updatedNodes);
    state = AsyncValue.data(updated);
    if (save) {
      await _repo.saveGraph(updated);
    }
  }

  Future<void> commitNodePositions() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _repo.saveGraph(current);
  }

  Future<void> removeNode(String nodeId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedNodes = current.nodes.where((n) => n.id != nodeId).toList();
    final updatedEdges = current.edges
        .where((e) => e.fromNodeId != nodeId && e.toNodeId != nodeId)
        .toList();

    final updated = current.copyWith(
      nodes: updatedNodes,
      edges: updatedEdges,
    );
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> addEdge(MindMapEdge edge) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Check duplicate
    final exists = current.edges.any((e) =>
        (e.fromNodeId == edge.fromNodeId && e.toNodeId == edge.toNodeId) ||
        (edge.isBidirectional &&
            e.fromNodeId == edge.toNodeId &&
            e.toNodeId == edge.fromNodeId),);
    if (exists) return;

    final updated = current.copyWith(
      edges: [...current.edges, edge],
    );
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> removeEdge(String edgeId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedEdges = current.edges.where((e) => e.id != edgeId).toList();
    final updated = current.copyWith(edges: updatedEdges);
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> addNodeAndEdge({
    required MindMapNode node,
    required MindMapEdge edge,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      nodes: [...current.nodes, node],
      edges: [...current.edges, edge],
    );
    state = AsyncValue.data(updated);
    await _repo.saveGraph(updated);
  }

  Future<void> autoOrganizeStoryFlow() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final organized = _repo.autoOrganizeStoryFlow(current);
    state = AsyncValue.data(organized);
    await _repo.saveGraph(organized);
  }

  Future<void> autoOrganizeBrainstorm() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final organized = _repo.autoOrganizeBrainstorm(current);
    state = AsyncValue.data(organized);
    await _repo.saveGraph(organized);
  }

  Future<void> clearGraph() async {
    final empty = MindMapGraph(
      novelId: novelId,
      nodes: [],
      edges: [],
    );
    state = AsyncValue.data(empty);
    await _repo.saveGraph(empty);
  }
}
