import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/app/app.dart';

void main() {
  testWidgets('NovellieApp boots into clean Home dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NovellieApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home tab elements
    expect(find.text('Home'), findsWidgets);
    expect(find.text('No active novel'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Recent novels'), findsOneWidget);
  });
}
