import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../application/mind_map_providers.dart';
import '../../domain/models/mind_map_models.dart';
import '../widgets/add_connection_dialog.dart';
import '../widgets/add_node_dialog.dart';
import '../widgets/mind_map_canvas.dart';
import '../widgets/mind_map_node_inspector.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final String? initialNovelId;

  const MindMapScreen({super.key, this.initialNovelId});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  String? _selectedNovelId;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedNovelId = widget.initialNovelId;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final novelListAsync = ref.watch(novelListStreamProvider);
    final activeNovelAsync = ref.watch(activeNovelProvider);

    return novelListAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(isIndo ? 'Gagal: $e' : 'Error: $e'))),
      data: (novels) {
        if (novels.isEmpty) {
          return Scaffold(
            appBar: NvAppBar(title: isIndo ? 'Peta Pikiran' : 'Mind Map'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.hub, size: 54, color: c.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      isIndo ? 'Tidak Ada Novel yang Tersedia' : 'No Novels Available',
                      style: AppTypography.screenTitle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIndo
                          ? 'Buat novel terlebih dahulu untuk melakukan curah pendapat ide, urutan bab, dan alur cerita.'
                          : 'Create a novel first to brainstorm ideas, chapter sequences, and story arcs.',
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

        // Determine effective novelId
        final activeNovel = activeNovelAsync.valueOrNull;
        final currentNovelId = _selectedNovelId ??
            (activeNovel?.id ?? novels.first.id);

        final graphAsync = ref.watch(mindMapGraphProvider(currentNovelId));
        final activeFilter = ref.watch(mindMapTypeFilterProvider);
        final selectedNodeId = ref.watch(selectedMindMapNodeIdProvider);

        return Scaffold(
          appBar: NvAppBar(
            title: isIndo ? 'Peta Pikiran' : 'Mind Map',
            subtitle: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentNovelId,
                isDense: true,
                dropdownColor: c.surface,
                icon:
                    Icon(Symbols.arrow_drop_down, color: c.primary, size: 18),
                style: AppTypography.bodySm.copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w600,
                ),
                items: novels.map((n) {
                  return DropdownMenuItem<String>(
                    value: n.id,
                    child: Text(n.title),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedNovelId = val;
                      _isSearching = false;
                      _searchController.clear();
                    });
                    ref.read(mindMapSearchQueryProvider.notifier).state = '';
                    ref.read(selectedMindMapNodeIdProvider.notifier).state =
                        null;
                  }
                },
              ),
            ),
            actions: [
              // Search toggle
              IconButton(
                icon: Icon(
                  _isSearching ? Symbols.close : Symbols.search,
                  color: _isSearching ? c.primary : null,
                ),
                tooltip: _isSearching
                    ? (isIndo ? 'Tutup Pencarian' : 'Close Search')
                    : (isIndo ? 'Cari Diagram' : 'Search Diagram'),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(mindMapSearchQueryProvider.notifier).state = '';
                    }
                  });
                },
              ),

              // Auto-Tidy / Layout Button
              IconButton(
                icon: const Icon(Symbols.auto_fix_high),
                tooltip: isIndo ? 'Rapikan Alur Cerita Otomatis' : 'Auto-Organize Story Flow',
                onPressed: () {
                  ref
                      .read(mindMapGraphProvider(currentNovelId).notifier)
                      .autoOrganizeStoryFlow();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isIndo
                          ? 'Alur cerita dan bab diurutkan secara rapi'
                          : 'Sequenced story flow and chapters cleanly'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // More Options Menu
              PopupMenuButton<String>(
                icon: const Icon(Symbols.more_vert),
                tooltip: isIndo ? 'Opsi Lainnya' : 'More Options',
                onSelected: (val) {
                  final notifier =
                      ref.read(mindMapGraphProvider(currentNovelId).notifier);
                  if (val == 'brainstorm_radial') {
                    notifier.autoOrganizeBrainstorm();
                  } else if (val == 'recenter') {
                    _transformationController.value = Matrix4.identity();
                  } else if (val == 'clear') {
                    _confirmClearCanvas(currentNovelId);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'brainstorm_radial',
                    child: Row(
                      children: [
                        const Icon(Symbols.bubble_chart, size: 18),
                        const SizedBox(width: 8),
                        Text(isIndo
                            ? 'Konstelasi Curah Pendapat Radial'
                            : 'Radial Brainstorm Constellation'),
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
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Symbols.delete_sweep, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(isIndo ? 'Bersihkan Kanvas' : 'Clear Canvas',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: graphAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(isIndo ? 'Gagal memuat diagram: $e' : 'Error loading diagram: $e')),
            data: (graph) {
              return Column(
                children: [
                  // Category Filter Bar (All, Brainstorm, Story Arcs, Chapters, Plot Points)
                  _buildCategoryFilterBar(activeFilter, graph, currentNovelId, c),

                  // Optional Search bar banner
                  if (_isSearching) _buildSearchBar(c),

                  // Interactive Canvas or Empty State
                  Expanded(
                    child: graph.nodes.isEmpty
                        ? _buildEmptyCanvas(currentNovelId, c)
                        : MindMapCanvas(
                            graph: graph,
                            novelId: currentNovelId,
                            transformationController: _transformationController,
                            onSelectNode: (node) => _showNodeInspector(
                              node,
                              graph,
                              currentNovelId,
                            ),
                            onDeselect: () {},
                          ),
                  ),
                ],
              );
            },
          ),
          // Positioned at startFloat when no node is selected so it never collides with zoom buttons at right: 16.
          // Automatically hides when a node is selected so it NEVER obscures +Next Beat, +Sub-Arc, Connect dock!
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: selectedNodeId != null
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'mind_map_add_node_fab',
                  icon: const Icon(Symbols.add),
                  label: Text(isIndo ? 'Tambah Simpul' : 'Add Node'),
                  onPressed: () => _showAddNodeModal(currentNovelId),
                ),
        );
      },
    );
  }

  Widget _buildCategoryFilterBar(
    MindMapNodeType? activeFilter,
    MindMapGraph graph,
    String novelId,
    AppColors c,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: '${isIndo ? 'Semua' : 'All'} (${graph.nodes.length})',
                    isSelected: activeFilter == null,
                    onSelected: () {
                      ref.read(mindMapTypeFilterProvider.notifier).state = null;
                    },
                    c: c,
                  ),
                  const SizedBox(width: 6),
                  ...MindMapNodeType.values.map((type) {
                    final count =
                        graph.nodes.where((n) => n.type == type).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _filterChip(
                        label: '${type.localizedLabel(isIndo)} ($count)',
                        isSelected: activeFilter == type,
                        onSelected: () {
                          ref.read(mindMapTypeFilterProvider.notifier).state =
                              activeFilter == type ? null : type;
                        },
                        c: c,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // "+ Add Node" Button in toolbar (accessible even when a node is selected)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Symbols.add, size: 16),
            label: Text(isIndo ? 'Tambah Simpul' : 'Add Node'),
            onPressed: () => _showAddNodeModal(novelId),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required AppColors c,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? c.primary : c.textPrimary,
      ),
      backgroundColor: c.surfaceSecondary,
      selectedColor: c.primarySoft,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildSearchBar(AppColors c) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: c.surface,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: isIndo
              ? 'Cari ide cerita, bab, atau alur narasi...'
              : 'Search story ideas, chapters, or narrative arcs...',
          prefixIcon: const Icon(Symbols.search, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Symbols.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(mindMapSearchQueryProvider.notifier).state = '';
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
          ref.read(mindMapSearchQueryProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildEmptyCanvas(String novelId, AppColors c) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Symbols.hub, size: 48, color: c.primary),
            ),
            const SizedBox(height: 16),
            Text(
              isIndo ? 'Kanvas Masih Kosong' : 'Canvas is Empty',
              style: AppTypography.screenTitle
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isIndo
                    ? 'Mulai memetakan novel Anda: tambahkan konsep curah pendapat, urutan bab, titik plot, atau alur cerita.'
                    : 'Start mapping your novel: add brainstorming concepts, chapter sequences, plot points, or narrative arcs.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Symbols.add),
              label: Text(isIndo ? 'Tambah Ide / Ketukan Cerita Pertama' : 'Add First Idea / Story Beat'),
              onPressed: () => _showAddNodeModal(novelId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddNodeModal(String novelId) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final activeFilter = ref.read(mindMapTypeFilterProvider);
    final newNode = await AddNodeDialog.show(
      context,
      novelId: novelId,
      initialType: activeFilter ?? MindMapNodeType.brainstorm,
    );

    if (newNode != null && mounted) {
      final notifier = ref.read(mindMapGraphProvider(novelId).notifier);
      await notifier.addNode(newNode);
      ref.read(selectedMindMapNodeIdProvider.notifier).state = newNode.id;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIndo
                ? 'Menambahkan "${newNode.title}" ke peta pikiran'
                : 'Added "${newNode.title}" to mind map'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showNodeInspector(
    MindMapNode node,
    MindMapGraph graph,
    String novelId,
  ) {
    final notifier = ref.read(mindMapGraphProvider(novelId).notifier);
    final connectedEdges = graph.edges
        .where((e) => e.fromNodeId == node.id || e.toNodeId == node.id)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MindMapNodeInspector(
        node: node,
        allNodes: graph.nodes,
        connectedEdges: connectedEdges,
        onClose: () => Navigator.of(context).pop(),
        onAddConnection: () async {
          Navigator.of(context).pop();
          final newEdge = await showDialog<MindMapEdge>(
            context: context,
            builder: (_) => AddConnectionDialog(
              sourceNode: node,
              availableNodes: graph.nodes,
            ),
          );
          if (newEdge != null && mounted) {
            await notifier.addEdge(newEdge);
          }
        },
        onDeleteEdge: (edgeId) async {
          await notifier.removeEdge(edgeId);
        },
        onDeleteNode: () async {
          await notifier.removeNode(node.id);
          if (mounted) Navigator.of(context).pop();
        },
        onSaveNode: (updated) async {
          await notifier.updateNode(updated);
        },
      ),
    );
  }

  Future<void> _confirmClearCanvas(String novelId) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Bersihkan Kanvas?' : 'Clear Canvas?'),
        content: Text(
          isIndo
              ? 'Apakah Anda yakin ingin menghapus semua simpul dan hubungan dari peta pikiran ini?'
              : 'Are you sure you want to clear all nodes and connections from this mind map?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isIndo ? 'Bersihkan Semua' : 'Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(mindMapGraphProvider(novelId).notifier).clearGraph();
    }
  }
}
