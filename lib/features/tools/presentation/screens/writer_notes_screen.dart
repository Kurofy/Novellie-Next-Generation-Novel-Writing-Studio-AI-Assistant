import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../application/writer_notes_providers.dart';
import '../../domain/models/writer_note_model.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/note_editor_dialog.dart';

class WriterNotesScreen extends ConsumerStatefulWidget {
  final String? initialNovelId;

  const WriterNotesScreen({
    super.key,
    this.initialNovelId,
  });

  @override
  ConsumerState<WriterNotesScreen> createState() => _WriterNotesScreenState();
}

class _WriterNotesScreenState extends ConsumerState<WriterNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != ref.read(notesActiveTabProvider)) {
        ref.read(notesActiveTabProvider.notifier).state = _tabController.index;
      }
    });
    if (widget.initialNovelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedNoteNovelFilterProvider.notifier).state =
            widget.initialNovelId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final viewMode = ref.watch(notesViewModeProvider);
    final novelListAsync = ref.watch(novelListStreamProvider);
    final selectedNovelId = ref.watch(selectedNoteNovelFilterProvider);
    final selectedLabel = ref.watch(selectedNoteLabelFilterProvider);
    final allLabels = ref.watch(allNoteLabelsProvider);
    final activeNotes = ref.watch(activeWriterNotesProvider);
    final checklistNotes = ref.watch(checklistWriterNotesProvider);
    final archivedNotes = ref.watch(archivedWriterNotesProvider);
    final activeTab = ref.watch(notesActiveTabProvider);

    final novels = novelListAsync.valueOrNull ?? [];
    final selectedNovel =
        novels.where((n) => n.id == selectedNovelId).firstOrNull;

    return Scaffold(
      appBar: NvAppBar(
        title: isIndo ? 'Catatan Penulis' : 'Writer Notes',
        subtitle: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedNovelId,
            isDense: true,
            dropdownColor: c.surface,
            icon: const Icon(
              Symbols.arrow_drop_down,
              color: Color(0xFFD97706),
              size: 18,
            ),
            style: AppTypography.bodySm.copyWith(
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w600,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(isIndo ? 'Semua Novel & Global' : 'All Novels & Global'),
              ),
              ...novels.map(
                (n) => DropdownMenuItem<String?>(
                  value: n.id,
                  child: Text(n.title),
                ),
              ),
            ],
            onChanged: (val) {
              ref.read(selectedNoteNovelFilterProvider.notifier).state = val;
            },
          ),
        ),
        actions: [
          // Search Toggle
          IconButton(
            icon: Icon(
              _isSearching ? Symbols.close : Symbols.search,
              color: _isSearching ? const Color(0xFFD97706) : null,
            ),
            tooltip: _isSearching
                ? (isIndo ? 'Tutup Pencarian' : 'Close Search')
                : (isIndo ? 'Cari Catatan' : 'Search Notes'),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(notesSearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),

          // Grid vs List Toggle
          IconButton(
            icon: Icon(
              viewMode == NotesViewMode.grid
                  ? Symbols.view_agenda
                  : Symbols.grid_view,
            ),
            tooltip: viewMode == NotesViewMode.grid
                ? (isIndo ? 'Beralih ke Tampilan Daftar' : 'Switch to List View')
                : (isIndo ? 'Beralih ke Tampilan Kisi' : 'Switch to Grid View'),
            onPressed: () {
              ref.read(notesViewModeProvider.notifier).state =
                  viewMode == NotesViewMode.grid
                      ? NotesViewMode.list
                      : NotesViewMode.grid;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Google Keep Style Tabs: All Notes, Checklists, Archived
          Container(
            color: c.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFD97706),
              unselectedLabelColor: c.textSecondary,
              indicatorColor: const Color(0xFFD97706),
              onTap: (index) {
                ref.read(notesActiveTabProvider.notifier).state = index;
              },
              tabs: [
                Tab(
                  icon: const Icon(Symbols.description, size: 18),
                  text: isIndo ? 'Semua Catatan' : 'All Notes',
                ),
                Tab(
                  icon: const Icon(Symbols.checklist, size: 18),
                  text: isIndo ? 'Daftar Tugas' : 'Checklists',
                ),
                Tab(
                  icon: const Icon(Symbols.archive, size: 18),
                  text: isIndo ? 'Diarsipkan' : 'Archived',
                ),
              ],
            ),
          ),

          // Optional Search Input Bar
          if (_isSearching) _buildSearchBar(c, isIndo),

          // Label Filter Chips Row (Always full horizontal width, never cropped)
          if (allLabels.isNotEmpty)
            _buildLabelChipsRow(allLabels, selectedLabel, c, isIndo),

          // Main Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTabContent(
                  activeNotes,
                  viewMode,
                  selectedNovel,
                  c,
                  isIndo: isIndo,
                  isChecklistOnly: false,
                  isArchive: false,
                ),
                _buildNotesTabContent(
                  checklistNotes,
                  viewMode,
                  selectedNovel,
                  c,
                  isIndo: isIndo,
                  isChecklistOnly: true,
                  isArchive: false,
                ),
                _buildNotesTabContent(
                  archivedNotes,
                  viewMode,
                  selectedNovel,
                  c,
                  isIndo: isIndo,
                  isChecklistOnly: false,
                  isArchive: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: activeTab == 2
          ? null
          : FloatingActionButton(
              heroTag: 'writer_notes_add_fab',
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              tooltip: isIndo ? 'Catatan Baru' : 'New Note',
              onPressed: () {
                NoteEditorDialog.show(
                  context,
                  initialNovelId: selectedNovel?.id,
                  initialNovelTitle: selectedNovel?.title,
                );
              },
              child: const Icon(Symbols.add),
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
              ? 'Cari catatan, daftar tugas, dan label...'
              : 'Search notes, checklists, and labels...',
          prefixIcon: const Icon(Symbols.search, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Symbols.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(notesSearchQueryProvider.notifier).state = '';
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
          ref.read(notesSearchQueryProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildLabelChipsRow(
    List<String> allLabels,
    String? selectedLabel,
    AppColors c,
    bool isIndo,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterChip(
              selected: selectedLabel == null,
              label: Text(isIndo ? 'Semua Label' : 'All Labels'),
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                ref.read(selectedNoteLabelFilterProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),
            ...allLabels.map((label) {
              final isSelected = selectedLabel == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    ref.read(selectedNoteLabelFilterProvider.notifier).state =
                        val ? label : null;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTabContent(
    List<WriterNote> notes,
    NotesViewMode viewMode,
    NovelModel? selectedNovel,
    AppColors c, {
    required bool isIndo,
    required bool isChecklistOnly,
    required bool isArchive,
  }) {
    if (notes.isEmpty) {
      return _buildEmptyState(c, isChecklistOnly, isArchive, isIndo);
    }

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return CustomScrollView(
      slivers: [
        // Quick "Take a note..." Bar (Google Keep style) on active tabs
        if (!isArchive)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildGoogleKeepQuickBar(selectedNovel, c, isIndo),
            ),
          ),

        // Pinned Notes Section
        if (pinnedNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                children: [
                  const Icon(
                    Symbols.push_pin,
                    size: 15,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isIndo ? 'DISEMATKAN' : 'PINNED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNotesSliver(pinnedNotes, viewMode),
        ],

        // Other Notes Section
        if (otherNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Text(
                  isIndo ? 'LAINNYA' : 'OTHERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          _buildNotesSliver(otherNotes, viewMode),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildGoogleKeepQuickBar(
    NovelModel? selectedNovel,
    AppColors c,
    bool isIndo,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          NoteEditorDialog.show(
            context,
            initialNovelId: selectedNovel?.id,
            initialNovelTitle: selectedNovel?.title,
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.outlineVariant.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.edit_note,
                size: 20,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isIndo ? 'Tulis catatan...' : 'Take a note...',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textMuted,
                  ),
                ),
              ),
              // Checklist quick launcher
              IconButton(
                icon: const Icon(Symbols.check_box, size: 20),
                tooltip: isIndo ? 'Daftar Tugas Baru' : 'New Checklist',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  NoteEditorDialog.show(
                    context,
                    startAsChecklist: true,
                    initialNovelId: selectedNovel?.id,
                    initialNovelTitle: selectedNovel?.title,
                  );
                },
              ),
              // Color quick launcher
              IconButton(
                icon: const Icon(Symbols.palette, size: 20),
                tooltip: isIndo ? 'Catatan Berwarna Baru' : 'New Colored Note',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  NoteEditorDialog.show(
                    context,
                    initialNovelId: selectedNovel?.id,
                    initialNovelTitle: selectedNovel?.title,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSliver(List<WriterNote> notes, NotesViewMode viewMode) {
    if (viewMode == NotesViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, idx) {
              final note = notes[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NoteCardWidget(
                  note: note,
                  onTap: () => NoteEditorDialog.show(context, initialNote: note),
                ),
              );
            },
            childCount: notes.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final note = notes[idx];
            return NoteCardWidget(
              note: note,
              onTap: () => NoteEditorDialog.show(context, initialNote: note),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppColors c,
    bool isChecklistOnly,
    bool isArchive,
    bool isIndo,
  ) {
    final title = isArchive
        ? (isIndo ? 'Belum Ada Catatan Diarsipkan' : 'No Archived Notes')
        : (isChecklistOnly
            ? (isIndo ? 'Belum Ada Daftar Tugas' : 'No Checklists Yet')
            : (isIndo ? 'Belum Ada Catatan Penulis' : 'No Writer Notes Yet'));

    final subtitle = isArchive
        ? (isIndo
            ? 'Catatan yang Anda arsipkan akan tersimpan rapi di sini.'
            : 'Notes you archive will appear here safely stored away.')
        : (isChecklistOnly
            ? (isIndo
                ? 'Buat daftar tugas, pencapaian bab, dan pemeriksaan alur cerita.'
                : 'Create to-do lists, chapter milestone tasks, and plotting checks.')
            : (isIndo
                ? 'Catat dialog karakter tiba-tiba, ide plot, dan sketsa lore layaknya Google Keep.'
                : 'Capture sudden character dialogues, plot ideas, and lore sketches just like Google Keep.'));

    final icon = isArchive
        ? Symbols.archive
        : (isChecklistOnly ? Symbols.checklist : Symbols.lightbulb);

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
              child: Icon(icon, size: 44, color: const Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.screenTitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            if (!isArchive) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Symbols.add),
                label: Text(isChecklistOnly
                    ? (isIndo ? 'Buat Daftar Tugas' : 'Create Checklist')
                    : (isIndo ? 'Tulis Catatan' : 'Take a Note')),
                onPressed: () {
                  NoteEditorDialog.show(
                    context,
                    startAsChecklist: isChecklistOnly,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
