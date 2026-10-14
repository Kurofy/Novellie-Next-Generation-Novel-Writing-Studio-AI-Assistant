import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../characters/presentation/screens/character_detail_screen.dart';
import '../../application/family_tree_providers.dart';
import '../../domain/models/family_tree_models.dart';
import 'family_tree_legend_widget.dart';
import 'family_tree_node_widget.dart';
import 'family_tree_painter.dart';
import 'quick_family_relative_dialog.dart';

class FamilyTreeCanvas extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String novelId;
  final TransformationController transformationController;
  final void Function(FamilyTreeNode node) onSelectNode;
  final VoidCallback onDeselect;

  const FamilyTreeCanvas({
    super.key,
    required this.tree,
    required this.novelId,
    required this.transformationController,
    required this.onSelectNode,
    required this.onDeselect,
  });

  @override
  ConsumerState<FamilyTreeCanvas> createState() => _FamilyTreeCanvasState();
}

class _FamilyTreeCanvasState extends ConsumerState<FamilyTreeCanvas> {
  static const double canvasWidth = 2800.0;
  static const double canvasHeight = 2800.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final selectedNodeId = ref.watch(selectedFamilyTreeNodeIdProvider);
    final selectedEdgeId = ref.watch(selectedFamilyTreeEdgeIdProvider);
    final searchQuery =
        ref.watch(familyTreeSearchQueryProvider).trim().toLowerCase();
    final notifier =
        ref.read(familyTreesProvider(widget.novelId).notifier);

    final selectedNode = widget.tree.nodes
        .where((n) => n.id == selectedNodeId)
        .firstOrNull;

