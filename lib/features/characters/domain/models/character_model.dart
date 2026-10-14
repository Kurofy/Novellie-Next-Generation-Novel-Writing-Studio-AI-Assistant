import '../../../../l10n/app_localizations.dart';

enum CharacterRole {
  protagonist,
  antagonist,
  deuteragonist,
  supporting,
  minor,
  antiHero,
  morallyGrey;

  String get label {
    switch (this) {
      case CharacterRole.protagonist:
        return 'Protagonist';
      case CharacterRole.antagonist:
        return 'Antagonist';
      case CharacterRole.deuteragonist:
        return 'Deuteragonist';
      case CharacterRole.supporting:
        return 'Supporting';
      case CharacterRole.minor:
        return 'Minor';
      case CharacterRole.antiHero:
        return 'Anti-Hero';
      case CharacterRole.morallyGrey:
        return 'Morally Grey';
    }
  }

  String getLabel([AppLocalizations? l10n]) {
    if (l10n != null) {
      switch (this) {
        case CharacterRole.protagonist:
          return l10n.roleProtagonist;
        case CharacterRole.antagonist:
          return l10n.roleAntagonist;
        case CharacterRole.deuteragonist:
          return 'Deuteragonis';
        case CharacterRole.supporting:
          return l10n.roleSupporting;
        case CharacterRole.minor:
          return l10n.roleMinor;
        case CharacterRole.antiHero:
          return 'Anti-Hero';
        case CharacterRole.morallyGrey:
          return 'Abu-abu Moral';
      }
    }
    return label;
  }

  static CharacterRole fromString(String? value) {
    if (value == null) return CharacterRole.supporting;
    final normalized = value.replaceAll(RegExp(r'[-_\s]'), '').toLowerCase();
    return CharacterRole.values.firstWhere(
      (e) =>
          e.name == value ||
          e.name.toLowerCase() == normalized,
      orElse: () => CharacterRole.supporting,
    );
  }
}

enum CharacterGender {
  male,
  female,
  custom;

  String get label {
    switch (this) {
      case CharacterGender.male:
        return 'Male';
      case CharacterGender.female:
        return 'Female';
      case CharacterGender.custom:
        return 'Custom';
    }
  }

  static CharacterGender fromString(String? value) {
    if (value == null || value.trim().isEmpty) return CharacterGender.custom;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male' ||
        normalized == 'laki-laki' ||
        normalized == 'pria' ||
        normalized == 'm') {
      return CharacterGender.male;
    }
    if (normalized == 'female' ||
        normalized == 'perempuan' ||
        normalized == 'wanita' ||
        normalized == 'f') {
      return CharacterGender.female;
    }
    return CharacterGender.custom;
  }
}

class CharacterRacePreset {
  static const List<String> presets = [
    'Human',
    'Demon',
    'Elf',
    'Dwarf',
    'Beastfolk',
    'Dragonkin',
    'Angel',
    'Spirit',
    'Undead',
    'Custom',
  ];
}

class CharacterRelationshipModel {
  final String id;
  final String novelId;
  final String characterAId;
  final String characterBId;
  final String? targetCharacterName;
  final String? targetCharacterPortrait;
  final String? targetCharacterGender;
  final String type;
  final String? customLabel;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterRelationshipModel({
    required this.id,
    required this.novelId,
    required this.characterAId,
    required this.characterBId,
    this.targetCharacterName,
    this.targetCharacterPortrait,
    this.targetCharacterGender,
    required this.type,
    this.customLabel,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayType =>
      customLabel != null && customLabel!.trim().isNotEmpty
          ? customLabel!
          : type;

  CharacterRelationshipModel copyWith({
    String? id,
    String? novelId,
    String? characterAId,
    String? characterBId,
    String? targetCharacterName,
    String? targetCharacterPortrait,
    String? targetCharacterGender,
    String? type,
    String? customLabel,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterRelationshipModel(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      characterAId: characterAId ?? this.characterAId,
      characterBId: characterBId ?? this.characterBId,
      targetCharacterName: targetCharacterName ?? this.targetCharacterName,
      targetCharacterPortrait:
          targetCharacterPortrait ?? this.targetCharacterPortrait,
      targetCharacterGender:
          targetCharacterGender ?? this.targetCharacterGender,
      type: type ?? this.type,
      customLabel: customLabel ?? this.customLabel,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CharacterModel {
  final String id;
  final String novelId;
  final String name;
  final String? nickname;
  final String? ageText;
  final String? gender;
  final String? race;
  final String? pronouns;
  final CharacterRole role;
  final String moralAlignment;
  final String status;
  final String? appearance;
  final String? personality;
  final String? motivation;
  final String? goal;
  final String? fear;
  final String? secret;
  final String? flaw;
  final String? strengths;
  final String? weaknesses;
  final String? backstory;
  final String? arcType;
  final String? arcSummary;
  final String? portraitPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterModel({
    required this.id,
    required this.novelId,
    required this.name,
    this.nickname,
    this.ageText,
    this.gender,
    this.race,
    this.pronouns,
    this.role = CharacterRole.supporting,
    this.moralAlignment = 'unspecified',
    this.status = 'alive',
    this.appearance,
    this.personality,
    this.motivation,
    this.goal,
    this.fear,
    this.secret,
    this.flaw,
    this.strengths,
    this.weaknesses,
    this.backstory,
    this.arcType,
    this.arcSummary,
    this.portraitPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  CharacterGender get genderCategory => CharacterGender.fromString(gender);

  String get displayName => nickname != null && nickname!.isNotEmpty
      ? '$name "$nickname"'
      : name;

  CharacterModel copyWith({
    String? name,
    String? nickname,
    String? ageText,
    String? gender,
    String? race,
    String? pronouns,
    CharacterRole? role,
    String? moralAlignment,
    String? status,
    String? appearance,
    String? personality,
    String? motivation,
    String? goal,
    String? fear,
    String? secret,
    String? flaw,
    String? strengths,
    String? weaknesses,
    String? backstory,
    String? arcType,
    String? arcSummary,
    String? portraitPath,
    String? notes,
    DateTime? updatedAt,
  }) {
    return CharacterModel(
      id: id,
      novelId: novelId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      ageText: ageText ?? this.ageText,
      gender: gender ?? this.gender,
      race: race ?? this.race,
      pronouns: pronouns ?? this.pronouns,
      role: role ?? this.role,
      moralAlignment: moralAlignment ?? this.moralAlignment,
      status: status ?? this.status,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      motivation: motivation ?? this.motivation,
      goal: goal ?? this.goal,
      fear: fear ?? this.fear,
      secret: secret ?? this.secret,
      flaw: flaw ?? this.flaw,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      backstory: backstory ?? this.backstory,
      arcType: arcType ?? this.arcType,
      arcSummary: arcSummary ?? this.arcSummary,
      portraitPath: portraitPath ?? this.portraitPath,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
