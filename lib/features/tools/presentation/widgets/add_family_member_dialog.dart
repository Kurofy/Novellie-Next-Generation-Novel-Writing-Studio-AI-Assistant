import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../characters/application/character_providers.dart';
import '../../domain/models/family_tree_models.dart';

class AddFamilyMemberDialog extends ConsumerStatefulWidget {
  final String novelId;
  final String treeId;
  final Set<String> existingCharacterIds;
  final int defaultGeneration;

  const AddFamilyMemberDialog({
    super.key,
    required this.novelId,
    required this.treeId,
    required this.existingCharacterIds,
    this.defaultGeneration = 0,
  });

  static Future<FamilyTreeNode?> show(
    BuildContext context, {
    required String novelId,
    required String treeId,
    required Set<String> existingCharacterIds,
    int defaultGeneration = 0,
  }) {
    return showDialog<FamilyTreeNode>(
      context: context,
      builder: (_) => AddFamilyMemberDialog(
        novelId: novelId,
        treeId: treeId,
        existingCharacterIds: existingCharacterIds,
        defaultGeneration: defaultGeneration,
      ),
    );
  }

  @override
  ConsumerState<AddFamilyMemberDialog> createState() =>
      _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends ConsumerState<AddFamilyMemberDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Custom Relative form state
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customYearsController = TextEditingController();
  final TextEditingController _customNotesController = TextEditingController();
  late int _generation;
  String _gender = 'female';
  String _status = 'alive';

