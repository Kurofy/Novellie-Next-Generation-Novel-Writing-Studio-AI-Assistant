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

  group('Language Settings State Management & Persistence', () {
    test('AppLanguageNotifier initializes to system when no prefs saved',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appLanguageProvider), AppLanguage.system);
      expect(container.read(currentLocaleProvider), isNull);
    });

    test('AppLanguageNotifier restores saved locale from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({'app_selected_language': 'id'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appLanguageProvider), AppLanguage.indonesian);
      expect(
        container.read(currentLocaleProvider),
        const Locale('id'),
      );
    });

    test('setLanguage switches to Indonesian and persists choice', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.indonesian);

      expect(container.read(appLanguageProvider), AppLanguage.indonesian);
      expect(
        container.read(currentLocaleProvider),
        const Locale('id'),
      );
      expect(prefs.getString('app_selected_language'), 'id');
    });

    test('setLanguage switches to English and persists choice', () async {
      SharedPreferences.setMockInitialValues({'app_selected_language': 'id'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.english);

      expect(container.read(appLanguageProvider), AppLanguage.english);
      expect(
        container.read(currentLocaleProvider),
        const Locale('en'),
      );
      expect(prefs.getString('app_selected_language'), 'en');
    });

    test('setLanguage switches back to System and persists choice', () async {
      SharedPreferences.setMockInitialValues({'app_selected_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.system);

      expect(container.read(appLanguageProvider), AppLanguage.system);
      expect(container.read(currentLocaleProvider), isNull);
      expect(prefs.getString('app_selected_language'), 'system');
    });
  });

  group('SettingsScreen Language Selection UI Tests', () {
    Widget buildSubject({SharedPreferences? prefs}) {
      return ProviderScope(
        overrides: [
          if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final currentLocale = ref.watch(currentLocaleProvider);
            return MaterialApp(
              theme: buildTheme(Brightness.light),
              locale: currentLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsScreen(),
            );
          },
        ),
      );
    }

    testWidgets('Renders Language tile and shows current selection badge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsWidgets);
      expect(find.text('System Default'), findsOneWidget);
    });

    testWidgets(
        'Tapping Language tile opens modal bottom sheet with language options',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap on the language tile
      await tester.tap(find.text('Choose your preferred application language'));
      await tester.pumpAndSettle();

      // Verify bottom sheet displays all options
      expect(find.text('System Default'), findsWidgets);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('Follow system device locale'), findsOneWidget);
    });

    testWidgets(
        'Selecting Bahasa Indonesia updates state and changes app language',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Choose your preferred application language'));
      await tester.pumpAndSettle();

      // Tap Bahasa Indonesia
      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();

      // Verify preference saved in SharedPreferences
      expect(prefs.getString('app_selected_language'), 'id');

      // Verify the UI translated to Indonesian
      expect(find.text('Pengaturan'), findsOneWidget); // Settings -> Pengaturan
      expect(find.text('Bahasa'), findsWidgets); // Language -> Bahasa
    });
  });
}
