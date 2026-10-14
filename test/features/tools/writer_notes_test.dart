import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/app_theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/tools/application/writer_notes_providers.dart';
import 'package:novellie/features/tools/data/repositories/writer_notes_repository.dart';
import 'package:novellie/features/tools/domain/models/writer_note_model.dart';
import 'package:novellie/features/tools/presentation/screens/writer_notes_screen.dart';
import 'package:novellie/features/tools/presentation/widgets/note_card_widget.dart';

class FakeWriterNotesRepository implements WriterNotesRepository {
  List<WriterNote> storage = [];

  @override
  Future<List<WriterNote>> loadNotes() async {
    return List.from(storage);
  }

  @override
  Future<void> saveNotes(List<WriterNote> notes) async {
    storage = List.from(notes);
  }

  @override
  Future<void> addNote(WriterNote note) async {
    storage.insert(0, note);
  }

  @override
  Future<void> updateNote(WriterNote note) async {
    final idx = storage.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      storage[idx] = note;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    storage.removeWhere((n) => n.id == noteId);
  }

  @override
  Future<void> togglePin(String noteId) async {
    final idx = storage.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      storage[idx] = storage[idx].copyWith(isPinned: !storage[idx].isPinned);
    }
  }

  @override
  Future<void> toggleArchive(String noteId) async {
    final idx = storage.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      storage[idx] = storage[idx].copyWith(isArchived: !storage[idx].isArchived);
    }
  }
}

