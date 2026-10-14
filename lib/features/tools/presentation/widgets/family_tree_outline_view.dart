import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/family_tree_providers.dart';
import '../../domain/models/family_tree_models.dart';
import 'quick_family_relative_dialog.dart';

class FamilyTreeOutlineView extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String novelId;
  final void Function(FamilyTreeNode node) onSelectNode;
  final void Function(FamilyTreeNode node) onFocusOnCanvas;
  final VoidCallback onAddMember;

  const FamilyTreeOutlineView({
    super.key,
    required this.tree,
    required this.novelId,
    required this.onSelectNode,
    required this.onFocusOnCanvas,
    required this.onAddMember,
  });

  @override
  ConsumerState<FamilyTreeOutlineView> createState() =>
      _FamilyTreeOutlineViewState();
}

class _FamilyTreeOutlineViewState extends ConsumerState<FamilyTreeOutlineView> {
  int? _selectedGenFilter;
  bool _onlyLiving = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final globalQuery = ref.watch(familyTreeSearchQueryProvider).trim().toLowerCase();
    final localQuery = _searchController.text.trim().toLowerCase();
    final effectiveQuery = globalQuery.isNotEmpty ? globalQuery : localQuery;

    final allNodes = widget.tree.nodes;
    final allEdges = widget.tree.edges;

    if (allNodes.isEmpty) {
      return _buildEmptyOutline(c, isIndo);
    }

    // Filter nodes
    final filteredNodes = allNodes.where((n) {
      if (_selectedGenFilter != null && n.generation != _selectedGenFilter) {
        return false;
      }
      if (_onlyLiving && (n.status?.toLowerCase() == 'deceased')) {
        return false;
      }
      if (effectiveQuery.isNotEmpty) {
        final matchesName = n.name.toLowerCase().contains(effectiveQuery);
        final matchesRole =
            n.titleOrRole?.toLowerCase().contains(effectiveQuery) ?? false;
        if (!matchesName && !matchesRole) return false;
      }
      return true;
    }).toList();

    // Group filtered nodes by generation
    final genMap = <int, List<FamilyTreeNode>>{};
    for (final node in filteredNodes) {
      genMap.putIfAbsent(node.generation, () => []).add(node);
    }
    final sortedGens = genMap.keys.toList()..sort();

    // Map for quick relationship lookups
    final nodeMap = {for (final n in allNodes) n.id: n};

    // Computations for dynasty stats
    final totalLiving =
        allNodes.where((n) => n.status?.toLowerCase() != 'deceased').length;
    final totalGens = allNodes.map((n) => n.generation).toSet().length;
    final minGen = allNodes.map((n) => n.generation).reduce((a, b) => a < b ? a : b);
    final maxGen = allNodes.map((n) => n.generation).reduce((a, b) => a > b ? a : b);
    final totalMarriages = allEdges
        .where((e) => e.relationshipType == FamilyRelationshipType.spouse)
        .length;

