import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../characters/application/character_providers.dart';
import '../../../characters/domain/models/character_model.dart';
import '../../domain/models/family_tree_models.dart';

class QuickFamilyRelativeResult {
  final FamilyTreeNode node;
  final FamilyRelationshipType relationship;
  final bool isExistingNode;

  QuickFamilyRelativeResult({
    required this.node,
    required this.relationship,
    this.isExistingNode = false,
  });
}

class QuickFamilyRelativeDialog extends ConsumerStatefulWidget {
  final FamilyTreeNode sourceNode;
  final String novelId;
  final String treeId;
  final FamilyRelationshipType defaultRelationship;
  final List<FamilyTreeNode> existingNodes;

  const QuickFamilyRelativeDialog({
    super.key,
    required this.sourceNode,
    required this.novelId,
    required this.treeId,
    required this.defaultRelationship,
    required this.existingNodes,
  });

  static Future<QuickFamilyRelativeResult?> show(
    BuildContext context, {
    required FamilyTreeNode sourceNode,
    required String novelId,
    required String treeId,
    required FamilyRelationshipType defaultRelationship,
    required List<FamilyTreeNode> existingNodes,
  }) {
    return showDialog<QuickFamilyRelativeResult>(
      context: context,
      builder: (_) => QuickFamilyRelativeDialog(
        sourceNode: sourceNode,
        novelId: novelId,
        treeId: treeId,
        defaultRelationship: defaultRelationship,
        existingNodes: existingNodes,
      ),
    );
  }

  @override
  ConsumerState<QuickFamilyRelativeDialog> createState() =>
      _QuickFamilyRelativeDialogState();
}

