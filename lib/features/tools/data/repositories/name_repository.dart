import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/name_models.dart';

class NameRepository {
  List<NameCategoryData>? _cachedCategories;
  final Random _random = Random();

  Future<List<NameCategoryData>> loadCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/novellie_names_all.json');
      final dynamic raw = jsonDecode(jsonString);

      if (raw is List) {
        _cachedCategories = raw
            .map((e) => NameCategoryData.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _cachedCategories = [];
      }
      return _cachedCategories!;
    } catch (e) {
      // Fallback empty list if error
      return [];
    }
  }

  /// Mode 1: Basic Name Generator
  /// Strictly retrieves random first_name and random last_name from the exact matching
  /// category and gender arrays inside novellie_names_all.json.
  /// Does not alter spelling or invent new names.
  Future<List<GeneratedName>> generateBasicNames({
    required String category,
    required String gender,
    required int count,
  }) async {
    final categories = await loadCategories();
    final matchedCategory = categories.firstWhere(
      (c) => c.category.toLowerCase() == category.toLowerCase(),
      orElse: () => categories.isNotEmpty
          ? categories.first
          : throw StateError('No categories loaded'),
    );

    final normalizedGender = gender.toLowerCase();
    final genderData = matchedCategory.forGender(normalizedGender);

    final firstNames = genderData.firstNames;
    final lastNames = genderData.lastNames;

    if (firstNames.isEmpty || lastNames.isEmpty) {
      return [];
    }

    final results = <GeneratedName>[];
    final usedPairs = <String>{};
    final maxAttempts = count * 10;
    var attempts = 0;

    while (results.length < count && attempts < maxAttempts) {
      attempts++;
      final firstName = firstNames[_random.nextInt(firstNames.length)];
      final lastName = lastNames[_random.nextInt(lastNames.length)];
      final key = '$firstName $lastName';

      // Avoid immediate duplicates if possible
      if (!usedPairs.contains(key) || attempts > count * 3) {
        usedPairs.add(key);
        results.add(
          GeneratedName(
            id: generateUuid(),
            firstName: firstName,
            lastName: lastName,

            category: matchedCategory.category,
            gender: normalizedGender,
            isAiGenerated: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    return results;
  }

  /// Provides linguistic patterns and syllable samples for Mode 2 AI Prompt
  Future<String> getLinguisticSampleSummary(Iterable<String>? requestedCategories) async {
    final categories = await loadCategories();
    final buffer = StringBuffer();

    final targetCats = (requestedCategories != null && requestedCategories.isNotEmpty)
        ? categories.where(
            (c) => requestedCategories.any(
              (req) => req.toLowerCase() == c.category.toLowerCase(),
            ),
          )
        : categories;


    for (final cat in targetCats) {
      buffer.writeln('Category: ${cat.category}');
      buffer.writeln(
        '  Sample First Names (Male): ${cat.male.firstNames.take(8).join(", ")}',
      );
      buffer.writeln(
        '  Sample First Names (Female): ${cat.female.firstNames.take(8).join(", ")}',
      );
      buffer.writeln(
        '  Sample Last Names: ${cat.male.lastNames.take(8).join(", ")}',
      );
    }

    return buffer.toString();
  }
}