    return Stack(
      children: [
        // Pan & Zoom Canvas
        InteractiveViewer(
          transformationController: widget.transformationController,
          boundaryMargin: const EdgeInsets.all(800),
          minScale: 0.2,
          maxScale: 2.5,
          constrained: false,
          child: GestureDetector(
            onTap: () {
              ref.read(selectedFamilyTreeNodeIdProvider.notifier).state = null;
              widget.onDeselect();
            },
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  // Lineage Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FamilyTreePainter(
                        tree: widget.tree,
                        selectedNodeId: selectedNodeId,
                        selectedEdgeId: selectedEdgeId,
                        colors: c,
                      ),
                    ),
                  ),

                  // Node Cards
                  ...widget.tree.nodes.map((node) {
                    final isSelected = node.id == selectedNodeId;
                    final isMatched = searchQuery.isNotEmpty &&
                        (node.name.toLowerCase().contains(searchQuery) ||
                            (node.titleOrRole
                                    ?.toLowerCase()
                                    .contains(searchQuery) ??
                                false));
                    final isDimmed = searchQuery.isNotEmpty && !isMatched;

                    return FamilyTreeNodeWidget(
                      key: ValueKey(node.id),
                      node: node,
                      isSelected: isSelected,
                      isDimmed: isDimmed,
                      onTap: () {
                        ref
                            .read(selectedFamilyTreeNodeIdProvider.notifier)
                            .state = node.id;
                      },
                      onDoubleTap: () => _handleDoubleTapNode(node),
                      onPanUpdate: (details) {
                        final scale = widget.transformationController.value
                            .getMaxScaleOnAxis();
                        notifier.updateMemberPosition(
                          widget.tree.id,
                          node.id,
                          node.x + details.delta.dx / scale,
                          node.y + details.delta.dy / scale,
                          save: false,
                        );
                      },
                      onPanEnd: () {
                        notifier.updateMemberPosition(
                          widget.tree.id,
                          node.id,
                          node.x,
                          node.y,
                          save: true,
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Lineage Relationship Legend Overlay
        const Positioned(
          left: 16,
          top: 16,
          child: FamilyTreeLegendWidget(),
        ),

        // Floating Node Quick-Actions Dock (When node selected)
        // Positioned at left: 16, right: 84 to NEVER collide with zoom controls at right: 16!
        if (selectedNode != null)
          Positioned(
            left: 16,
            right: 84,
            bottom: 20,
            child: _buildSelectedNodeDock(selectedNode, c, isIndo),
          ),

        // Quick Canvas Controls (Zoom In, Zoom Out, Center)
        Positioned(
          right: 16,
          bottom: 20,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border:
                  Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Symbols.add, size: 20),
                  tooltip: isIndo ? 'Perbesar' : 'Zoom In',
                  onPressed: _zoomIn,
                ),
                IconButton(
                  icon: const Icon(Symbols.remove, size: 20),
                  tooltip: isIndo ? 'Perkecil' : 'Zoom Out',
                  onPressed: _zoomOut,
                ),
                IconButton(
                  icon: const Icon(Symbols.filter_center_focus, size: 20),
                  tooltip: isIndo ? 'Pusatkan Kanvas' : 'Reset Zoom & Center',
                  onPressed: _centerCanvas,
                ),
                if (selectedNode != null)
                  IconButton(
                    icon: const Icon(Symbols.my_location,
                        size: 20, color: Color(0xFFD97706),),
                    tooltip: isIndo
                        ? 'Fokus ke Anggota Terpilih'
                        : 'Focus Selected Member',
                    onPressed: () => _focusOnNode(selectedNode),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedNodeDock(
    FamilyTreeNode node,
    AppColors c,
    bool isIndo,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(
              color: const Color(0xFFD97706).withValues(alpha: 0.5), width: 1.5,),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar & Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        const Color(0xFFD97706).withValues(alpha: 0.2),
                    child: Text(
                      node.name.isNotEmpty ? node.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: c.outlineVariant),
              const SizedBox(width: 6),

              // + Child
              _quickActionButton(
                icon: Symbols.child_care,
                label: isIndo ? '+ Anak' : '+ Child',
                tooltip: isIndo
                    ? 'Tambah Anak untuk ${node.name}'
                    : 'Add Child to ${node.name}',
                color: const Color(0xFFD97706),
                onTap: () => _openQuickRelativeDialog(
                  node,
                  FamilyRelationshipType.child,
                ),
              ),

              // + Spouse
              _quickActionButton(
                icon: Symbols.favorite,
                label: isIndo ? '+ Pasangan' : '+ Spouse',
                tooltip: isIndo
                    ? 'Tambah Pasangan untuk ${node.name}'
                    : 'Add Spouse / Partner for ${node.name}',
                color: const Color(0xFFE11D48),
                onTap: () => _openQuickRelativeDialog(
                  node,
                  FamilyRelationshipType.spouse,
                ),
              ),

              // + Parent
              _quickActionButton(
                icon: Symbols.escalator_warning,
                label: isIndo ? '+ Orang Tua' : '+ Parent',
                tooltip: isIndo
                    ? 'Tambah Orang Tua untuk ${node.name}'
                    : 'Add Parent of ${node.name}',
                color: const Color(0xFF2563EB),
                onTap: () => _openQuickRelativeDialog(
                  node,
                  FamilyRelationshipType.parent,
                ),
              ),

              // + Sibling
              _quickActionButton(
                icon: Symbols.diversity_1,
                label: isIndo ? '+ Saudara' : '+ Sibling',
                tooltip: isIndo
                    ? 'Tambah Saudara untuk ${node.name}'
                    : 'Add Sibling of ${node.name}',
                color: const Color(0xFF059669),
                onTap: () => _openQuickRelativeDialog(
                  node,
                  FamilyRelationshipType.sibling,
                ),
              ),

              // Inspector / Edit
              IconButton(
                icon: const Icon(Symbols.tune, size: 18),
                tooltip: isIndo
                    ? 'Periksa & Edit Anggota'
                    : 'Inspect & Edit Member',
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onSelectNode(node),
              ),

              // Close dock / Deselect
              IconButton(
                icon: const Icon(Symbols.close, size: 18),
                tooltip: isIndo ? 'Batal Pilih' : 'Deselect',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref.read(selectedFamilyTreeNodeIdProvider.notifier).state = null;
                  widget.onDeselect();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
            foregroundColor: color,
          ),
          icon: Icon(icon, size: 16, color: color),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Future<void> _openQuickRelativeDialog(
    FamilyTreeNode sourceNode,
    FamilyRelationshipType rel,
  ) async {
    final result = await QuickFamilyRelativeDialog.show(
      context,
      sourceNode: sourceNode,
      novelId: widget.novelId,
      treeId: widget.tree.id,
      defaultRelationship: rel,
      existingNodes: widget.tree.nodes,
    );

    if (result == null || !mounted) return;

    final notifier =
        ref.read(familyTreesProvider(widget.novelId).notifier);

    final edge = FamilyTreeEdge(
      id: generateUuid(),
      treeId: widget.tree.id,
      fromNodeId: sourceNode.id,
      toNodeId: result.node.id,
      relationshipType: result.relationship,
      isBidirectional: result.relationship.isBidirectional,
    );

    if (result.isExistingNode) {
      await notifier.addRelationship(widget.tree.id, edge);
    } else {
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

      ref.read(selectedFamilyTreeNodeIdProvider.notifier).state =
          result.node.id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndo
                ? 'Berhasil menghubungkan "${result.node.name}" sebagai $relLabel'
                : 'Connected "${result.node.name}" as ${result.relationship.label}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _zoomIn() {
    final matrix = widget.transformationController.value.clone();
    matrix.storage[0] *= 1.25;
    matrix.storage[5] *= 1.25;
    widget.transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = widget.transformationController.value.clone();
    matrix.storage[0] *= 0.8;
    matrix.storage[5] *= 0.8;
    widget.transformationController.value = matrix;
  }

  void _centerCanvas() {
    widget.transformationController.value = Matrix4.identity();
  }

  void _focusOnNode(FamilyTreeNode node) {
    final media = MediaQuery.of(context).size;
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    final targetX = (media.width / 2) - (node.x + 110) * scale;
    final targetY = (media.height / 2) - (node.y + 55) * scale;

    final matrix = Matrix4.identity()
      ..scale(scale)
      ..setTranslationRaw(targetX, targetY, 0.0);

    widget.transformationController.value = matrix;
  }

  void _handleDoubleTapNode(FamilyTreeNode node) {
    if (node.characterId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CharacterDetailScreen(
            characterId: node.characterId!,
          ),
        ),
      );
    }
  }
}
