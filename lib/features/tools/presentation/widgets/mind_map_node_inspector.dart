import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/mind_map_models.dart';

class MindMapNodeInspector extends StatefulWidget {
  final MindMapNode node;
  final List<MindMapNode> allNodes;
  final List<MindMapEdge> connectedEdges;
  final VoidCallback onAddConnection;
  final ValueChanged<String> onDeleteEdge;
  final VoidCallback onDeleteNode;
  final ValueChanged<MindMapNode> onSaveNode;
  final VoidCallback onClose;

  const MindMapNodeInspector({
    super.key,
    required this.node,
    required this.allNodes,
    required this.connectedEdges,
    required this.onAddConnection,
    required this.onDeleteEdge,
    required this.onDeleteNode,
    required this.onSaveNode,
    required this.onClose,
  });

  @override
  State<MindMapNodeInspector> createState() => _MindMapNodeInspectorState();
}

class _MindMapNodeInspectorState extends State<MindMapNodeInspector> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _arcNameController;
  late TextEditingController _sequenceController;
  late MindMapNodeType _type;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.title);
    _descController = TextEditingController(text: widget.node.description ?? '');
    _arcNameController =
        TextEditingController(text: widget.node.storyArcName ?? '');
    _sequenceController = TextEditingController(
        text: widget.node.sequenceOrder?.toString() ?? '',);
    _type = widget.node.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _arcNameController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final nodeMap = {for (final n in widget.allNodes) n.id: n};

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: c.primary.withValues(alpha: 0.15),
                    child: Icon(Symbols.hub, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.node.title,
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_type.localizedLabel(isIndo)}${widget.node.sequenceOrder != null ? (isIndo ? " • Urutan #${widget.node.sequenceOrder}" : " • Sequence #${widget.node.sequenceOrder}") : ""}',
                          style: AppTypography.labelSm
                              .copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Type selection chips
                  Text(
                    isIndo ? 'Kategori Simpul' : 'Node Category',
                    style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MindMapNodeType.values.map((t) {
                        final isSel = _type == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSel,
                            label: Text(t.localizedLabel(isIndo)),
                            labelStyle: TextStyle(
                              color: isSel ? c.primary : c.textPrimary,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            selectedColor: c.primarySoft,
                            backgroundColor: c.surfaceSecondary,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _type = t),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: isIndo ? 'Judul' : 'Title',
                      filled: true,
                      fillColor: c.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sequence & Arc Name
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _sequenceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isIndo ? 'Nomor Urutan' : 'Sequence #',
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _arcNameController,
                          decoration: InputDecoration(
                            labelText: isIndo ? 'Alur Cerita / Babak' : 'Story Arc / Act Group',
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isIndo ? 'Catatan & Ketukan Narasi' : 'Notes & Narrative Beats',
                      filled: true,
                      fillColor: c.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Connected Links
                  Row(
                    children: [
                      Text(
                        '${isIndo ? "Tautan Terhubung" : "Connected Links"} (${widget.connectedEdges.length})',
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Symbols.add, size: 16),
                        label: Text(isIndo ? 'Tambah Hubungan' : 'Add Connection'),
                        onPressed: widget.onAddConnection,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (widget.connectedEdges.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Text(
                        isIndo
                            ? 'Belum ada tautan urutan atau narasi yang terhubung.'
                            : 'No sequence or narrative links connected yet.',
                        style: AppTypography.bodySm
                            .copyWith(color: c.textSecondary),
                      ),
                    )
                  else
                    ...widget.connectedEdges.map((edge) {
                      final isOutgoing = edge.fromNodeId == widget.node.id;
                      final otherNodeId =
                          isOutgoing ? edge.toNodeId : edge.fromNodeId;
                      final otherNode = nodeMap[otherNodeId];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,),
                        decoration: BoxDecoration(
                          color: c.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                              color: c.outlineVariant.withValues(alpha: 0.5),),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.alt_route,
                                size: 16, color: c.textSecondary,),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherNode?.title ?? (isIndo ? 'Simpul Tidak Dikenal' : 'Unknown Node'),
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    edge.localizedDisplayLabel(isIndo),
                                    style: AppTypography.labelSm.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Symbols.link_off,
                                  size: 18, color: Colors.red,),
                              tooltip: isIndo ? 'Hapus Tautan' : 'Delete Link',
                              onPressed: () => widget.onDeleteEdge(edge.id),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Actions: Delete & Save
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red,),
                        icon: const Icon(Symbols.delete, size: 18),
                        label: Text(isIndo ? 'Hapus Simpul' : 'Delete Node'),
                        onPressed: widget.onDeleteNode,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Symbols.save, size: 18),
                        label: Text(isIndo ? 'Simpan Perubahan' : 'Save Changes'),
                        onPressed: () {
                          final seq =
                              int.tryParse(_sequenceController.text.trim());
                          final updated = widget.node.copyWith(
                            type: _type,
                            title: _titleController.text.trim().isEmpty
                                ? widget.node.title
                                : _titleController.text.trim(),
                            sequenceOrder: seq,
                            storyArcName:
                                _arcNameController.text.trim().isEmpty
                                    ? null
                                    : _arcNameController.text.trim(),
                            description:
                                _descController.text.trim().isEmpty
                                    ? null
                                    : _descController.text.trim(),
                          );
                          widget.onSaveNode(updated);
                          widget.onClose();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
