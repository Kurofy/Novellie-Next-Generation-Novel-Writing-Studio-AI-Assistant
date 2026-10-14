import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/uuid_generator.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/family_tree_repository.dart';
import '../domain/models/family_tree_models.dart';

final familyTreeRepositoryProvider = Provider<FamilyTreeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FamilyTreeRepository(db);
});

final selectedFamilyTreeNodeIdProvider = StateProvider<String?>((ref) => null);
final selectedFamilyTreeEdgeIdProvider = StateProvider<String?>((ref) => null);
final familyTreeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tracks the active Family Tree ID for each novel.
final activeFamilyTreeIdProvider =
    StateProvider.family<String?, String>((ref, novelId) => null);

/// State notifier managing all family trees for a specific novel.
final familyTreesProvider = StateNotifierProvider.family<FamilyTreesNotifier,
    AsyncValue<List<FamilyTree>>, String>((ref, novelId) {
  final repo = ref.watch(familyTreeRepositoryProvider);
  return FamilyTreesNotifier(repo, novelId, ref);
});

/// Computes the currently active family tree for the novel.
final currentFamilyTreeProvider =
    Provider.family<FamilyTree?, String>((ref, novelId) {
  final treesAsync = ref.watch(familyTreesProvider(novelId));
  final activeId = ref.watch(activeFamilyTreeIdProvider(novelId));

  return treesAsync.when(
    data: (trees) {
      if (trees.isEmpty) return null;
      if (activeId != null) {
        final match = trees.where((t) => t.id == activeId).firstOrNull;
        if (match != null) return match;
      }
      return trees.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class FamilyTreesNotifier extends StateNotifier<AsyncValue<List<FamilyTree>>> {
  final FamilyTreeRepository _repo;
  final String novelId;
  final Ref _ref;

  FamilyTreesNotifier(this._repo, this.novelId, this._ref)
      : super(const AsyncValue.loading()) {
    loadTrees();
  }

  Future<void> loadTrees() async {
    state = const AsyncValue.loading();
    try {
      final trees = await _repo.loadTrees(novelId);
      state = AsyncValue.data(trees);

      final activeId = _ref.read(activeFamilyTreeIdProvider(novelId));
      if (trees.isNotEmpty &&
          (activeId == null || !trees.any((FamilyTree t) => t.id == activeId))) {
        _ref.read(activeFamilyTreeIdProvider(novelId).notifier).state =
            trees.first.id;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new distinct Family Tree and sets it as active.
  Future<FamilyTree> createTree({
    required String name,
    String? description,
    String? rootCharacterId,
    String? rootCharacterName,
    String? rootRole,
    String? rootGender,
    String? rootAvatarPath,
  }) async {
    final newTree = await _repo.createTree(
      novelId: novelId,
      name: name,
      description: description,
      rootCharacterId: rootCharacterId,
      rootCharacterName: rootCharacterName,
      rootRole: rootRole,
      rootGender: rootGender,
      rootAvatarPath: rootAvatarPath,
    );

    final currentTrees = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentTrees, newTree]);

    _ref.read(activeFamilyTreeIdProvider(novelId).notifier).state = newTree.id;
    _ref.read(selectedFamilyTreeNodeIdProvider.notifier).state =
        newTree.nodes.isNotEmpty ? newTree.nodes.first.id : null;

    return newTree;
  }

  Future<void> deleteTree(String treeId) async {
    await _repo.deleteTree(novelId, treeId);
    final currentTrees = state.valueOrNull ?? [];
    final updated = currentTrees.where((t) => t.id != treeId).toList();
    state = AsyncValue.data(updated);

    final activeId = _ref.read(activeFamilyTreeIdProvider(novelId));
    if (activeId == treeId) {
      _ref.read(activeFamilyTreeIdProvider(novelId).notifier).state =
          updated.isNotEmpty ? updated.first.id : null;
    }
  }

  Future<void> renameTree(String treeId, String newName) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedTree = tree.copyWith(name: newName);
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> addMember(String treeId, FamilyTreeNode node) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedTree = tree.copyWith(
      nodes: [...tree.nodes, node],
    );
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> updateMember(String treeId, FamilyTreeNode node) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedNodes =
        tree.nodes.map((n) => n.id == node.id ? node : n).toList();
    final updatedTree = tree.copyWith(nodes: updatedNodes);
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> removeMember(String treeId, String nodeId) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedNodes = tree.nodes.where((n) => n.id != nodeId).toList();
    final updatedEdges = tree.edges
        .where((e) => e.fromNodeId != nodeId && e.toNodeId != nodeId)
        .toList();

    final updatedTree = tree.copyWith(
      nodes: updatedNodes,
      edges: updatedEdges,
    );
    await _updateTreeLocallyAndPersist(updatedTree);

    if (_ref.read(selectedFamilyTreeNodeIdProvider) == nodeId) {
      _ref.read(selectedFamilyTreeNodeIdProvider.notifier).state = null;
    }
  }

  Future<void> addRelationship(String treeId, FamilyTreeEdge edge) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedTree = tree.copyWith(
      edges: [...tree.edges, edge],
    );
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> removeRelationship(String treeId, String edgeId) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedEdges = tree.edges.where((e) => e.id != edgeId).toList();
    final updatedTree = tree.copyWith(edges: updatedEdges);
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> addRelativeMemberAndEdge(
    String treeId, {
    required FamilyTreeNode node,
    required FamilyTreeEdge edge,
  }) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedTree = tree.copyWith(
      nodes: [...tree.nodes, node],
      edges: [...tree.edges, edge],
    );
    await _updateTreeLocallyAndPersist(updatedTree);
  }

  Future<void> updateMemberPosition(
    String treeId,
    String nodeId,
    double x,
    double y, {
    bool save = true,
  }) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final updatedNodes = tree.nodes
        .map((n) => n.id == nodeId ? n.copyWith(x: x, y: y) : n)
        .toList();
    final updatedTree = tree.copyWith(nodes: updatedNodes);

    final updatedList =
        currentTrees.map((t) => t.id == treeId ? updatedTree : t).toList();
    state = AsyncValue.data(updatedList);

    if (save) {
      await _repo.saveTrees(novelId, updatedList);
    }
  }

  Future<void> autoOrganize(String treeId) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final organized = _repo.autoOrganizeTree(tree);
    await _updateTreeLocallyAndPersist(organized);
  }

  /// Quickly populates an empty tree with a standard dynasty starter template.
  Future<void> applyStarterTemplate(
    String treeId,
    String templateType, {
    String? rootName,
    String? consortName,
    String? heirName,
  }) async {
    final currentTrees = state.valueOrNull ?? [];
    final tree = currentTrees.where((t) => t.id == treeId).firstOrNull;
    if (tree == null) return;

    final List<FamilyTreeNode> newNodes = [];
    final List<FamilyTreeEdge> newEdges = [];

    if (templateType == 'solo') {
      newNodes.add(
        FamilyTreeNode(
          id: generateUuid(),
          treeId: treeId,
          name: rootName ?? 'Founding Patriarch / Matriarch',
          titleOrRole: 'Founder',
          generation: 0,
          status: 'alive',
          x: 400.0,
          y: 260.0,
        ),
      );
    } else if (templateType == 'couple') {
      final id1 = generateUuid();
      final id2 = generateUuid();
      newNodes.addAll([
        FamilyTreeNode(
          id: id1,
          treeId: treeId,
          name: rootName ?? 'Lord Founder',
          titleOrRole: 'Patriarch',
          generation: 0,
          gender: 'male',
          status: 'alive',
          x: 280.0,
          y: 260.0,
        ),
        FamilyTreeNode(
          id: id2,
          treeId: treeId,
          name: consortName ?? 'Lady Consort',
          titleOrRole: 'Matriarch',
          generation: 0,
          gender: 'female',
          status: 'alive',
          x: 560.0,
          y: 260.0,
        ),
      ]);
      newEdges.add(
        FamilyTreeEdge(
          id: generateUuid(),
          treeId: treeId,
          fromNodeId: id1,
          toNodeId: id2,
          relationshipType: FamilyRelationshipType.spouse,
          isBidirectional: true,
        ),
      );
    } else if (templateType == 'dynasty') {
      final id1 = generateUuid();
      final id2 = generateUuid();
      final id3 = generateUuid();
      final id4 = generateUuid();
      newNodes.addAll([
        FamilyTreeNode(
          id: id1,
          treeId: treeId,
          name: rootName ?? 'Lord Founder',
          titleOrRole: 'Patriarch',
          generation: 0,
          gender: 'male',
          status: 'alive',
          x: 280.0,
          y: 120.0,
        ),
        FamilyTreeNode(
          id: id2,
          treeId: treeId,
          name: consortName ?? 'Lady Consort',
          titleOrRole: 'Matriarch',
          generation: 0,
          gender: 'female',
          status: 'alive',
          x: 560.0,
          y: 120.0,
        ),
        FamilyTreeNode(
          id: id3,
          treeId: treeId,
          name: heirName ?? 'Crown Heir',
          titleOrRole: 'Firstborn Heir',
          generation: 1,
          gender: 'male',
          status: 'alive',
          x: 420.0,
          y: 340.0,
        ),
        FamilyTreeNode(
          id: id4,
          treeId: treeId,
          name: 'Next Generation',
          titleOrRole: 'Grandchild',
          generation: 2,
          status: 'alive',
          x: 420.0,
          y: 560.0,
        ),
      ]);
      newEdges.addAll([
        FamilyTreeEdge(
          id: generateUuid(),
          treeId: treeId,
          fromNodeId: id1,
          toNodeId: id2,
          relationshipType: FamilyRelationshipType.spouse,
          isBidirectional: true,
        ),
        FamilyTreeEdge(
          id: generateUuid(),
          treeId: treeId,
          fromNodeId: id1,
          toNodeId: id3,
          relationshipType: FamilyRelationshipType.child,
        ),
        FamilyTreeEdge(
          id: generateUuid(),
          treeId: treeId,
          fromNodeId: id2,
          toNodeId: id3,
          relationshipType: FamilyRelationshipType.child,
        ),
        FamilyTreeEdge(
          id: generateUuid(),
          treeId: treeId,
          fromNodeId: id3,
          toNodeId: id4,
          relationshipType: FamilyRelationshipType.child,
        ),
      ]);
    }

    final updatedTree = tree.copyWith(
      nodes: [...tree.nodes, ...newNodes],
      edges: [...tree.edges, ...newEdges],
    );
    await _updateTreeLocallyAndPersist(updatedTree);
    if (newNodes.isNotEmpty) {
      _ref.read(selectedFamilyTreeNodeIdProvider.notifier).state = newNodes.first.id;
    }
  }

  Future<void> _updateTreeLocallyAndPersist(FamilyTree updatedTree) async {
    final currentTrees = state.valueOrNull ?? [];
    final updatedList = currentTrees
        .map((t) => t.id == updatedTree.id ? updatedTree : t)
        .toList();
    state = AsyncValue.data(updatedList);
    await _repo.saveTrees(novelId, updatedList);
  }
}
