import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../manuscript/presentation/screens/chapter_editor_screen.dart';
import '../../application/mind_map_providers.dart';
import '../../domain/models/mind_map_models.dart';
import 'add_connection_dialog.dart';
import 'mind_map_node_widget.dart';
import 'mind_map_painter.dart';

class MindMapCanvas extends ConsumerStatefulWidget {
  final MindMapGraph graph;
  final String novelId;
  final TransformationController transformationController;
  final void Function(MindMapNode node) onSelectNode;
  final VoidCallback onDeselect;

  const MindMapCanvas({
    super.key,
    required this.graph,
    required this.novelId,
    required this.transformationController,
    required this.onSelectNode,
    required this.onDeselect,
  });

  @override
  ConsumerState<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends ConsumerState<MindMapCanvas> {
  static const double canvasWidth = 2800.0;
  static const double canvasHeight = 2800.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selectedNodeId = ref.watch(selectedMindMapNodeIdProvider);
    final selectedEdgeId = ref.watch(selectedMindMapEdgeIdProvider);
    final searchQuery =
        ref.watch(mindMapSearchQueryProvider).trim().toLowerCase();
    final typeFilter = ref.watch(mindMapTypeFilterProvider);
    final notifier = ref.read(mindMapGraphProvider(widget.novelId).notifier);

    final selectedNode = widget.graph.nodes
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
              ref.read(selectedMindMapNodeIdProvider.notifier).state = null;
              widget.onDeselect();
            },
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  // 1. Connection lines & labels
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MindMapPainter(
                        graph: widget.graph,
                        selectedNodeId: selectedNodeId,
                        selectedEdgeId: selectedEdgeId,
                        colors: c,
                      ),
                    ),
                  ),

                  // 2. Node Cards
                  ...widget.graph.nodes.map((node) {
                    final isSelected = node.id == selectedNodeId;
                    final matchesFilter =
                        typeFilter == null || node.type == typeFilter;
                    final matchesSearch = searchQuery.isEmpty ||
                        node.title.toLowerCase().contains(searchQuery) ||
                        (node.description
                                ?.toLowerCase()
                                .contains(searchQuery) ??
                            false);
                    final isDimmed = !matchesFilter || !matchesSearch;

                    return MindMapNodeWidget(
                      key: ValueKey(node.id),
                      node: node,
                      isSelected: isSelected,
                      isDimmed: isDimmed,
                      onTap: () {
                        ref
                            .read(selectedMindMapNodeIdProvider.notifier)
                            .state = node.id;
                      },
                      onDoubleTap: () => _handleDoubleTapNode(node),
                      onPanUpdate: (details) {
                        final scale = widget.transformationController.value
                            .getMaxScaleOnAxis();
                        notifier.updateNodePosition(
                          node.id,
                          node.x + details.delta.dx / scale,
                          node.y + details.delta.dy / scale,
                          save: false,
                        );
                      },
                      onPanEnd: () {
                        notifier.updateNodePosition(
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

        // Floating Node Quick-Actions Dock (When node selected)
        // Positioned at left: 16, right: 84 to NEVER collide with zoom controls at right: 16!
        if (selectedNode != null)
          Positioned(
            left: 16,
            right: 84,
            bottom: 20,
            child: _buildSelectedNodeDock(selectedNode, c),
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
                  tooltip: 'Zoom In',
                  onPressed: _zoomIn,
                ),
                IconButton(
                  icon: const Icon(Symbols.remove, size: 20),
                  tooltip: 'Zoom Out',
                  onPressed: _zoomOut,
                ),
                IconButton(
                  icon: const Icon(Symbols.filter_center_focus, size: 20),
                  tooltip: 'Reset Zoom & Center',
                  onPressed: _centerCanvas,
                ),
                if (selectedNode != null)
                  IconButton(
                    icon: Icon(Symbols.my_location,
                        size: 20, color: c.primary,),
                    tooltip: 'Focus Selected Node',
                    onPressed: () => _focusOnNode(selectedNode),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedNodeDock(MindMapNode node, AppColors c) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: c.primary.withValues(alpha: 0.5), width: 1.5),
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
                    backgroundColor: c.primary.withValues(alpha: 0.15),
                    child: Icon(Symbols.hub, size: 14, color: c.primary),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      node.title,
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

              // + Next Sequence
              _quickActionButton(
                icon: Symbols.arrow_forward,
                label: '+ Next Beat',
                tooltip: 'Add following chapter/beat sequence',
                color: const Color(0xFF06B6D4),
                onTap: () => _quickAddSequence(node),
              ),

              // + Sub-Arc
              _quickActionButton(
                icon: Symbols.alt_route,
                label: '+ Sub-Arc',
                tooltip: 'Add branching subplot or character arc',
                color: const Color(0xFF8B5CF6),
                onTap: () => _quickAddSubArc(node),
              ),

              // Connect to existing
              _quickActionButton(
                icon: Symbols.link,
                label: 'Connect',
                tooltip: 'Connect to existing node on canvas',
                color: c.textSecondary,
                onTap: () => _showAddConnectionModal(node),
              ),

              // Inspect / Edit
              IconButton(
                icon: const Icon(Symbols.tune, size: 18),
                tooltip: 'Inspect & Edit Node',
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onSelectNode(node),
              ),

              // Deselect
              IconButton(
                icon: const Icon(Symbols.close, size: 18),
                tooltip: 'Deselect',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref.read(selectedMindMapNodeIdProvider.notifier).state = null;
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

  Future<void> _quickAddSequence(MindMapNode sourceNode) async {
    final notifier = ref.read(mindMapGraphProvider(widget.novelId).notifier);
    final nextSeq = (sourceNode.sequenceOrder ?? 0) + 1;
    final nextNode = MindMapNode(
      id: generateUuid(),
      novelId: widget.novelId,
      type: sourceNode.type == MindMapNodeType.chapterOrder
          ? MindMapNodeType.chapterOrder
          : MindMapNodeType.plotPoint,
      title: 'Sequence #$nextSeq',
      sequenceOrder: nextSeq,
      storyArcName: sourceNode.storyArcName,
      x: sourceNode.x + 270.0,
      y: sourceNode.y,
    );

    final edge = MindMapEdge(
      id: generateUuid(),
      fromNodeId: sourceNode.id,
      toNodeId: nextNode.id,
      type: MindMapConnectionType.leadsTo,
    );

    await notifier.addNodeAndEdge(node: nextNode, edge: edge);
    ref.read(selectedMindMapNodeIdProvider.notifier).state = nextNode.id;
  }

  Future<void> _quickAddSubArc(MindMapNode sourceNode) async {
    final notifier = ref.read(mindMapGraphProvider(widget.novelId).notifier);
    final subNode = MindMapNode(
      id: generateUuid(),
      novelId: widget.novelId,
      type: MindMapNodeType.storyArc,
      title: 'Subplot Branch',
      storyArcName: sourceNode.storyArcName != null
          ? '${sourceNode.storyArcName} - Branch'
          : 'Subplot',
      x: sourceNode.x + 240.0,
      y: sourceNode.y + 160.0,
    );

    final edge = MindMapEdge(
      id: generateUuid(),
      fromNodeId: sourceNode.id,
      toNodeId: subNode.id,
      type: MindMapConnectionType.subPlot,
    );

    await notifier.addNodeAndEdge(node: subNode, edge: edge);
    ref.read(selectedMindMapNodeIdProvider.notifier).state = subNode.id;
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

  void _focusOnNode(MindMapNode node) {
    final media = MediaQuery.of(context).size;
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    final targetX = (media.width / 2) - (node.x + 115) * scale;
    final targetY = (media.height / 2) - (node.y + 55) * scale;

    final matrix = Matrix4.identity()
      ..scale(scale)
      ..setTranslationRaw(targetX, targetY, 0.0);

    widget.transformationController.value = matrix;
  }

  void _handleDoubleTapNode(MindMapNode node) {
    if (node.linkedChapterId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChapterEditorScreen(
            novelId: widget.novelId,
            chapterId: node.linkedChapterId!,
          ),
        ),
      );
    }
  }

  Future<void> _showAddConnectionModal(MindMapNode sourceNode) async {
    final newEdge = await showDialog<MindMapEdge>(
      context: context,
      builder: (_) => AddConnectionDialog(
        sourceNode: sourceNode,
        availableNodes: widget.graph.nodes,
      ),
    );

    if (newEdge != null && mounted) {
      final notifier =
          ref.read(mindMapGraphProvider(widget.novelId).notifier);
      await notifier.addEdge(newEdge);
    }
  }
}