void main() {
  group('WriterNote Domain Models', () {
    test('NoteChecklistItem serialization & toggle', () {
      const item = NoteChecklistItem(
        id: 'c1',
        text: 'Outline Chapter 4 climax',
        isDone: false,
      );

      final json = item.toJson();
      final restored = NoteChecklistItem.fromJson(json);

      expect(restored.id, equals('c1'));
      expect(restored.text, equals('Outline Chapter 4 climax'));
      expect(restored.isDone, isFalse);

      final completed = item.copyWith(isDone: true);
      expect(completed.isDone, isTrue);
    });

    test('WriterNote serialization, checklist helpers, and color resolution', () {
      final now = DateTime(2026, 10, 10, 15, 30);
      final note = WriterNote(
        id: 'note-1',
        title: 'Worldbuilding Rules',
        content: 'Rule 1: Magic requires silver catalyst.',
        colorId: NoteColorPreset.mint.id,
        labels: ['magic', 'world'],
        novelId: 'novel-1',
        novelTitle: 'Chronicles of Sol',
        isPinned: true,
        isChecklist: true,
        checklist: const [
          NoteChecklistItem(id: 'chk-1', text: 'Define mana types', isDone: true),
          NoteChecklistItem(id: 'chk-2', text: 'Draw map border', isDone: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final json = note.toJson();
      final restored = WriterNote.fromJson(json);

      expect(restored.id, equals('note-1'));
      expect(restored.title, equals('Worldbuilding Rules'));
      expect(restored.colorId, equals(NoteColorPreset.mint.id));
      expect(restored.isPinned, isTrue);
      expect(restored.labels, containsAll(['magic', 'world']));
      expect(restored.checklist.length, equals(2));
      expect(restored.checklist.first.isDone, isTrue);
      expect(restored.isChecklist, isTrue);

      // Color preset resolution
      final preset = restored.colorPreset;
      expect(preset, equals(NoteColorPreset.mint));
      expect(preset.resolveBackground(false), equals(preset.lightColor));
      expect(preset.resolveBackground(true), equals(preset.darkColor));
    });

    test('NoteColorPreset has 10 distinct presets', () {
      expect(NoteColorPreset.values.length, equals(10));
      final ids = NoteColorPreset.values.map((p) => p.id).toSet();
      expect(ids.length, equals(10));
    });
  });

  group('WriterNotesNotifier & Riverpod Application Layer', () {
    late FakeWriterNotesRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeWriterNotesRepository();
    });

    test('createNote, updateNote, togglePin, toggleArchive, deleteNote', () async {
      final container = ProviderContainer(
        overrides: [
          writerNotesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Let initial load complete
      await container.read(writerNotesProvider.notifier).loadNotes();
      expect(container.read(writerNotesProvider).value, isEmpty);

      // Create Note
      final created = await container.read(writerNotesProvider.notifier).createNote(
            title: 'Character Backstory',
            content: 'Aria lost her talisman in the sunken ruins.',
            colorId: NoteColorPreset.lavender.id,
            labels: ['aria', 'lore'],
          );

      var current = container.read(writerNotesProvider).value!;
      expect(current.length, equals(1));
      expect(current.first.title, equals('Character Backstory'));

      // Toggle Pin
      await container.read(writerNotesProvider.notifier).togglePin(created.id);
      current = container.read(writerNotesProvider).value!;
      expect(current.first.isPinned, isTrue);

      // Update Color
      await container
          .read(writerNotesProvider.notifier)
          .updateNoteColor(created.id, NoteColorPreset.amber.id);
      current = container.read(writerNotesProvider).value!;
      expect(current.first.colorId, equals(NoteColorPreset.amber.id));

      // Toggle Archive
      await container
          .read(writerNotesProvider.notifier)
          .toggleArchive(created.id);
      current = container.read(writerNotesProvider).value!;
      expect(current.first.isArchived, isTrue);

      // Delete
      await container.read(writerNotesProvider.notifier).deleteNote(created.id);
      current = container.read(writerNotesProvider).value!;
      expect(current, isEmpty);
    });

    test('Toggle checklist item updates status', () async {
      final container = ProviderContainer(
        overrides: [
          writerNotesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(writerNotesProvider.notifier).loadNotes();

      final note = await container.read(writerNotesProvider.notifier).createNote(
            title: 'Drafting tasks',
            isChecklist: true,
            checklist: const [
              NoteChecklistItem(id: 'step-1', text: 'Write scene 1', isDone: false),
            ],
          );

      // Toggle checklist item
      await container
          .read(writerNotesProvider.notifier)
          .toggleChecklistItem(note.id, 'step-1');

      final updated = container.read(writerNotesProvider).value!.first;
      expect(updated.checklist.first.isDone, isTrue);
    });

    test('Filtered notes provider responds to search, labels, and tabs', () async {
      final container = ProviderContainer(
        overrides: [
          writerNotesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(writerNotesProvider.notifier).loadNotes();

      final n1 = await container.read(writerNotesProvider.notifier).createNote(
            title: 'Potion Recipes',
            content: 'Elixir of Clarity',
            labels: ['alchemy'],
          );

      final n2 = await container.read(writerNotesProvider.notifier).createNote(
            title: 'Editing To-Do',
            isChecklist: true,
            checklist: const [
              NoteChecklistItem(id: 'i1', text: 'Check grammar', isDone: false),
            ],
            labels: ['editing'],
          );

      final n3 = await container.read(writerNotesProvider.notifier).createNote(
            title: 'Old Abandoned Arc',
            content: 'Archived draft',
          );
      await container.read(writerNotesProvider.notifier).toggleArchive(n3.id);

      // Tab 0: All active notes (n1, n2)
      container.read(notesActiveTabProvider.notifier).state = 0;
      expect(container.read(filteredWriterNotesProvider).length, equals(2));

      // Tab 1: Checklists only (n2)
      container.read(notesActiveTabProvider.notifier).state = 1;
      expect(container.read(filteredWriterNotesProvider).length, equals(1));
      expect(container.read(filteredWriterNotesProvider).first.id, equals(n2.id));

      // Tab 2: Archived only (n3)
      container.read(notesActiveTabProvider.notifier).state = 2;
      expect(container.read(filteredWriterNotesProvider).length, equals(1));
      expect(container.read(filteredWriterNotesProvider).first.id, equals(n3.id));

      // Back to Tab 0 with search filter
      container.read(notesActiveTabProvider.notifier).state = 0;
      container.read(notesSearchQueryProvider.notifier).state = 'clarity';
      expect(container.read(filteredWriterNotesProvider).length, equals(1));
      expect(container.read(filteredWriterNotesProvider).first.id, equals(n1.id));

      // Filter by label
      container.read(notesSearchQueryProvider.notifier).state = '';
      container.read(selectedNoteLabelFilterProvider.notifier).state = 'editing';
      expect(container.read(filteredWriterNotesProvider).length, equals(1));
      expect(container.read(filteredWriterNotesProvider).first.id, equals(n2.id));
    });
  });

  group('WriterNotesScreen Widget Tests', () {
    late FakeWriterNotesRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeWriterNotesRepository();
    });

    testWidgets('Renders Google Keep quick bar and notes list correctly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final pinned = WriterNote(
        id: 'p1',
        title: 'Pinned Keep Note',
        content: 'Always at the top',
        isPinned: true,
        colorId: NoteColorPreset.amber.id,
        createdAt: now,
        updatedAt: now,
      );
      final regular = WriterNote(
        id: 'r1',
        title: 'Regular Keep Note',
        content: 'Under other notes',
        colorId: NoteColorPreset.sky.id,
        createdAt: now,
        updatedAt: now,
      );

      fakeRepo.storage = [pinned, regular];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            writerNotesRepositoryProvider.overrideWithValue(fakeRepo),
            novelListStreamProvider.overrideWith((ref) => Stream.value(<NovelModel>[])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const WriterNotesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check app bar title
      expect(find.text('Writer Notes'), findsOneWidget);

      // Check "Take a note..." Google Keep quick bar
      expect(find.text('Take a note...'), findsOneWidget);

      // Check PINNED header and OTHERS header
      expect(find.text('PINNED'), findsOneWidget);
      expect(find.text('OTHERS'), findsOneWidget);

      // Check card titles
      expect(find.text('Pinned Keep Note'), findsOneWidget);
      expect(find.text('Regular Keep Note'), findsOneWidget);

      // Check NoteCardWidgets are rendered
      expect(find.byType(NoteCardWidget), findsNWidgets(2));
    });

    testWidgets('Tapping search toggle opens search input bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            writerNotesRepositoryProvider.overrideWithValue(fakeRepo),
            novelListStreamProvider.overrideWith((ref) => Stream.value(<NovelModel>[])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const WriterNotesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search field is initially not rendered
      expect(find.byType(TextField), findsNothing);

      // Tap search icon in AppBar
      final searchButton = find.byTooltip('Search Notes');
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Now search TextField appears
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
