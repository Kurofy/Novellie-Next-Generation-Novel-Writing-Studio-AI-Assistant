import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../ai/application/ai_providers.dart';
import '../data/repositories/name_repository.dart';

import '../domain/models/name_models.dart';

final nameRepositoryProvider = Provider<NameRepository>((ref) {
  return NameRepository();
});

final nameCategoriesProvider = FutureProvider<List<NameCategoryData>>((ref) async {
  return ref.watch(nameRepositoryProvider).loadCategories();
});

final activeNameGenModeProvider =
    StateProvider<NameGeneratorMode>((ref) => NameGeneratorMode.basic);

// --- Mode 1: Basic State ---
final basicCategoryProvider = StateProvider<String>((ref) => 'Elf');
final basicGenderProvider = StateProvider<String>((ref) => 'female');
final basicCountProvider = StateProvider<int>((ref) => 5);
final basicResultsProvider = StateProvider<List<GeneratedName>>((ref) => []);

// --- Mode 2: Advanced AI (BYOK) State ---
final advancedTraitsPromptProvider = StateProvider<String>((ref) => '');
final advancedOriginTagsProvider = StateProvider<Set<String>>((ref) => {'Demon', 'Nordic'});
final advancedGenderProvider = StateProvider<String>((ref) => 'any');
final advancedCountProvider = StateProvider<int>((ref) => 3);
final advancedResultsProvider = StateProvider<List<GeneratedName>>((ref) => []);
final advancedIsGeneratingProvider = StateProvider<bool>((ref) => false);
final advancedErrorProvider = StateProvider<String?>((ref) => null);

// --- Favorites Notifier ---
class FavoriteNamesNotifier extends StateNotifier<List<GeneratedName>> {
  FavoriteNamesNotifier() : super([]) {
    _loadFavorites();
  }

  static const _prefKey = 'novellie_favorite_names';

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefKey);
      if (rawList != null) {
        state = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return GeneratedName.fromJson(map);
        }).toList();
      }
    } catch (_) {}
  }

  Future<void> toggleFavorite(GeneratedName name) async {
    final exists = state.any((e) => e.fullName == name.fullName);
    if (exists) {
      state = state.where((e) => e.fullName != name.fullName).toList();
    } else {
      state = [name, ...state];
    }
    await _persist();

  }

  bool isFavorite(GeneratedName name) {
    return state.any((e) => e.fullName == name.fullName);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listStr = state.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_prefKey, listStr);
    } catch (_) {}
  }
}

final favoriteNamesProvider =
    StateNotifierProvider<FavoriteNamesNotifier, List<GeneratedName>>((ref) {
  return FavoriteNamesNotifier();
});

// --- Name Generator Controller ---
class NameGeneratorController {
  final Ref _ref;

  NameGeneratorController(this._ref);

  Future<void> generateBasic() async {
    try {
      final repo = _ref.read(nameRepositoryProvider);
      final category = _ref.read(basicCategoryProvider);
      final gender = _ref.read(basicGenderProvider);
      final count = _ref.read(basicCountProvider);

      final names = await repo.generateBasicNames(
        category: category,
        gender: gender,
        count: count,
      );

      _ref.read(basicResultsProvider.notifier).state = names;
    } catch (_) {}
  }


