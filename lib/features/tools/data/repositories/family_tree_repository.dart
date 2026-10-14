import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/family_tree_models.dart';

class FamilyTreeRepository {
  final AppDatabase? _db;

  FamilyTreeRepository([this._db]);

  String _treesKey(String novelId) => 'family_trees_$novelId';

  Future<List<FamilyTree>> loadTrees(String novelId) async {
    final db = _db;
    if (db == null) return [];

    final key = _treesKey(novelId);
    try {
      final row = await (db.select(db.appSettings)
            ..where((tbl) => tbl.key.equals(key)))
          .getSingleOrNull();

      if (row != null && row.value.isNotEmpty) {
        final decoded = jsonDecode(row.value) as List<dynamic>;
        return decoded
            .map((e) => FamilyTree.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Future<void> saveTrees(String novelId, List<FamilyTree> trees) async {
    final db = _db;
    if (db == null) return;

    final key = _treesKey(novelId);
    final jsonStr = jsonEncode(trees.map((t) => t.toJson()).toList());
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonStr,
            updatedAt: now,
          ),
        );
  }

  /// Creates a new distinct Family Tree for a novel and optional root character.
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
    final treeId = generateUuid();
    final now = DateTime.now();

    final List<FamilyTreeNode> initialNodes = [];
    if (rootCharacterName != null && rootCharacterName.trim().isNotEmpty) {
      initialNodes.add(
        FamilyTreeNode(
          id: generateUuid(),
          treeId: treeId,
          characterId: rootCharacterId,
          name: rootCharacterName.trim(),
          titleOrRole: rootRole ?? 'Founder / Progenitor',
          generation: 0,
          gender: rootGender,
          avatarPath: rootAvatarPath,
          status: 'alive',
          x: 400.0,
          y: 300.0,
        ),
      );
    }

    final newTree = FamilyTree(
      id: treeId,
      novelId: novelId,
      name: name.trim().isEmpty ? 'Untitled Family Tree' : name.trim(),
      description: description?.trim(),
      rootCharacterId: rootCharacterId,
      nodes: initialNodes,
      edges: const [],
      createdAt: now,
      updatedAt: now,
    );

    final existing = await loadTrees(novelId);
    final updated = [...existing, newTree];
    await saveTrees(novelId, updated);
    return newTree;
  }

  Future<void> deleteTree(String novelId, String treeId) async {
    final existing = await loadTrees(novelId);
    final updated = existing.where((t) => t.id != treeId).toList();
    await saveTrees(novelId, updated);
  }

  Future<void> updateTree(String novelId, FamilyTree updatedTree) async {
    final existing = await loadTrees(novelId);
    final index = existing.indexWhere((t) => t.id == updatedTree.id);
    if (index >= 0) {
      final updatedList = List<FamilyTree>.from(existing);
      updatedList[index] = updatedTree.copyWith(updatedAt: DateTime.now());
      await saveTrees(novelId, updatedList);
    } else {
      await saveTrees(novelId, [...existing, updatedTree]);
    }
  }

  /// Hierarchical generation layout algorithm strictly for family trees.
  /// - Groups nodes by generational rank (-2 grandparents, -1 parents, 0 root, 1 children, 2 grandchildren).
  /// - Spouses are placed side-by-side in the same generation.
  /// - Children are positioned below their parents.
  FamilyTree autoOrganizeTree(FamilyTree tree) {
    if (tree.nodes.isEmpty) return tree;

    // Group nodes by generation
    final Map<int, List<FamilyTreeNode>> genGroups = {};
    for (final node in tree.nodes) {
      genGroups.putIfAbsent(node.generation, () => []).add(node);
    }

    final sortedGens = genGroups.keys.toList()..sort();

    const double nodeWidth = 220.0;
    const double nodeHeight = 110.0;
    const double horizontalSpacing = 60.0;
    const double verticalSpacing = 160.0;
    const double originY = 120.0;

    final List<FamilyTreeNode> updatedNodes = [];

    for (int genIdx = 0; genIdx < sortedGens.length; genIdx++) {
      final gen = sortedGens[genIdx];
      final nodesInGen = genGroups[gen]!;

      // Identify spouse pairings to group them adjacent
      final spousesMapped = <String, String>{};
      for (final edge in tree.edges) {
        if (edge.relationshipType == FamilyRelationshipType.spouse) {
          spousesMapped[edge.fromNodeId] = edge.toNodeId;
          spousesMapped[edge.toNodeId] = edge.fromNodeId;
        }
      }

      final orderedInGen = <FamilyTreeNode>[];
      final visited = <String>{};

      for (final node in nodesInGen) {
        if (visited.contains(node.id)) continue;
        orderedInGen.add(node);
        visited.add(node.id);

        final spouseId = spousesMapped[node.id];
        if (spouseId != null && !visited.contains(spouseId)) {
          FamilyTreeNode? spouseNode;
          for (final n in nodesInGen) {
            if (n.id == spouseId) {
              spouseNode = n;
              break;
            }
          }
          if (spouseNode != null) {
            orderedInGen.add(spouseNode);
            visited.add(spouseId);
          }
        }
      }

      final totalWidth = orderedInGen.length * nodeWidth +
          (orderedInGen.length - 1) * horizontalSpacing;
      final startX = 600.0 - (totalWidth / 2);

      for (int i = 0; i < orderedInGen.length; i++) {
        final node = orderedInGen[i];
        final x = startX + i * (nodeWidth + horizontalSpacing);
        final y = originY + genIdx * (nodeHeight + verticalSpacing);
        updatedNodes.add(node.copyWith(x: x, y: y));
      }
    }

    return tree.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );
  }
}
