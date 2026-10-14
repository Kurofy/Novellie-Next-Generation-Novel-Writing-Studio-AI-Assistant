import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/ai/presentation/screens/ai_chat_screen.dart';
import 'package:novellie/features/dashboard/presentation/screens/home_screen.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/novels/presentation/screens/novel_library_screen.dart';
import 'package:novellie/features/outline/presentation/screens/planning_hub_screen.dart';
import 'package:novellie/features/settings/presentation/screens/more_menu_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  Widget buildTestableScreen(
    Widget screen, {
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        novelListStreamProvider.overrideWith(
          (ref) => Stream.value(<NovelModel>[]),
        ),
        activeNovelProvider.overrideWithValue(
          const AsyncValue.data(null),
        ),
      ],
      child: MaterialApp(
        title: 'Novellie Test',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
  }

  group('Empty State Screen Verification', () {
    final screens = <String, Widget>{
      'HomeScreen': const HomeScreen(),
      'NovelLibraryScreen': const NovelLibraryScreen(),
      'PlanningHubScreen': const PlanningHubScreen(),
      'AiChatScreen': const AiChatScreen(),
      'MoreMenuScreen': const MoreMenuScreen(),
    };

    final widths = [320.0, 390.0];
    final textScales = [1.0, 1.5];

    for (final entry in screens.entries) {
      for (final width in widths) {
        for (final scale in textScales) {
          testWidgets(
              '${entry.key} renders correctly at ${width}dp, textScale $scale',
              (tester) async {
            tester.view.physicalSize = Size(width * 2.0, 844 * 2.0);
            tester.view.devicePixelRatio = 2.0;
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(
              buildTestableScreen(entry.value, textScale: scale),
            );
            await tester.pumpAndSettle();

            expect(find.byType(entry.value.runtimeType), findsOneWidget);
          });
        }
      }
    }
  });
}
