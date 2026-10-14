import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/settings/application/settings_providers.dart';
import 'package:novellie/features/settings/presentation/screens/settings_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppEditorTypography Unit Tests', () {
    test('Resolves fallback and family for known typefaces', () {
      final signika = AppEditorTypography.resolveTextStyle(
        fontSize: 16,
        fontFamily: 'Signika',
      );
      expect(signika.fontFamily, 'Signika');
      expect(signika.fontSize, 16);

      final serif = AppEditorTypography.resolveTextStyle(
        fontSize: 18,
        fontFamily: 'Serif',
      );
      expect(serif.fontFamily, 'Georgia');
      expect(serif.fontFamilyFallback, contains('Times New Roman'));
      expect(serif.fontSize, 18);

      final sansSerif = AppEditorTypography.resolveTextStyle(
        fontSize: 20,
        fontFamily: 'Sans-Serif',
      );
      expect(sansSerif.fontFamily, 'Segoe UI');
      expect(sansSerif.fontFamilyFallback, contains('Roboto'));
      expect(sansSerif.fontSize, 20);

      final monospace = AppEditorTypography.resolveTextStyle(
        fontSize: 15,
        fontFamily: 'Monospace',
      );
      expect(monospace.fontFamily, 'Consolas');
      expect(monospace.fontFamilyFallback, contains('Courier New'));
      expect(monospace.fontSize, 15);
    });

    testWidgets('buildQuillStyles generates merged paragraph and heading styles',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final styles = AppEditorTypography.buildQuillStyles(
                context,
                fontSize: 22,
                fontFamily: 'Serif',
                textColor: Colors.black,
              );

              expect(styles.paragraph, isNotNull);
              expect(styles.paragraph!.style.fontSize, 22);
              expect(styles.paragraph!.style.fontFamily, 'Georgia');

              expect(styles.h1, isNotNull);
              expect(styles.h1!.style.fontSize, closeTo(22 * 1.6, 0.01));
              expect(styles.h1!.style.fontFamily, 'Georgia');

              expect(styles.placeHolder, isNotNull);
              expect(styles.placeHolder!.style.fontFamily, 'Georgia');

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('Editor Notifiers Persistence Tests', () {
    test('EditorFontSizeNotifier loads and persists preferences', () async {
      SharedPreferences.setMockInitialValues({'app_editor_font_size': 18.0});
      final prefs = await SharedPreferences.getInstance();
      final notifier = EditorFontSizeNotifier(prefs);

      expect(notifier.state, 18.0);

      await notifier.setFontSize(22.0);
      expect(notifier.state, 22.0);
      expect(prefs.getDouble('app_editor_font_size'), 22.0);
    });

    test('EditorFontFamilyNotifier loads and persists preferences', () async {
      SharedPreferences.setMockInitialValues(
        {'app_editor_font_family': 'Serif'},
      );
      final prefs = await SharedPreferences.getInstance();
      final notifier = EditorFontFamilyNotifier(prefs);

      expect(notifier.state, 'Serif');

      await notifier.setFontFamily('Monospace');
      expect(notifier.state, 'Monospace');
      expect(prefs.getString('app_editor_font_family'), 'Monospace');
    });
  });

  group('SettingsScreen Writing Editor UI Tests', () {
    Widget buildSubject({SharedPreferences? prefs}) {
      return ProviderScope(
        overrides: [
          if (prefs != null)
            sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('Renders font size slider, badges, and typeface chips',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Writing Editor'), findsOneWidget);
      expect(find.text('Editor Font Size'), findsOneWidget);
      expect(find.text('Editor Typeface'), findsOneWidget);

      // Verify typeface chips are available
      expect(find.text('Signika'), findsWidgets);
      expect(find.text('Serif'), findsOneWidget);
      expect(find.text('Sans-Serif'), findsOneWidget);
      expect(find.text('Monospace'), findsOneWidget);

      // Verify Live Manuscript Preview exists
      expect(find.text('Live Manuscript Preview'), findsOneWidget);
    });

    testWidgets('Adjusting font size updates state, preview, and SharedPreferences',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap + button to increase font size
      final addButton = find.byTooltip('Increase font size');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(prefs.getDouble('app_editor_font_size'), 17.0);
      expect(find.text('17 pt'), findsWidgets);

      // Tap - button to decrease font size
      final removeButton = find.byTooltip('Decrease font size');
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(prefs.getDouble('app_editor_font_size'), 16.0);
      expect(find.text('16 pt'), findsWidgets);
    });

    testWidgets('Selecting typeface chip updates state, preview, and SharedPreferences',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Select Serif
      final serifChip = find.text('Serif');
      await tester.tap(serifChip);
      await tester.pumpAndSettle();

      expect(prefs.getString('app_editor_font_family'), 'Serif');
      expect(find.text('Serif • 16 pt'), findsOneWidget);

      // Select Monospace
      final monospaceChip = find.text('Monospace');
      await tester.tap(monospaceChip);
      await tester.pumpAndSettle();

      expect(prefs.getString('app_editor_font_family'), 'Monospace');
      expect(find.text('Monospace • 16 pt'), findsOneWidget);
    });
  });
}
