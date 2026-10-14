import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../domain/models/writer_note_model.dart';

class WriterNotesRepository {
  final AppDatabase? _db;

  WriterNotesRepository([this._db]);

  static const String _storageKey = 'writer_notes_collection';

  Future<List<WriterNote>> loadNotes() async {
    final db = _db;
    if (db == null) return [];

    try {
      final row = await (db.select(db.appSettings)
            ..where((tbl) => tbl.key.equals(_storageKey)))
          .getSingleOrNull();

      if (row != null && row.value.isNotEmpty) {
        final decoded = jsonDecode(row.value) as List<dynamic>;
        return decoded
            .map((e) => WriterNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Future<void> saveNotes(List<WriterNote> notes) async {
    final db = _db;
    if (db == null) return;

    final jsonStr = jsonEncode(notes.map((n) => n.toJson()).toList());
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _storageKey,
            value: jsonStr,
            updatedAt: now,
          ),
        );
  }

  Future<void> addNote(WriterNote note) async {
    final existing = await loadNotes();
    final updated = [note, ...existing];
    await saveNotes(updated);
  }

  Future<void> updateNote(WriterNote note) async {
    final existing = await loadNotes();
    final index = existing.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      final updatedList = List<WriterNote>.from(existing);
      updatedList[index] = note.copyWith(updatedAt: DateTime.now());
      await saveNotes(updatedList);
    } else {
      await saveNotes([note, ...existing]);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final existing = await loadNotes();
    final updated = existing.where((n) => n.id != noteId).toList();
    await saveNotes(updated);
  }

  Future<void> togglePin(String noteId) async {
    final existing = await loadNotes();
    final index = existing.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final updatedList = List<WriterNote>.from(existing);
      final current = updatedList[index];
      updatedList[index] = current.copyWith(
        isPinned: !current.isPinned,
        updatedAt: DateTime.now(),
      );
      await saveNotes(updatedList);
    }
  }

  Future<void> toggleArchive(String noteId) async {
    final existing = await loadNotes();
    final index = existing.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final updatedList = List<WriterNote>.from(existing);
      final current = updatedList[index];
      updatedList[index] = current.copyWith(
        isArchived: !current.isArchived,
        isPinned: current.isArchived ? current.isPinned : false, // Unpin if archiving
        updatedAt: DateTime.now(),
      );
      await saveNotes(updatedList);
    }
  }
}
