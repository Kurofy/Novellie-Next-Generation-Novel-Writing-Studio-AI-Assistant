import 'dart:io';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';
import '../../../manuscript/domain/models/manuscript_models.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../domain/models/export_format.dart';

class NovelExportService {
  String generateExport({
    required NovelModel novel,
    required List<ChapterModel> chapters,
    required Map<String, ChapterContentModel> chapterContents,
    required ExportFormat format,
  }) {
    switch (format) {
      case ExportFormat.markdown:
        return _generateMarkdown(novel, chapters, chapterContents);
      case ExportFormat.txt:
        return _generatePlainText(novel, chapters, chapterContents);
      case ExportFormat.html:
        return _generateHtml(novel, chapters, chapterContents);
    }
  }

  Future<File> saveExportFile({
    required NovelModel novel,
    required String content,
    required ExportFormat format,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = novel.title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final fileName = '$sanitizedTitle.${format.extension}';
    final filePath = path_util.join(docsDir.path, fileName);

    final file = File(filePath);
    return file.writeAsString(content);
  }

  String _generateMarkdown(
    NovelModel novel,
    List<ChapterModel> chapters,
    Map<String, ChapterContentModel> contents,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('# ${novel.title}');
    if (novel.subtitle != null && novel.subtitle!.isNotEmpty) {
      buffer.writeln('### ${novel.subtitle}');
    }
    buffer.writeln();

    if (novel.description != null && novel.description!.isNotEmpty) {
      buffer.writeln('> ${novel.description}');
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    for (final chapter in chapters) {
      buffer.writeln('## ${chapter.displayTitle}');
      buffer.writeln();
      final body = contents[chapter.id]?.plainText ?? '';
      buffer.writeln(body.trim());
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generatePlainText(
    NovelModel novel,
    List<ChapterModel> chapters,
    Map<String, ChapterContentModel> contents,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(novel.title.toUpperCase());
    if (novel.subtitle != null && novel.subtitle!.isNotEmpty) {
      buffer.writeln(novel.subtitle);
    }
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (final chapter in chapters) {
      buffer.writeln(chapter.displayTitle);
      buffer.writeln('-' * chapter.displayTitle.length);
      buffer.writeln();
      final body = contents[chapter.id]?.plainText ?? '';
      buffer.writeln(body.trim());
      buffer.writeln();
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateHtml(
    NovelModel novel,
    List<ChapterModel> chapters,
    Map<String, ChapterContentModel> contents,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="utf-8">');
    buffer.writeln('  <title>${novel.title}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(
      '    body { font-family: Georgia, serif; max-width: 680px; margin: 40px auto; padding: 0 24px; line-height: 1.8; color: #1a1a1a; }',
    );
    buffer.writeln(
      '    h1 { text-align: center; margin-bottom: 8px; font-size: 2.2rem; }',
    );
    buffer.writeln(
      '    .subtitle { text-align: center; color: #555; font-style: italic; margin-bottom: 32px; }',
    );
    buffer.writeln(
      '    .chapter-title { margin-top: 48px; border-bottom: 1px solid #eee; padding-bottom: 8px; }',
    );
    buffer.writeln(
      '    p { text-indent: 1.5em; margin-top: 0; margin-bottom: 0.8em; }',
    );
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>${novel.title}</h1>');
    if (novel.subtitle != null && novel.subtitle!.isNotEmpty) {
      buffer.writeln('  <div class="subtitle">${novel.subtitle}</div>');
    }

    for (final chapter in chapters) {
      buffer.writeln('  <div class="chapter">');
      buffer.writeln(
        '    <h2 class="chapter-title">${chapter.displayTitle}</h2>',
      );
      final body = contents[chapter.id]?.plainText ?? '';
      final paragraphs =
          body.split('\n').where((para) => para.trim().isNotEmpty);
      for (final para in paragraphs) {
        buffer.writeln('    <p>$para</p>');
      }
      buffer.writeln('  </div>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
