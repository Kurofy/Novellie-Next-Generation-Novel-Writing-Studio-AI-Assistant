import 'package:flutter_quill/flutter_quill.dart';

/// Converts markdown text from AI responses into a formatted flutter_quill [Document]
/// to render in true WYSIWYG fashion.
class AiMarkdownToQuill {
  static Document parse(String markdownText) {
    final clean = markdownText.trim();
    if (clean.isEmpty) {
      return Document()..insert(0, '\n');
    }

    final ops = <Map<String, dynamic>>[];
    final lines = markdownText.split('\n');
    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Handle Code Block fence ```
      if (line.trim().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        ops.add({'insert': line});
        ops.add({
          'insert': '\n',
          'attributes': {'code-block': true},
        });
        continue;
      }

      Map<String, dynamic>? blockAttr;
      String lineContent = line;

      // Detect block headers and prefixes
      if (line.startsWith('### ')) {
        blockAttr = {'header': 3};
        lineContent = line.substring(4);
      } else if (line.startsWith('## ')) {
        blockAttr = {'header': 2};
        lineContent = line.substring(3);
      } else if (line.startsWith('# ')) {
        blockAttr = {'header': 1};
        lineContent = line.substring(2);
      } else if (line.startsWith('> ')) {
        blockAttr = {'blockquote': true};
        lineContent = line.substring(2);
      } else if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        blockAttr = {'list': 'bullet'};
        lineContent = line.replaceFirst(RegExp(r'^\s*[-*]\s+'), '');
      } else if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        blockAttr = {'list': 'ordered'};
        lineContent = line.replaceFirst(RegExp(r'^\s*\d+\.\s+'), '');
      }

      // Parse inline tokens for lineContent
      _parseInlineAndCollect(ops, lineContent);

      // Apply newline with block attribute if any
      if (blockAttr != null) {
        ops.add({
          'insert': '\n',
          'attributes': blockAttr,
        });
      } else {
        ops.add({'insert': '\n'});
      }
    }

    if (ops.isEmpty) {
      return Document()..insert(0, '\n');
    }

    try {
      return Document.fromJson(ops);
    } catch (_) {
      final fallbackDoc = Document();
      fallbackDoc.insert(0, '$markdownText\n');
      return fallbackDoc;
    }
  }

  static void _parseInlineAndCollect(
    List<Map<String, dynamic>> ops,
    String text,
  ) {
    if (text.isEmpty) return;

    final tokenRegex = RegExp(
      r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)|(_(.+?)_)|(`(.+?)`)|(~~(.+?)~~)',
    );

    int currentIndex = 0;
    for (final match in tokenRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        final plain = text.substring(currentIndex, match.start);
        ops.add({'insert': plain});
      }

      if (match.group(1) != null) {
        final content = match.group(2)!;
        ops.add({
          'insert': content,
          'attributes': {'bold': true, 'italic': true},
        });
      } else if (match.group(3) != null) {
        final content = match.group(4)!;
        ops.add({
          'insert': content,
          'attributes': {'bold': true},
        });
      } else if (match.group(5) != null) {
        final content = match.group(6)!;
        ops.add({
          'insert': content,
          'attributes': {'italic': true},
        });
      } else if (match.group(7) != null) {
        final content = match.group(8)!;
        ops.add({
          'insert': content,
          'attributes': {'italic': true},
        });
      } else if (match.group(9) != null) {
        final content = match.group(10)!;
        ops.add({
          'insert': content,
          'attributes': {'code': true},
        });
      } else if (match.group(11) != null) {
        final content = match.group(12)!;
        ops.add({
          'insert': content,
          'attributes': {'strike': true},
        });
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      final remaining = text.substring(currentIndex);
      ops.add({'insert': remaining});
    }
  }
}
