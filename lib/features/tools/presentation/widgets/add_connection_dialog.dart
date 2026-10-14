import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/mind_map_models.dart';

class AddConnectionDialog extends StatefulWidget {
  final MindMapNode sourceNode;
  final List<MindMapNode> availableNodes;

  const AddConnectionDialog({
    super.key,
    required this.sourceNode,
    required this.availableNodes,
  });

  @override
  State<AddConnectionDialog> createState() => _AddConnectionDialogState();
}

class _AddConnectionDialogState extends State<AddConnectionDialog> {
  late String _selectedTargetId;
  MindMapConnectionType _selectedType = MindMapConnectionType.leadsTo;
  final TextEditingController _customLabelController = TextEditingController();
  bool _isBidirectional = false;

  @override
  void initState() {
    super.initState();
    final candidates = widget.availableNodes
        .where((n) => n.id != widget.sourceNode.id)
        .toList();
    _selectedTargetId = candidates.isNotEmpty ? candidates.first.id : '';
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final candidates = widget.availableNodes
        .where((n) => n.id != widget.sourceNode.id)
        .toList();

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Symbols.alt_route, color: c.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isIndo
                          ? 'Hubungkan "${widget.sourceNode.title}"'
                          : 'Connect "${widget.sourceNode.title}"',
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    tooltip: isIndo ? 'Tutup' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (candidates.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isIndo
                        ? 'Tidak ada simpul lain di kanvas untuk dihubungkan. Tambahkan simpul lain terlebih dahulu.'
                        : 'No other nodes on the canvas to connect to. Add more nodes first.',
                    style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                // Target Node Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedTargetId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Simpul Target' : 'Target Node',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  items: candidates.map((n) {
                    return DropdownMenuItem<String>(
                      value: n.id,
                      child: Text('${n.title} (${n.type.localizedLabel(isIndo)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTargetId = val);
                  },
                ),

                const SizedBox(height: 16),

                // Connection Type
                Text(
                  isIndo ? 'Hubungan Relasi' : 'Connection Relationship',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: MindMapConnectionType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.localizedLabel(isIndo)),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected ? c.primary : c.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: c.primarySoft,
                      backgroundColor: c.surfaceSecondary,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedType = type),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Custom Label
                TextField(
                  controller: _customLabelController,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Label Kustom (Opsional)' : 'Custom Label (Optional)',
                    hintText: isIndo
                        ? 'cth. Memantik konflik, Menjadi bayangan masa depan'
                        : 'e.g. Incites conflict, Foreshadows',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bidirectional checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isIndo ? 'Hubungan dua arah (timbal balik)' : 'Bidirectional relationship'),
                  subtitle: Text(isIndo
                      ? 'Menunjukkan urutan saling pengaruh atau konflik timbal balik'
                      : 'Indicates mutual sequence or mutual conflict'),
                  value: _isBidirectional,
                  onChanged: (val) =>
                      setState(() => _isBidirectional = val ?? false),
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(isIndo ? 'Batal' : 'Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final edge = MindMapEdge(
                          id: generateUuid(),
                          fromNodeId: widget.sourceNode.id,
                          toNodeId: _selectedTargetId,
                          type: _selectedType,
                          customLabel:
                              _customLabelController.text.trim().isEmpty
                                  ? null
                                  : _customLabelController.text.trim(),
                          isBidirectional: _isBidirectional,
                        );
                        Navigator.of(context).pop(edge);
                      },
                      child: Text(isIndo ? 'Buat Hubungan' : 'Create Connection'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
