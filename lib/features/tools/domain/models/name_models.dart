import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

enum NameGeneratorMode {
  basic,
  advanced;

  String get label {
    switch (this) {
      case NameGeneratorMode.basic:
        return 'Mode 1: Basic';
      case NameGeneratorMode.advanced:
        return 'Mode 2: Advanced (AI)';
    }
  }

  String get description {
    switch (this) {
      case NameGeneratorMode.basic:
        return 'Strictly pull verified names from curated cultural & fantasy datasets without spelling alterations.';
      case NameGeneratorMode.advanced:
        return 'AI-powered generation with hybrid origins, custom traits, lore meanings, and backstories (BYOK).';
    }
  }
}

class NameGenderData {
  final List<String> firstNames;
  final List<String> lastNames;

  const NameGenderData({
    required this.firstNames,
    required this.lastNames,
  });

  factory NameGenderData.fromJson(Map<String, dynamic> json) {
    return NameGenderData(
      firstNames: (json['first_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastNames: (json['last_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'first_names': firstNames,
        'last_names': lastNames,
      };
}

class NameCategoryData {
  final String category;
  final NameGenderData male;
  final NameGenderData female;
  final NameGenderData unisex;

  const NameCategoryData({
    required this.category,
    required this.male,
    required this.female,
    required this.unisex,
  });

  factory NameCategoryData.fromJson(Map<String, dynamic> json) {
    return NameCategoryData(
      category: json['category'] as String? ?? 'Unknown',
      male: NameGenderData.fromJson(
        (json['male'] as Map<String, dynamic>?) ?? {},
      ),
      female: NameGenderData.fromJson(
        (json['female'] as Map<String, dynamic>?) ?? {},
      ),
      unisex: NameGenderData.fromJson(
        (json['unisex'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  NameGenderData forGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return male;
      case 'female':
        return female;
      case 'unisex':
      default:
        return unisex;
    }
  }

  IconData get iconSymbol {
    switch (category.toLowerCase()) {
      case 'roman':
        return Symbols.account_balance;
      case 'greek':
        return Symbols.bolt;
      case 'nordic':
        return Symbols.shield;
      case 'english':
        return Symbols.castle;
      case 'german':
        return Symbols.fort;
      case 'chinese':
        return Symbols.temple_buddhist;
      case 'korean':
        return Symbols.spa;
      case 'japanese':
        return Symbols.landscape;
      case 'indonesian':
        return Symbols.volcano;
      case 'vampire':
        return Symbols.nightlight;
      case 'human':
        return Symbols.person;
      case 'elf':
        return Symbols.park;
      case 'demon':
        return Symbols.whatshot;
      case 'dragon':
        return Symbols.auto_awesome;
      default:
        return Symbols.auto_stories;
    }
  }

  String get iconEmoji => '';
}

class GeneratedName {
  final String id;
  final String firstName;
  final String lastName;
  final String category;
  final String gender;
  final String? title; // e.g. "The Frostbane"
  final String? meaning; // fictional meaning behind name
  final String? backstory; // brief backstory
  final bool isAiGenerated;
  final DateTime timestamp;

  const GeneratedName({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.category,
    required this.gender,
    this.title,
    this.meaning,
    this.backstory,
    this.isAiGenerated = false,
    required this.timestamp,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'category': category,
        'gender': gender,
        'title': title,
        'meaning': meaning,
        'backstory': backstory,
        'is_ai_generated': isAiGenerated,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GeneratedName.fromJson(Map<String, dynamic> json) {
    return GeneratedName(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      gender: json['gender'] as String? ?? 'unisex',
      title: json['title'] as String?,
      meaning: json['meaning'] as String?,
      backstory: json['backstory'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