    return Column(
      children: [
        // Dynasty Stats & Quick Filter Strip
        _buildStatsAndFiltersBar(
          c,
          totalLiving: totalLiving,
          totalGens: totalGens,
          minGen: minGen,
          maxGen: maxGen,
          totalMarriages: totalMarriages,
          allNodes: allNodes,
          isIndo: isIndo,
        ),

        // Lineage Generational List
        Expanded(
          child: filteredNodes.isEmpty
              ? _buildNoResultsView(c, isIndo)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: sortedGens.length,
                  itemBuilder: (context, index) {
                    final gen = sortedGens[index];
                    final members = genMap[gen]!;
                    return _buildGenerationSection(
                      context,
                      gen: gen,
                      members: members,
                      nodeMap: nodeMap,
                      allEdges: allEdges,
                      c: c,
                      isIndo: isIndo,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsAndFiltersBar(
    AppColors c, {
    required int totalLiving,
    required int totalGens,
    required int minGen,
    required int maxGen,
    required int totalMarriages,
    required List<FamilyTreeNode> allNodes,
    required bool isIndo,
  }) {
    final availableGens = allNodes.map((n) => n.generation).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Badges Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatPill(
                  icon: Symbols.groups,
                  label: isIndo
                      ? '${allNodes.length} Anggota'
                      : '${allNodes.length} Members',
                  color: const Color(0xFFD97706),
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  icon: Symbols.timeline,
                  label: isIndo
                      ? '$totalGens Gen (Gen $minGen s/d +$maxGen)'
                      : '$totalGens Gen (Gen $minGen to +$maxGen)',
                  color: const Color(0xFF2563EB),
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  icon: Symbols.favorite,
                  label: isIndo
                      ? '$totalMarriages Pernikahan'
                      : '$totalMarriages Unions',
                  color: const Color(0xFFE11D48),
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  icon: Symbols.eco,
                  label: isIndo
                      ? '$totalLiving Masih Hidup'
                      : '$totalLiving Living',
                  color: const Color(0xFF059669),
                  c: c,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All Generations Pill
                FilterChip(
                  selected: _selectedGenFilter == null,
                  label: Text(isIndo ? 'Semua Generasi' : 'All Generations'),
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    setState(() {
                      _selectedGenFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 6),

                // Gen specific chips
                ...availableGens.map((gen) {
                  final label = gen == 0
                      ? (isIndo ? 'Gen 0 (Pendiri)' : 'Gen 0 (Founders)')
                      : (gen < 0
                          ? (isIndo ? 'Gen $gen (Leluhur)' : 'Gen $gen (Ancestors)')
                          : 'Gen +$gen');
                  final isSelected = _selectedGenFilter == gen;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(label),
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() {
                          _selectedGenFilter = val ? gen : null;
                        });
                      },
                    ),
                  );
                }),

                // Living Only toggle
                FilterChip(
                  selected: _onlyLiving,
                  avatar: Icon(
                    Symbols.heart_plus,
                    size: 14,
                    color: _onlyLiving ? c.primary : c.textSecondary,
                  ),
                  label: Text(isIndo ? 'Hanya yang Hidup' : 'Living Only'),
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    setState(() {
                      _onlyLiving = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationSection(
    BuildContext context, {
    required int gen,
    required List<FamilyTreeNode> members,
    required Map<String, FamilyTreeNode> nodeMap,
    required List<FamilyTreeEdge> allEdges,
    required AppColors c,
    required bool isIndo,
  }) {
    final genTitle = gen == 0
        ? (isIndo
            ? 'Generasi 0 — Pendiri & Leluhur Utama'
            : 'Generation 0 — Founders & Progenitors')
        : (gen < 0
            ? (isIndo
                ? 'Generasi $gen — Leluhur Masa Lalu'
                : 'Generation $gen — Ancestors & Forebears')
            : (isIndo
                ? 'Generasi +$gen — Keturunan & Penerus'
                : 'Generation +$gen — Descendants & Heirs'));

    final genIcon = gen == 0
        ? Symbols.crown
        : (gen < 0 ? Symbols.history_edu : Symbols.nature_people);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generation Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFD97706).withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(genIcon, size: 20, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    genTitle,
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isIndo
                        ? '${members.length} anggota'
                        : '${members.length} members',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Member Cards in this generation
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final member = members[idx];
              return _buildMemberCard(
                member,
                nodeMap: nodeMap,
                allEdges: allEdges,
                c: c,
                isIndo: isIndo,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    FamilyTreeNode node, {
    required Map<String, FamilyTreeNode> nodeMap,
    required List<FamilyTreeEdge> allEdges,
    required AppColors c,
    required bool isIndo,
  }) {
    final isDeceased = node.status?.toLowerCase() == 'deceased';

    // Find spouses, children, parents, siblings
    final spouses = <FamilyTreeNode>[];
    final children = <FamilyTreeNode>[];
    final parents = <FamilyTreeNode>[];
    final siblings = <FamilyTreeNode>[];

    for (final edge in allEdges) {
      if (edge.relationshipType == FamilyRelationshipType.spouse) {
        if (edge.fromNodeId == node.id && nodeMap.containsKey(edge.toNodeId)) {
          spouses.add(nodeMap[edge.toNodeId]!);
        } else if (edge.toNodeId == node.id &&
            nodeMap.containsKey(edge.fromNodeId)) {
          spouses.add(nodeMap[edge.fromNodeId]!);
        }
      } else if (edge.relationshipType == FamilyRelationshipType.child) {
        if (edge.fromNodeId == node.id && nodeMap.containsKey(edge.toNodeId)) {
          children.add(nodeMap[edge.toNodeId]!);
        } else if (edge.toNodeId == node.id &&
            nodeMap.containsKey(edge.fromNodeId)) {
          parents.add(nodeMap[edge.fromNodeId]!);
        }
      } else if (edge.relationshipType == FamilyRelationshipType.sibling) {
        if (edge.fromNodeId == node.id && nodeMap.containsKey(edge.toNodeId)) {
          siblings.add(nodeMap[edge.toNodeId]!);
        } else if (edge.toNodeId == node.id &&
            nodeMap.containsKey(edge.fromNodeId)) {
          siblings.add(nodeMap[edge.fromNodeId]!);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDeceased
              ? c.outlineVariant.withValues(alpha: 0.5)
              : c.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar + Name + Title + Lifespan + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFFD97706).withValues(alpha: 0.15),
                child: Text(
                  node.name.isNotEmpty ? node.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            node.name,
                            style: AppTypography.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Alive / Deceased Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDeceased
                                ? Colors.grey.withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDeceased
                                      ? Colors.grey
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDeceased
                                    ? (isIndo ? 'Meninggal' : 'Deceased')
                                    : (isIndo ? 'Hidup' : 'Alive'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDeceased
                                      ? c.textSecondary
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (node.titleOrRole != null &&
                        node.titleOrRole!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        node.titleOrRole!,
                        style: AppTypography.labelSm.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    if (node.years != null && node.years!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Symbols.schedule, size: 12, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            node.years!,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action Toolbar on Card
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.filter_center_focus, size: 18),
                    tooltip:
                        isIndo ? 'Pusatkan di Kanvas' : 'Locate on Canvas',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onFocusOnCanvas(node),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.tune, size: 18),
                    tooltip: isIndo
                        ? 'Periksa & Edit Anggota'
                        : 'Inspect & Edit Member',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onSelectNode(node),
                  ),
                ],
              ),
            ],
          ),

          // Relationships Badges Section
          if (spouses.isNotEmpty ||
              children.isNotEmpty ||
              parents.isNotEmpty ||
              siblings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Spouse
                if (spouses.isNotEmpty)
                  _buildRelationshipChip(
                    icon: Symbols.favorite,
                    label: isIndo
                        ? 'Pasangan: ${spouses.map((s) => s.name).join(", ")}'
                        : 'Spouse: ${spouses.map((s) => s.name).join(", ")}',
                    color: const Color(0xFFE11D48),
                    onTap: () => widget.onSelectNode(spouses.first),
                  ),

                // Children
                if (children.isNotEmpty)
                  _buildRelationshipChip(
                    icon: Symbols.child_care,
                    label: isIndo
                        ? 'Anak (${children.length}): ${children.map((c) => c.name).join(", ")}'
                        : 'Children (${children.length}): ${children.map((c) => c.name).join(", ")}',
                    color: const Color(0xFFD97706),
                    onTap: () => widget.onSelectNode(children.first),
                  ),

                // Parents
                if (parents.isNotEmpty)
                  _buildRelationshipChip(
                    icon: Symbols.escalator_warning,
                    label: isIndo
                        ? 'Orang Tua: ${parents.map((p) => p.name).join(", ")}'
                        : 'Parents: ${parents.map((p) => p.name).join(", ")}',
                    color: const Color(0xFF2563EB),
                    onTap: () => widget.onSelectNode(parents.first),
                  ),

                // Siblings
                if (siblings.isNotEmpty)
                  _buildRelationshipChip(
                    icon: Symbols.diversity_1,
                    label: isIndo
                        ? 'Saudara: ${siblings.map((s) => s.name).join(", ")}'
                        : 'Siblings: ${siblings.map((s) => s.name).join(", ")}',
                    color: const Color(0xFF059669),
                    onTap: () => widget.onSelectNode(siblings.first),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Quick "+ Relative" Action Button for this member
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: BorderSide(
                    color: const Color(0xFFD97706).withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(
                  Symbols.person_add_alt,
                  size: 15,
                  color: Color(0xFFD97706),
                ),
                label: Text(
                  isIndo ? '+ Tambah Kerabat' : '+ Add Relative',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                onPressed: () => _openAddRelativeDialog(node),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddRelativeDialog(FamilyTreeNode sourceNode) async {
    final result = await QuickFamilyRelativeDialog.show(
      context,
      sourceNode: sourceNode,
      novelId: widget.novelId,
      treeId: widget.tree.id,
      defaultRelationship: FamilyRelationshipType.child,
      existingNodes: widget.tree.nodes,
    );

    if (result != null && mounted) {
      final notifier =
          ref.read(familyTreesProvider(widget.novelId).notifier);

      if (result.isExistingNode) {
        final edge = FamilyTreeEdge(
          id: '${sourceNode.id}_${result.node.id}_${result.relationship.name}',
          treeId: widget.tree.id,
          fromNodeId: sourceNode.id,
          toNodeId: result.node.id,
          relationshipType: result.relationship,
          isBidirectional: result.relationship.isBidirectional,
        );
        await notifier.addRelationship(widget.tree.id, edge);
      } else {
        final edge = FamilyTreeEdge(
          id: '${sourceNode.id}_${result.node.id}_${result.relationship.name}',
          treeId: widget.tree.id,
          fromNodeId: sourceNode.id,
          toNodeId: result.node.id,
          relationshipType: result.relationship,
          isBidirectional: result.relationship.isBidirectional,
        );
        await notifier.addRelativeMemberAndEdge(
          widget.tree.id,
          node: result.node,
          edge: edge,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final isIndo = l10n?.localeName == 'id';
        final relLabel = result.relationship.localizedLabel(isIndo);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Menghubungkan ${result.node.name} sebagai $relLabel dari ${sourceNode.name}'
                  : 'Linked ${result.node.name} as ${result.relationship.label} ${sourceNode.name}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyOutline(AppColors c, bool isIndo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.account_tree,
                size: 44,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isIndo
                  ? '${widget.tree.name} masih kosong'
                  : '${widget.tree.name} is Empty',
              style: AppTypography.screenTitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isIndo
                    ? 'Bangun silsilah ini dengan templat dinasti 1-klik atau tambahkan karakter pertama Anda.'
                    : 'Build this family lineage using 1-click starter templates or add your first character.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _buildStarterTemplatesCard(c, isIndo),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterTemplatesCard(AppColors c, bool isIndo) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isIndo
                    ? 'Templat Cepat Silsilah Dinasti'
                    : 'Quick Starter Dynasty Templates',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _templateButton(
                icon: Symbols.person,
                title: isIndo ? 'Pendiri Tunggal' : 'Solo Founder',
                subtitle: isIndo
                    ? 'Kepala keluarga atau matriark tunggal siap dibangun'
                    : 'Single patriarch or matriarch ready to build from',
                onTap: () => _applyTemplate('solo'),
              ),
              const SizedBox(height: 8),
              _templateButton(
                icon: Symbols.favorite,
                title: isIndo ? 'Pasangan Pendiri' : 'Founder Couple',
                subtitle: isIndo
                    ? 'Patriark & Matriark terhubung sebagai pasangan'
                    : 'Patriarch & Matriarch connected as spouses',
                onTap: () => _applyTemplate('couple'),
              ),
              const SizedBox(height: 8),
              _templateButton(
                icon: Symbols.family_restroom,
                title: isIndo
                    ? 'Dinasti Tiga Generasi'
                    : 'Three Generations Dynasty',
                subtitle: isIndo
                    ? 'Pendiri -> Pewaris Sulung -> Cucu siap diedit'
                    : 'Founders -> Firstborn Heir -> Grandchild ready to edit',
                onTap: () => _applyTemplate('dynasty'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Symbols.person_add),
                label: Text(
                  isIndo ? 'Tambah Anggota Manual' : 'Add Member Manually',
                ),
                onPressed: widget.onAddMember,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFD97706)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Symbols.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTemplate(String type) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final notifier = ref.read(familyTreesProvider(widget.novelId).notifier);
    await notifier.applyStarterTemplate(widget.tree.id, type);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndo
                ? 'Berhasil menerapkan templat silsilah dinasti!'
                : 'Populated starter dynasty lineage template!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildNoResultsView(AppColors c, bool isIndo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.search_off, size: 40, color: c.textMuted),
            const SizedBox(height: 10),
            Text(
              isIndo
                  ? 'Tidak Ada Anggota yang Cocok'
                  : 'No Members Match Filter',
              style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isIndo
                  ? 'Coba bersihkan pencarian atau pilih "Semua Generasi".'
                  : 'Try clearing your search query or selecting "All Generations".',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedGenFilter = null;
                  _onlyLiving = false;
                  _searchController.clear();
                });
                ref.read(familyTreeSearchQueryProvider.notifier).state = '';
              },
              child: Text(isIndo ? 'Reset Filter' : 'Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
