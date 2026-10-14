import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../data/repositories/writer_notes_repository.dart';
import '../domain/models/writer_note_model.dart';

enum NotesViewMode { grid, list }

final writerNotesRepositoryProvider = Provider<WriterNotesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WriterNotesRepository(db);
});

final notesViewModeProvider = StateProvider<NotesViewMode>((ref) => NotesViewMode.grid);
final notesSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedNoteLabelFilterProvider = StateProvider<String?>((ref) => null);
final selectedNoteNovelFilterProvider = StateProvider<String?>((ref) => null);
final notesActiveTabProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Checklists, 2: Archived

class WriterNotesNotifier extends StateNotifier<AsyncValue<List<WriterNote>>> {
  final WriterNotesRepository _repo;

  WriterNotesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repo.loadNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<WriterNote> createNote({
    String title = '',
    String content = '',
    bool isChecklist = false,
    String? novelId,
    String? novelTitle,
    String colorId = 'default',
    bool isPinned = false,
    List<String> labels = const [],
    List<NoteChecklistItem> checklist = const [],
  }) async {
    final now = DateTime.now();
    final newNote = WriterNote(
      id: generateUuid(),
      novelId: novelId,
      novelTitle: novelTitle,
      title: title,
      content: content,
      isChecklist: isChecklist,
      isPinned: isPinned,
      isArchived: false,
      colorId: colorId,
      labels: labels,
      checklist: checklist,
      createdAt: now,
      updatedAt: now,
    );

    final currentNotes = state.valueOrNull ?? [];
    final updated = [newNote, ...currentNotes];
    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
    return newNote;
  }

  Future<void> updateNote(WriterNote note) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.map((n) {
      if (n.id == note.id) {
        return note.copyWith(updatedAt: DateTime.now());
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }

  Future<void> deleteNote(String noteId) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.where((n) => n.id != noteId).toList();
    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }

  Future<void> togglePin(String noteId) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.map((n) {
      if (n.id == noteId) {
        return n.copyWith(
          isPinned: !n.isPinned,
          updatedAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }

  Future<void> toggleArchive(String noteId) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.map((n) {
      if (n.id == noteId) {
        final willArchive = !n.isArchived;
        return n.copyWith(
          isArchived: willArchive,
          isPinned: willArchive ? false : n.isPinned,
          updatedAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }

  Future<void> updateNoteColor(String noteId, String colorId) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.map((n) {
      if (n.id == noteId) {
        return n.copyWith(
          colorId: colorId,
          updatedAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final currentNotes = state.valueOrNull ?? [];
    final updated = currentNotes.map((n) {
      if (n.id == noteId) {
        final updatedChecklist = n.checklist.map((item) {
          if (item.id == itemId) {
            return item.copyWith(isDone: !item.isDone);
          }
          return item;
        }).toList();

        return n.copyWith(
          checklist: updatedChecklist,
          updatedAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    state = AsyncValue.data(updated);
    await _repo.saveNotes(updated);
  }
}

final writerNotesProvider =
    StateNotifierProvider<WriterNotesNotifier, AsyncValue<List<WriterNote>>>((ref) {
  final repo = ref.watch(writerNotesRepositoryProvider);
  return WriterNotesNotifier(repo);
});

List<WriterNote> _filterNotesList(
  List<WriterNote> notes, {
  required bool isArchive,
  required bool isChecklistOnly,
  String? novelFilter,
  String? labelFilter,
  String searchQuery = '',
}) {
  return notes.where((note) {
    if (isArchive) {
      if (!note.isArchived) return false;
    } else {
      if (note.isArchived) return false;
      if (isChecklistOnly && !note.isChecklist) return false;
    }

    if (novelFilter != null && novelFilter.isNotEmpty) {
      if (note.novelId != novelFilter) return false;
    }

    if (labelFilter != null && labelFilter.isNotEmpty) {
      if (!note.labels.contains(labelFilter)) return false;
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      final matchesTitle = note.title.toLowerCase().contains(q);
      final matchesContent = note.content.toLowerCase().contains(q);
      final matchesLabel =
          note.labels.any((l) => l.toLowerCase().contains(q));
      final matchesChecklist =
          note.checklist.any((item) => item.text.toLowerCase().contains(q));
      if (!matchesTitle &&
          !matchesContent &&
          !matchesLabel &&
          !matchesChecklist) {
        return false;
      }
    }

    return true;
  }).toList();
}

/// Computes active writer notes (not archived).
final activeWriterNotesProvider = Provider<List<WriterNote>>((ref) {
  final notes = ref.watch(writerNotesProvider).valueOrNull ?? [];
  final novelFilter = ref.watch(selectedNoteNovelFilterProvider);
  final labelFilter = ref.watch(selectedNoteLabelFilterProvider);
  final searchQuery = ref.watch(notesSearchQueryProvider).trim();
  return _filterNotesList(
    notes,
    isArchive: false,
    isChecklistOnly: false,
    novelFilter: novelFilter,
    labelFilter: labelFilter,
    searchQuery: searchQuery,
  );
});

/// Computes active checklist notes.
final checklistWriterNotesProvider = Provider<List<WriterNote>>((ref) {
  final notes = ref.watch(writerNotesProvider).valueOrNull ?? [];
  final novelFilter = ref.watch(selectedNoteNovelFilterProvider);
  final labelFilter = ref.watch(selectedNoteLabelFilterProvider);
  final searchQuery = ref.watch(notesSearchQueryProvider).trim();
  return _filterNotesList(
    notes,
    isArchive: false,
    isChecklistOnly: true,
    novelFilter: novelFilter,
    labelFilter: labelFilter,
    searchQuery: searchQuery,
  );
});

/// Computes archived writer notes.
final archivedWriterNotesProvider = Provider<List<WriterNote>>((ref) {
  final notes = ref.watch(writerNotesProvider).valueOrNull ?? [];
  final novelFilter = ref.watch(selectedNoteNovelFilterProvider);
  final labelFilter = ref.watch(selectedNoteLabelFilterProvider);
  final searchQuery = ref.watch(notesSearchQueryProvider).trim();
  return _filterNotesList(
    notes,
    isArchive: true,
    isChecklistOnly: false,
    novelFilter: novelFilter,
    labelFilter: labelFilter,
    searchQuery: searchQuery,
  );
});

/// Computes filtered writer notes according to the currently active tab.
final filteredWriterNotesProvider = Provider<List<WriterNote>>((ref) {
  final tab = ref.watch(notesActiveTabProvider);
  if (tab == 1) return ref.watch(checklistWriterNotesProvider);
  if (tab == 2) return ref.watch(archivedWriterNotesProvider);
  return ref.watch(activeWriterNotesProvider);
});

/// Collects all unique labels used across all active notes.
final allNoteLabelsProvider = Provider<List<String>>((ref) {
  final notesAsync = ref.watch(writerNotesProvider);
  final notes = notesAsync.valueOrNull ?? [];
  final labelsSet = <String>{};
  for (final note in notes) {
    labelsSet.addAll(note.labels);
  }
  return labelsSet.toList()..sort();
});
