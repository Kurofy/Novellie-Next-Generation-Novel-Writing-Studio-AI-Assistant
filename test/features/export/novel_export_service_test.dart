import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/export/data/services/novel_export_service.dart';
import 'package:novellie/features/export/domain/models/export_format.dart';
import 'package:novellie/features/manuscript/domain/models/manuscript_models.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';

void main() {
  group('NovelExportService', () {
    late NovelExportService exporter;

    setUp(() {
      exporter = NovelExportService();
    });

    final testNovel = NovelModel(
      id: 'test-novel-1',
      title: 'The Starlight Chronicle',
      subtitle: 'Book One',
      description: 'An epic tale of galactic rediscovery.',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final testChapters = [
      ChapterModel(
        id: 'ch-1',
        novelId: 'test-novel-1',
        arcId: 'arc-1',
        title: 'Awakening',
        sequenceNumber: 1,
        position: 0,
        wordCount: 120,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
      ChapterModel(
        id: 'ch-2',
        novelId: 'test-novel-1',
        arcId: 'arc-1',
        title: 'The Silent Signal',
        sequenceNumber: 2,
        position: 1,
        wordCount: 150,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    ];

    final testContents = {
      'ch-1': ChapterContentModel(
        chapterId: 'ch-1',
        deltaJson: '{}',
        plainText: 'Cold light spilled across the cryo chamber.',
        wordCount: 7,
        charCount: 44,
        updatedAt: DateTime.now().toUtc(),
      ),
      'ch-2': ChapterContentModel(
        chapterId: 'ch-2',
        deltaJson: '{}',
        plainText: 'A pulse echoed through the communication array.',
        wordCount: 7,
        charCount: 47,
        updatedAt: DateTime.now().toUtc(),
      ),
    };

    test('generates valid Markdown export', () {
      final md = exporter.generateExport(
        novel: testNovel,
        chapters: testChapters,
        chapterContents: testContents,
        format: ExportFormat.markdown,
      );

      expect(md, contains('# The Starlight Chronicle'));
      expect(md, contains('### Book One'));
      expect(md, contains('> An epic tale of galactic rediscovery.'));
      expect(md, contains('## Awakening'));
      expect(md, contains('Cold light spilled across the cryo chamber.'));
      expect(md, contains('## The Silent Signal'));
      expect(md, contains('A pulse echoed through the communication array.'));
    });

    test('generates clean Plain Text export', () {
      final txt = exporter.generateExport(
        novel: testNovel,
        chapters: testChapters,
        chapterContents: testContents,
        format: ExportFormat.txt,
      );

      expect(txt, contains('THE STARLIGHT CHRONICLE'));
      expect(txt, contains('Book One'));
      expect(txt, contains('Awakening'));
      expect(txt, contains('Cold light spilled across the cryo chamber.'));
      expect(txt, contains('The Silent Signal'));
    });

    test('generates structured HTML export with styles and paragraphs', () {
      final html = exporter.generateExport(
        novel: testNovel,
        chapters: testChapters,
        chapterContents: testContents,
        format: ExportFormat.html,
      );

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<title>The Starlight Chronicle</title>'));
      expect(html, contains('<h1>The Starlight Chronicle</h1>'));
      expect(html, contains('<div class="subtitle">Book One</div>'));
      expect(html, contains('<h2 class="chapter-title">Awakening</h2>'));
      expect(html, contains('<p>Cold light spilled across the cryo chamber.</p>'));
      expect(html, contains('</html>'));
    });
  });
}
