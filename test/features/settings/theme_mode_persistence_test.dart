import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThemeModeNotifier persists theme changes to SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Initial state should be dark as loaded from prefs
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // Update state to light
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Verify stored in SharedPreferences
    expect(prefs.getString('app_theme_mode'), 'light');

    // Update state to system
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString('app_theme_mode'), 'system');
  });
}
