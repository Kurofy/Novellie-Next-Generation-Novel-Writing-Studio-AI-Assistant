import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/app_theme.dart';
import 'package:novellie/features/manuscript/presentation/widgets/editor_toolbar.dart';
import 'package:novellie/features/manuscript/presentation/widgets/import_index_entity_dialog.dart';
import 'package:novellie/shared/widgets/widgets.dart';

void main() {
  group('Workspace Imports & Variable Mapping', () {
    test('IndexEntityItem strips unwanted @ prefixes and supports clean identifiers', () {
      final item = IndexEntityItem(
        id: 'char-1',
        name: '@Alexander Pierce',
        nickname: '@The Wolf',
        type: NvEntityType.character,
      );

      // Verify unwanted @ prefixes are stripped
      expect(item.name, equals('Alexander Pierce'));
      expect(item.nickname, equals('The Wolf'));
      expect(item.boundIdentifier, equals('Alexander Pierce'));

      // Dual identifier binding via Nickname
      final boundByNickname = item.copyWithBinding(item.nickname!);
      expect(boundByNickname.boundIdentifier, equals('The Wolf'));

      // Dual identifier binding via Full Name
      final boundByName = item.copyWithBinding(item.name);
      expect(boundByName.boundIdentifier, equals('Alexander Pierce'));
    });

    test('IndexEntityItem entity link is formatted properly', () {
      final item = IndexEntityItem(
        id: 'loc-42',
        name: '@Valoria Citadel',
        type: NvEntityType.location,
      );

      expect(item.name, equals('Valoria Citadel'));
      expect(item.entityLink, equals('entity://location/loc-42'));
    });
  });

  group('Compact Toolbar Layout', () {
    testWidgets('EditorToolbar renders within compact slim height (h-12 / 48px)',
        (tester) async {
      final controller = QuillController.basic();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 48,
                child: EditorToolbar(
                  controller: controller,
                  novelId: 'novel-1',
                  onInsertImage: (_) {},
                  onInsertEntity: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final toolbarFinder = find.byType(EditorToolbar);
      expect(toolbarFinder, findsOneWidget);

      final renderBox = tester.renderObject(toolbarFinder) as RenderBox;
      expect(renderBox.size.height, lessThanOrEqualTo(52.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(40.0));
    });

    testWidgets('EditorToolbar is positioned at bottom of column below editor workspace',
        (tester) async {
      final controller = QuillController.basic();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const Expanded(
                    child: Placeholder(),
                  ),
                  EditorToolbar(
                    controller: controller,
                    novelId: 'novel-1',
                    onInsertImage: (_) {},
                    onInsertEntity: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final placeholderFinder = find.byType(Placeholder);
      final toolbarFinder = find.byType(EditorToolbar);

      final placeholderBottom = tester.getBottomLeft(placeholderFinder).dy;
      final toolbarTop = tester.getTopLeft(toolbarFinder).dy;

      // Toolbar must be docked directly below the expanded workspace
      expect(toolbarTop, equals(placeholderBottom));
    });

    test('Entity removal cleanses entity link operations from Quill document delta', () {
      final doc = Document();
      doc.insert(0, 'Hello ');
      doc.insert(6, 'Gojo Satoru');
      doc.format(6, 11, const LinkAttribute('entity://character/char-1'));
      doc.insert(17, ' in the room.');

      final entity = IndexEntityItem(
        id: 'char-1',
        name: 'Gojo Satoru',
        type: NvEntityType.character,
      );

      // Verify the link is currently present
      expect(
        doc.toDelta().operations.any(
              (op) =>
                  op.attributes != null &&
                  op.attributes![Attribute.link.key] == entity.entityLink,
            ),
        isTrue,
      );

      // Simulate the removal logic used in ChapterEditorScreen
      final docDelta = doc.toDelta();
      var currentOffset = 0;
      final rangesToRemove = <({int offset, int length, String text})>[];

      for (final op in docDelta.operations) {
        final len =
            op.length ?? (op.data is String ? (op.data as String).length : 1);
        if (op.attributes != null &&
            op.attributes![Attribute.link.key] == entity.entityLink) {
          final text = op.data is String ? op.data as String : '';
          rangesToRemove.add((offset: currentOffset, length: len, text: text));
        }
        currentOffset += len;
      }

      for (final r in rangesToRemove.reversed) {
        doc.replace(r.offset, r.length, '');
      }

      // Verify the link and text are now gone from document
      expect(
        doc.toDelta().operations.any(
              (op) =>
                  op.attributes != null &&
                  op.attributes![Attribute.link.key] == entity.entityLink,
            ),
        isFalse,
      );
      expect(doc.toPlainText(), equals('Hello  in the room.\n'));
    });
  });
}
