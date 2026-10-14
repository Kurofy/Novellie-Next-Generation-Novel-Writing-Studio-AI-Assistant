import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/family_tree_models.dart';

class FamilyTreeNodeInspector extends StatefulWidget {
  final FamilyTreeNode node;
  final List<FamilyTreeNode> allNodes;
  final List<FamilyTreeEdge> connectedEdges;
  final VoidCallback onClose;
  final ValueChanged<int> onChangeGeneration;
  final ValueChanged<String> onDeleteEdge;
  final VoidCallback onDeleteNode;
  final ValueChanged<FamilyTreeNode> onSaveNode;

  const FamilyTreeNodeInspector({
    super.key,
    required this.node,
    required this.allNodes,
    required this.connectedEdges,
    required this.onClose,
    required this.onChangeGeneration,
    required this.onDeleteEdge,
    required this.onDeleteNode,
    required this.onSaveNode,
  });

  @override
  State<FamilyTreeNodeInspector> createState() =>
      _FamilyTreeNodeInspectorState();
}

class _FamilyTreeNodeInspectorState extends State<FamilyTreeNodeInspector> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _yearsController;
  late TextEditingController _notesController;
  late int _generation;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node.name);
    _roleController = TextEditingController(text: widget.node.titleOrRole ?? '');
    _yearsController = TextEditingController(text: widget.node.years ?? '');
    _notesController = TextEditingController(text: widget.node.notes ?? '');
    _generation = widget.node.generation;
    _status = widget.node.status ?? 'alive';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _yearsController.dispose();
    _notesController.dispose();
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
                  radius: 18,
                  backgroundColor:
                      const Color(0xFFD97706).withValues(alpha: 0.15),
                  child: Text(
                    widget.node.name.isNotEmpty
                        ? widget.node.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.name,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isIndo
                            ? 'Generasi $_generation • ${widget.node.titleOrRole ?? "Anggota Keluarga"}'
                            : 'Generation $_generation • ${widget.node.titleOrRole ?? "Family Member"}',
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
                // Quick generation shift
                Row(
                  children: [
                    Text(
                      isIndo ? 'Generasi: ' : 'Generation: ',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _generation == 0
                            ? (isIndo ? 'Akar (Gen 0)' : 'Root (Gen 0)')
                            : (_generation < 0
                                ? (isIndo
                                    ? 'Leluhur (Gen $_generation)'
                                    : 'Ancestors (Gen $_generation)')
                                : (isIndo
                                    ? 'Keturunan (Gen +$_generation)'
                                    : 'Descendants (Gen +$_generation)')),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Symbols.remove_circle_outline, size: 20),
                      tooltip: isIndo
                          ? 'Geser Lebih Tua (-1 Gen)'
                          : 'Shift Older (-1 Gen)',
                      onPressed: () {
                        setState(() => _generation -= 1);
                        widget.onChangeGeneration(_generation);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Symbols.add_circle_outline, size: 20),
                      tooltip: isIndo
                          ? 'Geser Lebih Muda (+1 Gen)'
                          : 'Shift Younger (+1 Gen)',
                      onPressed: () {
                        setState(() => _generation += 1);
                        widget.onChangeGeneration(_generation);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Nama Lengkap' : 'Full Name',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Role/Title field
                TextField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    labelText: isIndo
                        ? 'Gelar Dinasti atau Peran'
                        : 'Dynastic Title or Role',
                    hintText: isIndo
                        ? 'cth. Kepala Keluarga, Matriark, Pewaris, Putra Sulung'
                        : 'e.g. Patriarch, Matriarch, Heir, Eldest Son',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Years & Status
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearsController,
                        decoration: InputDecoration(
                          labelText:
                              isIndo ? 'Masa Hidup / Tahun' : 'Lifespan / Years',
                          hintText: isIndo
                              ? 'cth. 1040 - 1099'
                              : 'e.g. 1040 - 1099',
                          filled: true,
                          fillColor: c.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          filled: true,
                          fillColor: c.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'alive',
                            child: Text(isIndo ? 'Hidup' : 'Alive'),
                          ),
                          DropdownMenuItem(
                            value: 'deceased',
                            child: Text(isIndo ? 'Meninggal' : 'Deceased'),
                          ),
                          DropdownMenuItem(
                            value: 'unknown',
                            child: Text(isIndo ? 'Tidak Diketahui' : 'Unknown'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText:
                        isIndo ? 'Biografi & Catatan' : 'Biography & Notes',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Connected Relatives List
                Text(
                  isIndo
                      ? 'Kerabat Keluarga Terhubung (${widget.connectedEdges.length})'
                      : 'Connected Family Members (${widget.connectedEdges.length})',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
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
                          ? 'Belum ada kerabat yang terhubung secara langsung. Gunakan dok aksi cepat di kanvas untuk menghubungkan.'
                          : 'No relatives connected directly yet. Use quick action dock on canvas to connect.',
                      style:
                          AppTypography.bodySm.copyWith(color: c.textSecondary),
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: c.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Symbols.link, size: 16, color: c.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherNode?.name ??
                                      (isIndo
                                          ? 'Kerabat Tidak Dikenal'
                                          : 'Unknown Relative'),
                                  style: AppTypography.bodySm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: c.textPrimary,
                                  ),
                                ),
                                Text(
                                  edge.localizedDisplayLabel(isIndo),
                                  style: AppTypography.labelSm.copyWith(
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Symbols.link_off,
                              size: 18,
                              color: Colors.red,
                            ),
                            tooltip: isIndo
                                ? 'Putuskan Hubungan'
                                : 'Disconnect Relationship',
                            onPressed: () => widget.onDeleteEdge(edge.id),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Save & Delete buttons
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Symbols.delete, size: 18),
                      label: Text(isIndo ? 'Hapus Anggota' : 'Delete Member'),
                      onPressed: widget.onDeleteNode,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Symbols.save, size: 18),
                      label:
                          Text(isIndo ? 'Simpan Perubahan' : 'Save Details'),
                      onPressed: () {
                        final updated = widget.node.copyWith(
                          name: _nameController.text.trim().isEmpty
                              ? widget.node.name
                              : _nameController.text.trim(),
                          titleOrRole: _roleController.text.trim().isEmpty
                              ? null
                              : _roleController.text.trim(),
                          generation: _generation,
                          years: _yearsController.text.trim().isEmpty
                              ? null
                              : _yearsController.text.trim(),
                          status: _status,
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
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
    );
  }
}
