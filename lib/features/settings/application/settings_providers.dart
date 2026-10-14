import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? _prefs;
  static const _key = 'app_theme_mode';

  ThemeModeNotifier([this._prefs]) : super(_initialMode(_prefs)) {
    if (_prefs == null) {
      _loadAsync();
    }
  }

  static ThemeMode _initialMode(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.system;
    final saved = prefs.getString(_key);
    return _parseMode(saved);
  }

  static ThemeMode _parseMode(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        state = _parseMode(saved);
      }
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
  }

  @override
  set state(ThemeMode value) {
    super.state = value;
    _saveAsync(value);
  }

  Future<void> _saveAsync(ThemeMode mode) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (e) {
      debugPrint('Failed to persist theme preference: $e');
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeColorNotifier extends StateNotifier<AppThemeColor> {
  final SharedPreferences? _prefs;
  static const _key = 'app_theme_color';

  ThemeColorNotifier([this._prefs]) : super(_initialColor(_prefs)) {
    if (_prefs == null) {
      _loadAsync();
    }
  }

  static AppThemeColor _initialColor(SharedPreferences? prefs) {
    if (prefs == null) return AppThemeColor.ocean;
    final saved = prefs.getString(_key);
    return AppThemeColor.fromId(saved);
  }

  Future<void> _loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        state = AppThemeColor.fromId(saved);
      }
    } catch (e) {
      debugPrint('Failed to load theme color preference: $e');
    }
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    state = color;
  }

  @override
  set state(AppThemeColor value) {
    super.state = value;
    _saveAsync(value);
  }

  Future<void> _saveAsync(AppThemeColor color) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key, color.id);
    } catch (e) {
      debugPrint('Failed to persist theme color preference: $e');
    }
  }
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, AppThemeColor>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeColorNotifier(prefs);
});

class EditorFontSizeNotifier extends StateNotifier<double> {
  final SharedPreferences? _prefs;
  static const _key = 'app_editor_font_size';
  static const defaultSize = 16.0;

  EditorFontSizeNotifier([this._prefs]) : super(_initialSize(_prefs)) {
    if (_prefs == null) {
      _loadAsync();
    }
  }

  static double _initialSize(SharedPreferences? prefs) {
    if (prefs == null) return defaultSize;
    return prefs.getDouble(_key) ?? defaultSize;
  }

  Future<void> _loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_key);
      if (saved != null) {
        state = saved;
      }
    } catch (e) {
      debugPrint('Failed to load editor font size preference: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    state = size;
  }

  @override
  set state(double value) {
    super.state = value;
    _saveAsync(value);
  }

  Future<void> _saveAsync(double size) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setDouble(_key, size);
    } catch (e) {
      debugPrint('Failed to persist editor font size preference: $e');
    }
  }
}

final editorFontSizeProvider =
    StateNotifierProvider<EditorFontSizeNotifier, double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EditorFontSizeNotifier(prefs);
});

class EditorFontFamilyNotifier extends StateNotifier<String> {
  final SharedPreferences? _prefs;
  static const _key = 'app_editor_font_family';
  static const defaultFamily = 'Signika';

  EditorFontFamilyNotifier([this._prefs]) : super(_initialFamily(_prefs)) {
    if (_prefs == null) {
      _loadAsync();
    }
  }

  static String _initialFamily(SharedPreferences? prefs) {
    if (prefs == null) return defaultFamily;
    return prefs.getString(_key) ?? defaultFamily;
  }

  Future<void> _loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        state = saved;
      }
    } catch (e) {
      debugPrint('Failed to load editor font family preference: $e');
    }
  }

  Future<void> setFontFamily(String family) async {
    state = family;
  }

  @override
  set state(String value) {
    super.state = value;
    _saveAsync(value);
  }

  Future<void> _saveAsync(String family) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key, family);
    } catch (e) {
      debugPrint('Failed to persist editor font family preference: $e');
    }
  }
}

final editorFontFamilyProvider =
    StateNotifierProvider<EditorFontFamilyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EditorFontFamilyNotifier(prefs);
});

enum AppLanguage {
  system('system'),
  english('en'),
  indonesian('id');

  final String code;
  const AppLanguage(this.code);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'id':
        return AppLanguage.indonesian;
      case 'system':
      default:
        return AppLanguage.system;
    }
  }

  Locale? get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.indonesian:
        return const Locale('id');
      case AppLanguage.system:
        return null;
    }
  }
}

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  final SharedPreferences? _prefs;
  static const _key = 'app_selected_language';

  AppLanguageNotifier([this._prefs]) : super(_initialLanguage(_prefs)) {
    if (_prefs == null) {
      _loadAsync();
    }
  }

  static AppLanguage _initialLanguage(SharedPreferences? prefs) {
    if (prefs == null) return AppLanguage.system;
    final saved = prefs.getString(_key);
    return AppLanguage.fromCode(saved);
  }

  Future<void> _loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        state = AppLanguage.fromCode(saved);
      }
    } catch (e) {
      debugPrint('Failed to load language preference: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
  }

  @override
  set state(AppLanguage value) {
    super.state = value;
    _saveAsync(value);
  }

  Future<void> _saveAsync(AppLanguage language) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key, language.code);
    } catch (e) {
      debugPrint('Failed to persist language preference: $e');
    }
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLanguageNotifier(prefs);
});

final currentLocaleProvider = Provider<Locale?>((ref) {
  return ref.watch(appLanguageProvider).locale;
});