class _QuickFamilyRelativeDialogState
    extends ConsumerState<QuickFamilyRelativeDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FamilyRelationshipType _selectedRelationship;

  // Form state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  String _gender = 'female';
  String _status = 'alive';

  // Existing selection
  FamilyTreeNode? _selectedExistingNode;
  CharacterModel? _selectedRosterCharacter;

  @override
  void initState() {
    super.initState();
    _selectedRelationship = widget.defaultRelationship;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  int _calculateTargetGeneration() {
    switch (_selectedRelationship) {
      case FamilyRelationshipType.parent:
      case FamilyRelationshipType.ancestor:
        return widget.sourceNode.generation - 1;
      case FamilyRelationshipType.child:
        return widget.sourceNode.generation + 1;
      case FamilyRelationshipType.spouse:
      case FamilyRelationshipType.sibling:
        return widget.sourceNode.generation;
      case FamilyRelationshipType.adoptive:
        return widget.sourceNode.generation + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.family_restroom,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isIndo ? "Tambah Kerabat untuk" : "Add Relative for"} "${widget.sourceNode.name}"',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isIndo
                              ? 'Pilih hubungan dan tentukan atau buat kerabat baru'
                              : 'Select relationship and choose or create relative',
                          style: AppTypography.labelSm
                              .copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Relationship selector chips
              Text(
                isIndo ? 'Tipe Hubungan' : 'Relationship Type',
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _relChip(FamilyRelationshipType.child, isIndo ? 'Anak (+1)' : 'Child (+1)',
                        const Color(0xFFD97706), c,),
                    _relChip(FamilyRelationshipType.spouse, isIndo ? 'Pasangan' : 'Spouse',
                        const Color(0xFFE11D48), c,),
                    _relChip(FamilyRelationshipType.parent, isIndo ? 'Orang Tua (-1)' : 'Parent (-1)',
                        const Color(0xFF2563EB), c,),
                    _relChip(FamilyRelationshipType.sibling, isIndo ? 'Saudara (=)' : 'Sibling (=)',
                        const Color(0xFF059669), c,),
                    _relChip(FamilyRelationshipType.ancestor, isIndo ? 'Leluhur' : 'Ancestor',
                        const Color(0xFF7C3AED), c,),
                    _relChip(FamilyRelationshipType.adoptive, isIndo ? 'Anak Angkat' : 'Adopted',
                        const Color(0xFF9333EA), c,),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Mode Tabs: Novel Roster, Tree Members, New Relative
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFD97706),
                unselectedLabelColor: c.textSecondary,
                indicatorColor: const Color(0xFFD97706),
                tabs: [
                  Tab(text: isIndo ? 'Daftar Karakter' : 'Novel Roster'),
                  Tab(text: isIndo ? 'Ada di Silsilah' : 'Existing on Tree'),
                  Tab(text: isIndo ? 'Kerabat Baru' : 'New Relative'),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNovelRosterTab(c, isIndo, l10n),
                    _buildExistingNodesTab(c, isIndo),
                    _buildNewRelativeTab(c, isIndo),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isIndo ? 'Batal' : 'Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Symbols.link, size: 18),
                    label: Text(isIndo ? 'Hubungkan Kerabat' : 'Connect Relative'),
                    onPressed: () => _handleSubmit(isIndo, l10n),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _relChip(
    FamilyRelationshipType rel,
    String label,
    Color color,
    AppColors c,
  ) {
    final isSelected = _selectedRelationship == rel;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : c.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: c.surfaceSecondary,
        selectedColor: color,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedRelationship = rel),
      ),
    );
  }

  Widget _buildNovelRosterTab(AppColors c, bool isIndo, AppLocalizations? l10n) {
    final charactersAsync =
        ref.watch(charactersStreamProvider(widget.novelId));

    return charactersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (characters) {
        final existingCharIds = widget.existingNodes
            .where((n) => n.characterId != null)
            .map((n) => n.characterId!)
            .toSet();

        final available = characters
            .where((ch) => !existingCharIds.contains(ch.id))
            .toList();

        if (available.isEmpty) {
          return Center(
            child: Text(
              isIndo
                  ? 'Semua karakter novel sudah ada di pohon silsilah ini.'
                  : 'All novel roster characters are already on this family tree.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: available.length,
          itemBuilder: (ctx, idx) {
            final ch = available[idx];
            final isSelected = _selectedRosterCharacter?.id == ch.id;

            return ListTile(
              dense: true,
              selected: isSelected,
              selectedTileColor:
                  const Color(0xFFD97706).withValues(alpha: 0.15),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFFD97706).withValues(alpha: 0.2),
                child: Text(
                  ch.name.isNotEmpty ? ch.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              title: Text(
                ch.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              subtitle: Text(
                ch.role.getLabel(l10n),
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
              trailing: isSelected
                  ? const Icon(Symbols.check_circle,
                      color: Color(0xFFD97706), size: 18,)
                  : null,
              onTap: () {
                setState(() => _selectedRosterCharacter = ch);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExistingNodesTab(AppColors c, bool isIndo) {
    final candidates = widget.existingNodes
        .where((n) => n.id != widget.sourceNode.id)
        .toList();

    if (candidates.isEmpty) {
      return Center(
        child: Text(
          isIndo
              ? 'Belum ada anggota lain di pohon silsilah ini.'
              : 'No other members on this family tree yet.',
          style: AppTypography.bodySm.copyWith(color: c.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: candidates.length,
      itemBuilder: (ctx, idx) {
        final node = candidates[idx];
        final isSelected = _selectedExistingNode?.id == node.id;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor:
              const Color(0xFFD97706).withValues(alpha: 0.15),
          leading: CircleAvatar(
            radius: 14,
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
          title: Text(
            node.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          subtitle: Text(
            '${isIndo ? "Gen" : "Gen"} ${node.generation} • ${node.titleOrRole ?? ""}',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
          trailing: isSelected
              ? const Icon(Symbols.check_circle,
                  color: Color(0xFFD97706), size: 18,)
              : null,
          onTap: () {
            setState(() => _selectedExistingNode = node);
          },
        );
      },
    );
  }

  Widget _buildNewRelativeTab(AppColors c, bool isIndo) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isIndo ? 'Nama Kerabat *' : 'Relative Name *',
              hintText: isIndo ? 'misalnya Ratu Yvaine' : 'e.g. Queen Yvaine',
              isDense: true,
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _roleController,
            decoration: InputDecoration(
              labelText: isIndo ? 'Gelar / Peran' : 'Title / Role',
              hintText: isIndo ? 'misalnya Permaisuri, Ahli Waris' : 'e.g. Queen Consort, Heir',
              isDense: true,
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Jenis Kelamin' : 'Gender',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'female', child: Text(isIndo ? 'Perempuan' : 'Female')),
                    DropdownMenuItem(value: 'male', child: Text(isIndo ? 'Laki-laki' : 'Male')),
                    DropdownMenuItem(value: 'other', child: Text(isIndo ? 'Lainnya' : 'Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Status' : 'Status',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'alive', child: Text(isIndo ? 'Hidup' : 'Alive')),
                    DropdownMenuItem(value: 'deceased', child: Text(isIndo ? 'Meninggal' : 'Deceased')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _yearsController,
            decoration: InputDecoration(
              labelText: isIndo ? 'Tahun / Rentang Usia' : 'Years / Life Span',
              hintText: isIndo ? 'misalnya 1020 - 1084' : 'e.g. 1020 - 1084',
              isDense: true,
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(bool isIndo, AppLocalizations? l10n) {
    final activeTab = _tabController.index;
    final targetGen = _calculateTargetGeneration();

    final coords = _calculateSmartCoordinates();

    if (activeTab == 0) {
      // Novel roster
      if (_selectedRosterCharacter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Silakan pilih karakter novel'
                  : 'Please select a novel character',
            ),
          ),
        );
        return;
      }
      final node = FamilyTreeNode(
        id: generateUuid(),
        treeId: widget.treeId,
        characterId: _selectedRosterCharacter!.id,
        name: _selectedRosterCharacter!.name,
        titleOrRole: _selectedRosterCharacter!.role.getLabel(l10n),
        generation: targetGen,
        gender: _selectedRosterCharacter!.gender,
        avatarPath: _selectedRosterCharacter!.portraitPath,
        x: coords.dx,
        y: coords.dy,
      );
      Navigator.of(context).pop(
        QuickFamilyRelativeResult(
          node: node,
          relationship: _selectedRelationship,
        ),
      );
    } else if (activeTab == 1) {
      // Existing tree node
      if (_selectedExistingNode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Silakan pilih anggota yang ada'
                  : 'Please select an existing member',
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(
        QuickFamilyRelativeResult(
          node: _selectedExistingNode!,
          relationship: _selectedRelationship,
          isExistingNode: true,
        ),
      );
    } else {
      // New relative
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Silakan masukkan nama kerabat'
                  : 'Please enter a name for the relative',
            ),
          ),
        );
        return;
      }
      final node = FamilyTreeNode(
        id: generateUuid(),
        treeId: widget.treeId,
        name: name,
        titleOrRole: _roleController.text.trim().isEmpty
            ? (isIndo ? 'Kerabat' : 'Relative')
            : _roleController.text.trim(),
        generation: targetGen,
        gender: _gender,
        status: _status,
        years: _yearsController.text.trim().isEmpty
            ? null
            : _yearsController.text.trim(),
        x: coords.dx,
        y: coords.dy,
      );
      Navigator.of(context).pop(
        QuickFamilyRelativeResult(
          node: node,
          relationship: _selectedRelationship,
        ),
      );
    }
  }

  Offset _calculateSmartCoordinates() {
    double x = widget.sourceNode.x;
    double y = widget.sourceNode.y;

    switch (_selectedRelationship) {
      case FamilyRelationshipType.spouse:
        final spouses = widget.existingNodes
            .where(
              (n) =>
                  n.generation == widget.sourceNode.generation &&
                  n.x > widget.sourceNode.x,
            )
            .length;
        x = widget.sourceNode.x + 280.0 + (spouses * 60.0);
        y = widget.sourceNode.y;
        break;
      case FamilyRelationshipType.sibling:
        final siblings = widget.existingNodes
            .where(
              (n) =>
                  n.generation == widget.sourceNode.generation &&
                  n.id != widget.sourceNode.id,
            )
            .length;
        x = widget.sourceNode.x + 280.0 + (siblings * 60.0);
        y = widget.sourceNode.y;
        break;
      case FamilyRelationshipType.child:
      case FamilyRelationshipType.adoptive:
        final childrenInGen = widget.existingNodes
            .where((n) => n.generation == widget.sourceNode.generation + 1)
            .length;
        x = widget.sourceNode.x + (childrenInGen * 80.0);
        y = widget.sourceNode.y + 200.0;
        break;
      case FamilyRelationshipType.parent:
      case FamilyRelationshipType.ancestor:
        final parentsInGen = widget.existingNodes
            .where((n) => n.generation == widget.sourceNode.generation - 1)
            .length;
        x = widget.sourceNode.x + (parentsInGen * 80.0);
        y = widget.sourceNode.y - 200.0;
        break;
    }
    return Offset(x, y);
  }
}