  Future<void> generateAdvanced() async {
    final configAsync = _ref.read(aiConfigProvider);
    final config = configAsync.valueOrNull;

    if (config == null || !config.isConfigured) {
      _ref.read(advancedErrorProvider.notifier).state =
          'AI Assistant is not configured. Please add your API key in AI settings.';
      return;
    }

    final promptText = _ref.read(advancedTraitsPromptProvider).trim();
    if (promptText.isEmpty) {
      _ref.read(advancedErrorProvider.notifier).state =
          'Please enter character traits, aesthetic, or backstory.';
      return;
    }

    _ref.read(advancedIsGeneratingProvider.notifier).state = true;
    _ref.read(advancedErrorProvider.notifier).state = null;

    try {
      final repo = _ref.read(nameRepositoryProvider);
      final count = _ref.read(advancedCountProvider);
      final originTags = _ref.read(advancedOriginTagsProvider);
      final gender = _ref.read(advancedGenderProvider);

      final linguisticRef = await repo.getLinguisticSampleSummary(originTags);

      final fullPrompt = StringBuffer();
      fullPrompt.writeln(
        'You are Novellie Master Name Generator, an expert fantasy & world-building onomastician.',
      );
      fullPrompt.writeln();
      fullPrompt.writeln('Task: Mode 2 - Advanced Names Generator with AI.');
      fullPrompt.writeln(
        'Generate exactly $count unique character names based on the user\'s requested traits, aesthetic, or hybrid origin.',
      );
      fullPrompt.writeln();
      fullPrompt.writeln('User Request:');
      fullPrompt.writeln('"$promptText"');
      if (gender != 'any') {
        fullPrompt.writeln('Preferred Gender: $gender');
      }
      if (originTags.isNotEmpty) {
        fullPrompt.writeln('Target Origins / Influences: ${originTags.join(", ")}');
      }
      fullPrompt.writeln();
      fullPrompt.writeln(
        'Foundational Linguistic & Syllable Knowledge Base from novellie_names_all.json:',
      );
      fullPrompt.writeln(linguisticRef);
      fullPrompt.writeln();
      fullPrompt.writeln('Instructions:');
      fullPrompt.writeln(
        '1. Use the linguistic patterns, syllables, and structural style found in the reference dataset above as your foundational knowledge base.',
      );
      fullPrompt.writeln(
        '2. You have full creative freedom to mix and match first and last names across different categories, modify syllables to create unique variations, or generate entirely new names that fit the requested aesthetic.',
      );
      fullPrompt.writeln(
        '3. For EACH generated name, output a brief AI-crafted backstory (2-3 sentences), a fitting title/epithet (e.g. "The Frostbane", "Shadowweaver"), and the fictional meaning behind the name.',
      );
      fullPrompt.writeln(
        '4. Respond ONLY with a valid JSON array of objects. Do not include extra conversational text outside the JSON.',
      );
      fullPrompt.writeln('Format example:');
      fullPrompt.writeln('''[
  {
    "first_name": "Valerius",
    "last_name": "Frostgard",
    "title": "The Frostbane",
    "category": "Demon / Nordic",
    "meaning": "Strength born from eternal glaciers and infernal blood",
    "backstory": "A exiled warlord from the jagged crags of the northern frontier who unified the splintered frost-clans under an iron banner."
  }
]''');

      final aiClient = _ref.read(aiClientServiceProvider);
      final responseText = await aiClient.sendMessage(
        config: config,
        prompt: fullPrompt.toString(),
      );

      final parsedList = _parseAiNames(responseText, originTags.join(' / '));
      _ref.read(advancedResultsProvider.notifier).state = parsedList;
    } catch (e) {
      _ref.read(advancedErrorProvider.notifier).state =
          'Failed to generate names: ${e.toString().replaceAll("Exception: ", "")}';
    } finally {
      _ref.read(advancedIsGeneratingProvider.notifier).state = false;
    }
  }

  List<GeneratedName> _parseAiNames(String response, String defaultCategory) {
    var clean = response.trim();
    // Strip markdown code fences if present
    if (clean.contains('```json')) {
      final start = clean.indexOf('```json') + 7;
      final end = clean.lastIndexOf('```');
      if (end > start) {
        clean = clean.substring(start, end).trim();
      }
    } else if (clean.contains('```')) {
      final start = clean.indexOf('```') + 3;
      final end = clean.lastIndexOf('```');
      if (end > start) {
        clean = clean.substring(start, end).trim();
      }
    }

    try {
      final dynamic decoded = jsonDecode(clean);
      if (decoded is List) {
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return GeneratedName(
            id: generateUuid(),
            firstName: map['first_name'] as String? ?? 'Unnamed',
            lastName: map['last_name'] as String? ?? '',
            category: map['category'] as String? ??
                (defaultCategory.isNotEmpty ? defaultCategory : 'AI Hybrid'),
            gender: map['gender'] as String? ?? 'unisex',
            title: map['title'] as String?,
            meaning: map['meaning'] as String?,
            backstory: map['backstory'] as String?,
            isAiGenerated: true,
            timestamp: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {
      // Fallback: simple line/regex extraction if JSON was imperfect
      final lines = clean.split('\n');
      final fallbackNames = <GeneratedName>[];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith(RegExp(r'\d+[\.\)]|\-')) && trimmed.length > 3) {
          final text = trimmed.replaceFirst(RegExp(r'^\d+[\.\)]|\-\s*'), '').trim();
          final parts = text.split(' ');
          final first = parts.isNotEmpty ? parts[0] : 'Hero';
          final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          fallbackNames.add(
            GeneratedName(
              id: generateUuid(),
              firstName: first,
              lastName: last,

              category: defaultCategory.isNotEmpty ? defaultCategory : 'AI Hybrid',
              gender: 'unisex',
              title: null,
              meaning: null,
              backstory: null,
              isAiGenerated: true,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      if (fallbackNames.isNotEmpty) return fallbackNames;
    }

    return [];
  }
}

final nameGeneratorControllerProvider = Provider<NameGeneratorController>((ref) {
  return NameGeneratorController(ref);
});
