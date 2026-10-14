import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../application/family_tree_providers.dart';
import '../../domain/models/family_tree_models.dart';
import '../widgets/add_family_member_dialog.dart';
import '../widgets/create_family_tree_dialog.dart';
import '../widgets/family_tree_canvas.dart';
import '../widgets/family_tree_node_inspector.dart';
import '../widgets/family_tree_outline_view.dart';
import '../widgets/family_tree_summary_dialog.dart';

enum FamilyTreeViewMode { canvas, outline }

class FamilyTreeScreen extends ConsumerStatefulWidget {
  final String? initialNovelId;
  final String? initialTreeId;
  final String? initialNodeId;

  const FamilyTreeScreen({
    super.key,
    this.initialNovelId,
    this.initialTreeId,
    this.initialNodeId,
  });

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final TransformationController _transformationController =
      TransformationController();
  String? _selectedNovelId;
  bool _isSearching = false;
  FamilyTreeViewMode _viewMode = FamilyTreeViewMode.canvas;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedNovelId = widget.initialNovelId;
    if (widget.initialTreeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final novelId = widget.initialNovelId ?? _selectedNovelId;
        if (novelId != null && novelId.isNotEmpty) {
          ref
              .read(activeFamilyTreeIdProvider(novelId).notifier)
              .state = widget.initialTreeId;
        }
        if (widget.initialNodeId != null) {
          ref.read(selectedFamilyTreeNodeIdProvider.notifier).state =
              widget.initialNodeId;
        }
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final novelListAsync = ref.watch(novelListStreamProvider);
    final activeNovelAsync = ref.watch(activeNovelProvider);

    return novelListAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (novels) {
        if (novels.isEmpty) {
          return Scaffold(
            appBar: NvAppBar(title: isIndo ? 'Pohon Silsilah' : 'Family Tree'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.family_restroom, size: 54, color: c.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      isIndo ? 'Tidak Ada Novel Tersedia' : 'No Novels Available',
                      style: AppTypography.screenTitle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIndo
                          ? 'Buat novel terlebih dahulu untuk menyusun garis keturunan karakter dan silsilah dinasti.'
                          : 'Create a novel first to build character lineages and dynasty family trees.',
                      style:
                          AppTypography.bodySm.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final activeNovel = activeNovelAsync.valueOrNull;
        final currentNovelId = _selectedNovelId ??
            (activeNovel?.id ?? novels.first.id);

        final selectedNovel = novels.firstWhere(
          (n) => n.id == currentNovelId,
          orElse: () => novels.first,
        );

        final treesAsync = ref.watch(familyTreesProvider(currentNovelId));
        final activeTree = ref.watch(currentFamilyTreeProvider(currentNovelId));
        final selectedNodeId = ref.watch(selectedFamilyTreeNodeIdProvider);

        return Scaffold(
          appBar: NvAppBar(
            title: isIndo ? 'Pohon Silsilah' : 'Family Tree',
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentNovelId,
                    isDense: true,
                    dropdownColor: c.surface,
                    icon: const Icon(Symbols.arrow_drop_down,
                        color: Color(0xFFD97706), size: 18,),
                    style: AppTypography.labelMd.copyWith(
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w600,
                    ),
                    items: novels.map((n) {
                      return DropdownMenuItem<String>(
                        value: n.id,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            n.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedNovelId = val;
                          _isSearching = false;
                          _searchController.clear();
                        });
                        ref.read(familyTreeSearchQueryProvider.notifier).state = '';
                        ref.read(selectedFamilyTreeNodeIdProvider.notifier).state =
                            null;
                      }
                    },
                  ),
                ),
              ),
            ),
            actions: [
              const SizedBox(width: AppSpacing.sm),
              // Search toggle
              IconButton(
                icon: Icon(
                  _isSearching ? Symbols.close : Symbols.search,
                  color: _isSearching ? const Color(0xFFD97706) : null,
                ),
                tooltip: _isSearching
                    ? (isIndo ? 'Tutup Pencarian' : 'Close Search')
                    : (isIndo ? 'Cari Garis Keturunan' : 'Search Lineage'),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(familyTreeSearchQueryProvider.notifier).state =
                          '';
                    }
                  });
                },
              ),

              // Auto-Organize Layout
              if (activeTree != null)
                IconButton(
                  icon: const Icon(Symbols.auto_fix_high),
                  tooltip: isIndo ? 'Tata Otomatis Tata Letak Silsilah' : 'Auto-Organize Lineage Layout',
                  onPressed: () {
                    ref
                        .read(familyTreesProvider(currentNovelId).notifier)
                        .autoOrganize(activeTree.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isIndo
                              ? 'Berhasil menata ulang silsilah keluarga berdasarkan generasi'
                              : 'Reorganized family lineage by generations cleanly',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

              // Lineage summary
              if (activeTree != null)
                IconButton(
                  icon: const Icon(Symbols.summarize),
                  tooltip: isIndo ? 'Ringkasan Silsilah' : 'Lineage Summary',
                  onPressed: () {
                    FamilyTreeSummaryDialog.show(
                      context,
                      tree: activeTree,
                      novelTitle: selectedNovel.title,
                    );
                  },
                ),

              // More options
              PopupMenuButton<String>(
                icon: const Icon(Symbols.more_vert),
                tooltip: isIndo ? 'Opsi Silsilah' : 'Tree Options',
                onSelected: (val) {
                  if (val == 'add_tree') {
                    _showCreateTreeDialog(currentNovelId);
                  } else if (val == 'rename_tree' && activeTree != null) {
                    _showRenameTreeDialog(currentNovelId, activeTree);
                  } else if (val == 'delete_tree' && activeTree != null) {
                    _confirmDeleteTree(currentNovelId, activeTree);
                  } else if (val == 'recenter') {
                    _transformationController.value = Matrix4.identity();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'add_tree',
                    child: Row(
                      children: [
                        const Icon(Symbols.add_circle,
                            size: 18, color: Color(0xFFD97706),),
                        const SizedBox(width: 8),
                        Text(isIndo ? 'Tambah Pohon Silsilah…' : 'Add Family Tree…'),
                      ],
                    ),
                  ),
                  if (activeTree != null) ...[
                    PopupMenuItem(
                      value: 'rename_tree',
                      child: Row(
                        children: [
                          const Icon(Symbols.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(isIndo ? 'Ubah Nama Pohon Saat Ini' : 'Rename Current Tree'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'recenter',
                      child: Row(
                        children: [
                          const Icon(Symbols.filter_center_focus, size: 18),
                          const SizedBox(width: 8),
                          Text(isIndo ? 'Pusatkan Tampilan' : 'Recenter View'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete_tree',
                      child: Row(
                        children: [
                          const Icon(Symbols.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            isIndo ? 'Hapus Pohon Silsilah' : 'Delete Family Tree',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: treesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading trees: $e')),
            data: (trees) {
              return Column(
                children: [
                  // Tree Selector Header with "Add Family Tree" button
                  _buildTreeSelectorBar(trees, activeTree, currentNovelId, c, isIndo),

                  // Optional Search Banner
                  if (_isSearching) _buildSearchBar(c, isIndo),

                  // Canvas, Outline, or Empty State
                  Expanded(
                    child: activeTree == null
                        ? _buildNoTreesEmptyState(currentNovelId, c, isIndo)
                        : (activeTree.nodes.isEmpty
                            ? _buildEmptyTreeCanvas(
                                activeTree, currentNovelId, c, isIndo,)
                            : (_viewMode == FamilyTreeViewMode.outline
                                ? FamilyTreeOutlineView(
                                    tree: activeTree,
                                    novelId: currentNovelId,
                                    onSelectNode: (node) => _showNodeInspector(
                                      node,
                                      activeTree,
                                      currentNovelId,
                                    ),
                                    onFocusOnCanvas: (node) {
                                      setState(() {
                                        _viewMode = FamilyTreeViewMode.canvas;
                                      });
                                      ref
                                          .read(selectedFamilyTreeNodeIdProvider
                                              .notifier,)
                                          .state = node.id;
                                      _focusOnNodeOnCanvas(node);
                                    },
                                    onAddMember: () => _showAddMemberModal(
                                      currentNovelId,
                                      activeTree,
                                    ),
                                  )
                                : FamilyTreeCanvas(
                                    tree: activeTree,
                                    novelId: currentNovelId,
                                    transformationController:
                                        _transformationController,
                                    onSelectNode: (node) => _showNodeInspector(
                                      node,
                                      activeTree,
                                      currentNovelId,
                                    ),
                                    onDeselect: () {},
                                  ))),
                  ),
                ],
              );
            },
          ),
          // Positioned at startFloat when no member is selected so it never collides with zoom buttons.
          // Automatically hides when a member is selected so it NEVER obscures +Child, +Spouse, +Parent navigation!
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: (activeTree == null || selectedNodeId != null)
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'family_tree_add_member_fab',
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  icon: const Icon(Symbols.person_add),
                  label: Text(isIndo ? 'Tambah Anggota' : 'Add Member'),
                  onPressed: () =>
                      _showAddMemberModal(currentNovelId, activeTree),
                ),
        );
      },
    );
  }

  Widget _buildTreeSelectorBar(
    List<FamilyTree> trees,
    FamilyTree? activeTree,
    String novelId,
    AppColors c,
    bool isIndo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Symbols.family_restroom,
                size: 20, color: Color(0xFFD97706),),
            const SizedBox(width: 8),

            // Active Tree Dropdown / Selector
            if (trees.isNotEmpty && activeTree != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.outlineVariant, width: 0.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeTree.id,
                    isDense: true,
                    dropdownColor: c.surface,
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                    items: trees.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.name),
                            const SizedBox(width: 6),
                            Text(
                              '(${t.nodes.length} ${isIndo ? "anggota" : "members"})',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(activeFamilyTreeIdProvider(novelId).notifier)
                            .state = val;
                        ref.read(selectedFamilyTreeNodeIdProvider.notifier).state =
                            null;
                      }
                    },
                  ),
                ),
              ),
            ] else ...[
              Text(
                isIndo ? 'Belum Ada Pohon Silsilah' : 'No Family Trees Yet',
                style: AppTypography.bodySm.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // View Mode Segmented Switcher (Canvas vs. Dynasty Outline)
            if (activeTree != null) ...[
              const SizedBox(width: 8),
              SegmentedButton<FamilyTreeViewMode>(
                showSelectedIcon: true,
                selectedIcon: const Icon(
                  Symbols.check,
                  size: 15,
                  color: Color(0xFFD97706),
                ),
                segments: [
                  ButtonSegment(
                    value: FamilyTreeViewMode.canvas,
                    icon: const Icon(Symbols.account_tree, size: 15),
                    label: Text(isIndo ? 'Kanvas' : 'Canvas'),
                  ),
                  ButtonSegment(
                    value: FamilyTreeViewMode.outline,
                    icon: const Icon(Symbols.checklist, size: 15),
                    label: Text(isIndo ? 'Bagan Dinasti' : 'Dynasty Outline'),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (set) {
                  setState(() {
                    _viewMode = set.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.standard,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedForegroundColor: const Color(0xFFD97706),
                  selectedBackgroundColor:
                      const Color(0xFFD97706).withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // "+ Add Member" Button (accessible from toolbar, avoids canvas obscuring)
            if (activeTree != null) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Symbols.person_add, size: 16),
                label: Text(isIndo ? 'Tambah Anggota' : 'Add Member'),
                onPressed: () => _showAddMemberModal(novelId, activeTree),
              ),
              const SizedBox(width: 8),
            ],

            // "+ Add Family Tree" Button
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Symbols.add, size: 16),
              label: Text(isIndo ? 'Tambah Pohon Silsilah' : 'Add Family Tree'),
              onPressed: () => _showCreateTreeDialog(novelId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppColors c, bool isIndo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: c.surface,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: isIndo
              ? 'Saring anggota keluarga berdasarkan nama atau gelar...'
              : 'Filter family members by name or title...',
          prefixIcon: const Icon(Symbols.search, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Symbols.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(familyTreeSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: c.surfaceSecondary,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          ref.read(familyTreeSearchQueryProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildNoTreesEmptyState(String novelId, AppColors c, bool isIndo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                Symbols.family_restroom,
                size: 48,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isIndo ? 'Belum Ada Pohon Silsilah Dibuat' : 'No Family Trees Created',
              style: AppTypography.screenTitle
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isIndo
                    ? 'Buat pohon silsilah terpisah untuk karakter atau dinasti berbeda (misalnya Garis Keturunan Elena, Wangsa Valerius).'
                    : 'Create distinct family trees for different characters or dynasties (e.g. Elena\'s Lineage, House Valerius).',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Symbols.add),
              label: Text(isIndo ? 'Tambah Pohon Silsilah' : 'Add Family Tree'),
              onPressed: () => _showCreateTreeDialog(novelId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTreeCanvas(
    FamilyTree tree,
    String novelId,
    AppColors c,
    bool isIndo,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.account_tree,
                size: 40,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${tree.name} ${isIndo ? "Masih Kosong" : "is Empty"}',
              style: AppTypography.screenTitle
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isIndo
                    ? 'Mulai petakan dinastimu dengan templat awal cepat atau tambahkan karakter secara manual.'
                    : 'Start charting your dynasty with a quick starter template or add characters manually.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                        isIndo ? 'Templat Dinasti Instan 1-Klik' : '1-Click Starter Dynasty Templates',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _starterTemplateTile(
                        icon: Symbols.person,
                        title: isIndo ? 'Pendiri Tunggal' : 'Solo Founder',
                        subtitle: isIndo ? 'Satu patriark atau matriark pendiri' : 'Single founding patriarch or matriarch',
                        onTap: () =>
                            _applyStarterTemplate(novelId, tree.id, 'solo'),
                      ),
                      const SizedBox(height: 8),
                      _starterTemplateTile(
                        icon: Symbols.favorite,
                        title: isIndo ? 'Pasangan Pendiri' : 'Founder Couple',
                        subtitle: isIndo ? 'Patriark & Matriark terhubung sebagai pasangan' : 'Patriarch & Matriarch connected as spouses',
                        onTap: () =>
                            _applyStarterTemplate(novelId, tree.id, 'couple'),
                      ),
                      const SizedBox(height: 8),
                      _starterTemplateTile(
                        icon: Symbols.family_restroom,
                        title: isIndo ? 'Dinasti Tiga Generasi' : 'Three Generations Dynasty',
                        subtitle: isIndo
                            ? 'Pendiri -> Ahli Waris Sulung -> Cucu siap diedit'
                            : 'Founders -> Firstborn Heir -> Grandchild ready to edit',
                        onTap: () =>
                            _applyStarterTemplate(novelId, tree.id, 'dynasty'),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Symbols.person_add),
                        label: Text(isIndo ? 'Tambah Anggota Manual' : 'Add Member Manually'),
                        onPressed: () => _showAddMemberModal(novelId, tree),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starterTemplateTile({
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

  Future<void> _applyStarterTemplate(
    String novelId,
    String treeId,
    String templateType,
  ) async {
    final notifier = ref.read(familyTreesProvider(novelId).notifier);
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    await notifier.applyStarterTemplate(treeId, templateType);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndo
                ? 'Berhasil memuat templat silsilah dinasti awal!'
                : 'Populated starter dynasty lineage template!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _focusOnNodeOnCanvas(FamilyTreeNode node) {
    final media = MediaQuery.of(context).size;
    const scale = 1.0;
    final targetX = (media.width / 2) - (node.x + 110) * scale;
    final targetY = (media.height / 2) - (node.y + 55) * scale;

    _transformationController.value = Matrix4.identity()
      ..scale(scale)
      ..setTranslationRaw(targetX, targetY, 0.0);
  }

  Future<void> _showCreateTreeDialog(String novelId) async {
    final result = await CreateFamilyTreeDialog.show(context, novelId);
    if (result != null && mounted) {
      final l10n = AppLocalizations.of(context);
      final isIndo = l10n?.localeName == 'id';

      // Parse description string encoded metadata if root character was selected
      String? rootName;
      String? rootRole;
      String? rootGender;
      String? rootAvatar;
      String? rootCharId;

      if (result.description != null &&
          result.description!.startsWith('ROOT:')) {
        final parts = result.description!.split('|');
        for (final p in parts) {
          if (p.startsWith('ROOT:')) rootName = p.substring(5);
          if (p.startsWith('ROLE:')) rootRole = p.substring(5);
          if (p.startsWith('GENDER:')) rootGender = p.substring(7);
          if (p.startsWith('AVATAR:')) rootAvatar = p.substring(7);
          if (p.startsWith('CHARID:')) rootCharId = p.substring(7);
        }
      }

      await ref.read(familyTreesProvider(novelId).notifier).createTree(
            name: result.name,
            description: null,
            rootCharacterId: rootCharId,
            rootCharacterName: rootName,
            rootRole: rootRole,
            rootGender: rootGender,
            rootAvatarPath: rootAvatar,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isIndo ? "Berhasil membuat Pohon Silsilah" : "Created Family Tree"} "${result.name}"',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRenameTreeDialog(
    String novelId,
    FamilyTree tree,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller = TextEditingController(text: tree.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Ubah Nama Pohon Silsilah' : 'Rename Family Tree'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isIndo ? 'Nama Pohon Silsilah' : 'Family Tree Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(isIndo ? 'Simpan' : 'Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await ref
          .read(familyTreesProvider(novelId).notifier)
          .renameTree(tree.id, newName);
    }
  }

  Future<void> _confirmDeleteTree(
    String novelId,
    FamilyTree tree,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isIndo ? "Hapus" : "Delete"} "${tree.name}"?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus pohon silsilah ini? Semua simpul garis keturunan di pohon ini akan dihapus.'
              : 'Are you sure you want to delete this family tree? This will remove all lineage nodes in this tree.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isIndo ? 'Hapus' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(familyTreesProvider(novelId).notifier)
          .deleteTree(tree.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isIndo ? "Dihapus" : "Deleted"} "${tree.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddMemberModal(
    String novelId,
    FamilyTree tree,
  ) async {
    final existingCharIds = tree.nodes
        .where((n) => n.characterId != null)
        .map((n) => n.characterId!)
        .toSet();

    final newMember = await AddFamilyMemberDialog.show(
      context,
      novelId: novelId,
      treeId: tree.id,
      existingCharacterIds: existingCharIds,
    );

    if (newMember != null && mounted) {
      final l10n = AppLocalizations.of(context);
      final isIndo = l10n?.localeName == 'id';
      final notifier = ref.read(familyTreesProvider(novelId).notifier);
      await notifier.addMember(tree.id, newMember);
      ref.read(selectedFamilyTreeNodeIdProvider.notifier).state = newMember.id;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isIndo ? "Menambahkan" : "Added"} "${newMember.name}" ${isIndo ? "ke" : "to"} ${tree.name}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showNodeInspector(
    FamilyTreeNode node,
    FamilyTree tree,
    String novelId,
  ) {
    final notifier = ref.read(familyTreesProvider(novelId).notifier);
    final connectedEdges = tree.edges
        .where((e) => e.fromNodeId == node.id || e.toNodeId == node.id)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyTreeNodeInspector(
        node: node,
        allNodes: tree.nodes,
        connectedEdges: connectedEdges,
        onClose: () => Navigator.of(context).pop(),
        onChangeGeneration: (newGen) async {
          await notifier.updateMember(
              tree.id, node.copyWith(generation: newGen),);
        },
        onDeleteEdge: (edgeId) async {
          await notifier.removeRelationship(tree.id, edgeId);
        },
        onDeleteNode: () async {
          await notifier.removeMember(tree.id, node.id);
          if (mounted) Navigator.of(context).pop();
        },
        onSaveNode: (updated) async {
          await notifier.updateMember(tree.id, updated);
        },
      ),
    );
  }
}
