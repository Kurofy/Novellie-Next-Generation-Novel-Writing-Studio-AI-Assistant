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

  group('AppThemeColor Model & Palette Tests', () {
    test('Default color is ocean with isDefault true', () {
      expect(AppThemeColor.ocean.isDefault, isTrue);
      expect(AppThemeColor.ocean.displayName, 'Ocean Blue');
      expect(AppThemeColor.fromId(null), AppThemeColor.ocean);
      expect(AppThemeColor.fromId('ocean'), AppThemeColor.ocean);
      expect(AppThemeColor.fromId('unknown'), AppThemeColor.ocean);
    });

    test('All theme color values resolve correctly fromId', () {
      expect(AppThemeColor.fromId('purple'), AppThemeColor.purple);
      expect(AppThemeColor.fromId('green'), AppThemeColor.green);
      expect(AppThemeColor.fromId('red'), AppThemeColor.red);
      expect(AppThemeColor.fromId('amber'), AppThemeColor.amber);
      expect(AppThemeColor.fromId('teal'), AppThemeColor.teal);
    });

    test('ThemeData builds with custom theme color', () {
      final purpleLight = buildTheme(Brightness.light, AppThemeColor.purple);
      final greenDark = buildTheme(Brightness.dark, AppThemeColor.green);

      expect(purpleLight.brightness, Brightness.light);
      expect(greenDark.brightness, Brightness.dark);

      final purpleColors = purpleLight.extension<AppColors>()!;
      expect(purpleColors.primary, equals(const Color(0xFF5E35B1)));

      final greenColors = greenDark.extension<AppColors>()!;
      expect(greenColors.primary, equals(const Color(0xFF81C784)));
    });
  });

  group('ThemeColorNotifier Persistence Tests', () {
    test('Loads default ocean when no preference saved', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeColorNotifier(prefs);

      expect(notifier.state, AppThemeColor.ocean);
    });

    test('Loads saved color preference when present', () async {
      SharedPreferences.setMockInitialValues({'app_theme_color': 'purple'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeColorNotifier(prefs);

      expect(notifier.state, AppThemeColor.purple);
    });

    test('Saves color preference to SharedPreferences on update', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeColorNotifier(prefs);

      notifier.state = AppThemeColor.green;
      expect(notifier.state, AppThemeColor.green);
      expect(prefs.getString('app_theme_color'), 'green');

      notifier.state = AppThemeColor.red;
      expect(notifier.state, AppThemeColor.red);
      expect(prefs.getString('app_theme_color'), 'red');
    });
  });

  group('SettingsScreen Theme Color UI Tests', () {
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

    testWidgets('Renders Color Theme header, tiles, and Primary badge',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Primary Color Theme'), findsOneWidget);
      expect(find.text('Ocean Blue'), findsNWidgets(2)); // in tile + active preview
      expect(find.text('Royal Purple'), findsOneWidget);
      expect(find.text('Forest Green'), findsOneWidget);
      expect(find.text('Crimson Red'), findsOneWidget);
      expect(find.text('Warm Amber'), findsOneWidget);
      expect(find.text('Nordic Teal'), findsOneWidget);
      expect(find.text('Primary'), findsWidgets);
    });

    testWidgets('Tapping a theme color updates selection and active preview',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap Royal Purple
      final purpleTile = find.text('Royal Purple');
      expect(purpleTile, findsOneWidget);
      await tester.tap(purpleTile);
      await tester.pumpAndSettle();

      // Check persisted value
      expect(prefs.getString('app_theme_color'), 'purple');

      // Tap Forest Green
      final greenTile = find.text('Forest Green');
      await tester.tap(greenTile);
      await tester.pumpAndSettle();
      expect(prefs.getString('app_theme_color'), 'green');

      // Tap Crimson Red
      final redTile = find.text('Crimson Red');
      await tester.tap(redTile);
      await tester.pumpAndSettle();
      expect(prefs.getString('app_theme_color'), 'red');

      // Tap back to Ocean Blue (Primary)
      final oceanTile = find.text('Ocean Blue');
      await tester.tap(oceanTile);
      await tester.pumpAndSettle();
      expect(prefs.getString('app_theme_color'), 'ocean');
    });
  });
}