  @override
  void initState() {
    super.initState();
    _generation = widget.defaultGeneration;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customNameController.dispose();
    _customTitleController.dispose();
    _customYearsController.dispose();
    _customNotesController.dispose();
    super.dispose();
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Icon(Symbols.family_restroom,
                      color: Color(0xFFD97706), size: 24,),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isIndo ? 'Tambah Anggota Keluarga' : 'Add Family Member',
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar: Novel Character vs Custom Relative
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFD97706),
              unselectedLabelColor: c.textSecondary,
              indicatorColor: const Color(0xFFD97706),
              tabs: [
                Tab(
                  icon: const Icon(Symbols.group, size: 18),
                  text: isIndo ? 'Karakter Novel' : 'Novel Characters',
                ),
                Tab(
                  icon: const Icon(Symbols.person_add, size: 18),
                  text: isIndo ? 'Kerabat Kustom' : 'Custom Relative',
                ),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNovelCharactersTab(c, isIndo, l10n),
                  _buildCustomRelativeTab(c, isIndo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNovelCharactersTab(AppColors c, bool isIndo, AppLocalizations? l10n) {
    final charactersAsync =
        ref.watch(charactersStreamProvider(widget.novelId));

    return charactersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (characters) {
        final query = _searchController.text.trim().toLowerCase();
        final filtered = characters.where((char) {
          final matchesQuery = query.isEmpty ||
              char.name.toLowerCase().contains(query) ||
              char.role.label.toLowerCase().contains(query);
          return matchesQuery;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isIndo ? 'Cari karakter di novel...' : 'Search characters in novel...',
                  prefixIcon: const Icon(Symbols.search, size: 20),
                  filled: true,
                  fillColor: c.surfaceSecondary,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        isIndo ? 'Karakter tidak ditemukan' : 'No matching characters found',
                        style: AppTypography.bodySm
                            .copyWith(color: c.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final char = filtered[idx];
                        final isAlreadyAdded =
                            widget.existingCharacterIds.contains(char.id);

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFD97706)
                                .withValues(alpha: 0.15),
                            child: Text(
                              char.name.isNotEmpty
                                  ? char.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            char.name,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            char.role.getLabel(l10n),
                            style: AppTypography.labelSm
                                .copyWith(color: c.textSecondary),
                          ),
                          trailing: isAlreadyAdded
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4,),
                                  decoration: BoxDecoration(
                                    color: c.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill,),
                                  ),
                                  child: Text(
                                    isIndo ? 'Ada di Silsilah' : 'In Tree',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.textMuted,
                                    ),
                                  ),
                                )
                              : FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(isIndo ? 'Tambah' : 'Add'),
                                  onPressed: () {
                                    final node = FamilyTreeNode(
                                      id: generateUuid(),
                                      treeId: widget.treeId,
                                      characterId: char.id,
                                      name: char.name,
                                      titleOrRole: char.role.getLabel(l10n),
                                      generation: _generation,
                                      gender: char.gender,
                                      avatarPath: char.portraitPath,
                                      status: 'alive',
                                      x: 400.0,
                                      y: 300.0,
                                    );
                                    Navigator.of(context).pop(node);
                                  },
                                ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomRelativeTab(AppColors c, bool isIndo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _customNameController,
            decoration: InputDecoration(
              labelText: isIndo ? 'Nama Kerabat *' : 'Relative Name *',
              hintText: isIndo ? 'misalnya Putri Genevieve, Pangeran Lucian' : 'e.g. Lady Genevieve, Prince Lucian',
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customTitleController,
            decoration: InputDecoration(
              labelText: isIndo ? 'Gelar / Peran Keluarga' : 'Family Title / Role',
              hintText: isIndo ? 'misalnya Matriark, Ahli Waris, Putri Sulung, Pasangan' : 'e.g. Matriarch, Heir, Eldest Daughter, Consort',
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _generation,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Generasi' : 'Generation',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: -2,
                      child: Text(isIndo ? '-2: Kakek / Nenek' : '-2: Grandparents'),
                    ),
                    DropdownMenuItem(
                      value: -1,
                      child: Text(isIndo ? '-1: Orang Tua' : '-1: Parents'),
                    ),
                    DropdownMenuItem(
                      value: 0,
                      child: Text(isIndo ? '0: Pendiri / Utama' : '0: Founder / Root'),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(isIndo ? '+1: Anak' : '+1: Children'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(isIndo ? '+2: Cucu' : '+2: Grandchildren'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _generation = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Jenis Kelamin' : 'Gender',
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(isIndo ? 'Perempuan' : 'Female'),
                    ),
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(isIndo ? 'Laki-laki' : 'Male'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(isIndo ? 'Lainnya' : 'Other'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customYearsController,
                  decoration: InputDecoration(
                    labelText: isIndo ? 'Tahun / Rentang Usia' : 'Years / Life Span',
                    hintText: isIndo ? 'misalnya 1045 - 1102' : 'e.g. 1045 - 1102',
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
                    labelText: isIndo ? 'Status' : 'Status',
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
          TextField(
            controller: _customNotesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isIndo ? 'Catatan Silsilah / Lore' : 'Lineage Notes / Lore',
              hintText: isIndo
                  ? 'Tambahkan biografi, sifat leluhur, atau klaim suksesi...'
                  : 'Add biography, ancestral traits, or succession claims...',
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Symbols.add, size: 18),
            label: Text(isIndo ? 'Tambah Kerabat ke Silsilah' : 'Add Relative to Tree'),
            onPressed: () {
              final name = _customNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isIndo
                          ? 'Silakan masukkan nama kerabat'
                          : 'Please enter a name for the relative',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final node = FamilyTreeNode(
                id: generateUuid(),
                treeId: widget.treeId,
                name: name,
                titleOrRole: _customTitleController.text.trim().isEmpty
                    ? (isIndo ? 'Kerabat' : 'Relative')
                    : _customTitleController.text.trim(),
                generation: _generation,
                gender: _gender,
                status: _status,
                years: _customYearsController.text.trim().isEmpty
                    ? null
                    : _customYearsController.text.trim(),
                notes: _customNotesController.text.trim().isEmpty
                    ? null
                    : _customNotesController.text.trim(),
                x: 400.0,
                y: 300.0,
              );
              Navigator.of(context).pop(node);
            },
          ),
        ],
      ),
    );
  }
}
