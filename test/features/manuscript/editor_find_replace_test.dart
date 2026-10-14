import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/app_theme.dart';
import 'package:novellie/features/manuscript/presentation/widgets/editor_find_replace_bar.dart';

void main() {
  group('EditorFindReplaceBar Widget Tests', () {
    testWidgets('Renders on narrow mobile screen (360px) without overflow',
        (tester) async {
      final doc = Document()..insert(0, 'The quick brown fox jumps over the lazy dog.');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Column(
              children: [
                EditorFindReplaceBar(
                  controller: controller,
                  initialShowReplace: true,
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(EditorFindReplaceBar), findsOneWidget);
      expect(find.text('Find in chapter…'), findsOneWidget);
      expect(find.text('Replace with…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Finds matching terms and navigates next / previous',
        (tester) async {
      final doc = Document()..insert(0, 'apple banana apple cherry apple');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorFindReplaceBar(
              controller: controller,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search term 'apple'
      final findInput = find.widgetWithText(TextField, 'Find in chapter…');
      await tester.enterText(findInput, 'apple');
      await tester.pumpAndSettle();

      // Check match pill
      expect(find.text('1/3'), findsOneWidget);
      expect(controller.selection.baseOffset, equals(0));
      expect(controller.selection.extentOffset, equals(5));

      // Tap Next match button
      final nextButton = find.byTooltip('Next match (Enter)');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      expect(controller.selection.baseOffset, equals(13));
      expect(controller.selection.extentOffset, equals(18));

      // Tap Next match again
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('3/3'), findsOneWidget);
      expect(controller.selection.baseOffset, equals(26));
      expect(controller.selection.extentOffset, equals(31));

      // Tap Prev match button
      final prevButton = find.byTooltip('Previous match (Shift+Enter)');
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      expect(controller.selection.baseOffset, equals(13));
    });

    testWidgets('Match Case filtering works as expected', (tester) async {
      final doc = Document()..insert(0, 'Apple apple APPLE');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorFindReplaceBar(
              controller: controller,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final findInput = find.widgetWithText(TextField, 'Find in chapter…');
      await tester.enterText(findInput, 'Apple');
      await tester.pumpAndSettle();

      // Case-insensitive by default: 3 matches
      expect(find.text('1/3'), findsOneWidget);

      // Toggle Match Case
      final matchCaseChip = find.text('Match Case');
      await tester.tap(matchCaseChip);
      await tester.pumpAndSettle();

      // Exactly 1 match ('Apple')
      expect(find.text('1/1'), findsOneWidget);
      expect(controller.selection.baseOffset, equals(0));
    });

    testWidgets('Whole Word filtering works as expected', (tester) async {
      final doc = Document()..insert(0, 'cat catalog scatter cat');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorFindReplaceBar(
              controller: controller,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final findInput = find.widgetWithText(TextField, 'Find in chapter…');
      await tester.enterText(findInput, 'cat');
      await tester.pumpAndSettle();

      // Partial matches included: cat, catalog, scatter, cat = 4 matches
      expect(find.text('1/4'), findsOneWidget);

      // Toggle Whole Word
      final wholeWordChip = find.text('Whole Word');
      await tester.tap(wholeWordChip);
      await tester.pumpAndSettle();

      // Only standalone 'cat': 2 matches
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('Replaces single match and advances correctly', (tester) async {
      final doc = Document()..insert(0, 'hello world hello again');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorFindReplaceBar(
              controller: controller,
              initialShowReplace: true,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final findInput = find.widgetWithText(TextField, 'Find in chapter…');
      await tester.enterText(findInput, 'hello');
      await tester.pumpAndSettle();

      final replaceInput = find.widgetWithText(TextField, 'Replace with…');
      await tester.enterText(replaceInput, 'greetings');
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);

      // Tap Replace button
      final replaceButton = find.widgetWithText(FilledButton, 'Replace');
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      // Document plain text should now have 'greetings' at start
      expect(
        controller.document.toPlainText(),
        contains('greetings world hello again'),
      );
      // Now 1 remaining match ('hello') selected
      expect(find.text('1/1'), findsOneWidget);
    });

    testWidgets('Replace All replaces all occurrences cleanly', (tester) async {
      final doc = Document()..insert(0, 'foo bar foo baz foo');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorFindReplaceBar(
              controller: controller,
              initialShowReplace: true,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final findInput = find.widgetWithText(TextField, 'Find in chapter…');
      await tester.enterText(findInput, 'foo');
      await tester.pumpAndSettle();

      final replaceInput = find.widgetWithText(TextField, 'Replace with…');
      await tester.enterText(replaceInput, 'qux');
      await tester.pumpAndSettle();

      expect(find.text('1/3'), findsOneWidget);

      // Tap All button
      final replaceAllButton = find.widgetWithText(FilledButton, 'All');
      await tester.tap(replaceAllButton);
      await tester.pumpAndSettle();

      expect(
        controller.document.toPlainText(),
        equals('qux bar qux baz qux\n'),
      );
      expect(find.text('0'), findsOneWidget);
    });
  });
}
