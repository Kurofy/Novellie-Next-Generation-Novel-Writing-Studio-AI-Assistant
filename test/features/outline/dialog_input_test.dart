import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/outline/presentation/screens/create_event_dialog.dart';
import 'package:novellie/shared/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NvTextField defaults to TextInputAction.next for single line and moves focus', (tester) async {
    final focus1 = FocusNode();
    final focus2 = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              NvTextField(
                focusNode: focus1,
                hintText: 'Field 1',
              ),
              NvTextField(
                focusNode: focus2,
                hintText: 'Field 2',
              ),
            ],
          ),
        ),
      ),
    );

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    final textField1 = tester.widget<TextField>(textFields.first);
    expect(textField1.textInputAction, TextInputAction.next);

    // Focus field 1
    focus1.requestFocus();
    await tester.pump();
    expect(focus1.hasFocus, isTrue);
    expect(focus2.hasFocus, isFalse);

    // Trigger onSubmitted
    textField1.onSubmitted?.call('test');
    await tester.pump();
    expect(focus2.hasFocus, isTrue);

    focus1.dispose();
    focus2.dispose();
  });

  testWidgets('CreateEventDialog renders all fields without keyboard double inset layout issue', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(
            body: CreateEventDialog(novelId: 'novel-1'),
          ),
        ),
      ),
    );

    expect(find.text('New Timeline Event'), findsOneWidget);
    expect(find.text('Event Title *'), findsOneWidget);
    expect(find.text('Chronological Date / Marker'), findsOneWidget);
    expect(find.text('Event Description'), findsOneWidget);
    expect(find.text('Create Event'), findsOneWidget);

    // Enter text into title without pressing enter
    await tester.enterText(find.byType(TextField).first, 'Battle of Dawn');
    await tester.pump();

    // Enter text into date without pressing enter
    await tester.enterText(find.byType(TextField).at(1), 'Year 1024');
    await tester.pump();

    expect(find.text('Battle of Dawn'), findsOneWidget);
    expect(find.text('Year 1024'), findsOneWidget);
  });
}
