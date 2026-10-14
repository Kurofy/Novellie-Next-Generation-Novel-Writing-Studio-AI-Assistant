import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../characters/domain/models/character_model.dart';

enum AiIndexEntityType {
  character,
  location,
  organization,
  faction,
  religion,
  lore;

  String get label {
    switch (this) {
      case AiIndexEntityType.character:
        return 'Character';
      case AiIndexEntityType.location:
        return 'Location';
      case AiIndexEntityType.organization:
        return 'Organization';
      case AiIndexEntityType.faction:
        return 'Faction';
      case AiIndexEntityType.religion:
        return 'Religion';
      case AiIndexEntityType.lore:
        return 'World Lore';
    }
  }

  IconData get icon {
    switch (this) {
      case AiIndexEntityType.character:
        return Symbols.person;
      case AiIndexEntityType.location:
        return Symbols.pin_drop;
      case AiIndexEntityType.organization:
        return Symbols.corporate_fare;
      case AiIndexEntityType.faction:
        return Symbols.shield;
      case AiIndexEntityType.religion:
        return Symbols.church;
      case AiIndexEntityType.lore:
        return Symbols.auto_awesome;
    }
  }

  Color get color {
    switch (this) {
      case AiIndexEntityType.character:
        return const Color(0xFF6366F1); // Indigo
      case AiIndexEntityType.location:
        return const Color(0xFF10B981); // Emerald
      case AiIndexEntityType.organization:
        return const Color(0xFFF59E0B); // Amber
      case AiIndexEntityType.faction:
        return const Color(0xFFEC4899); // Pink
      case AiIndexEntityType.religion:
        return const Color(0xFF8B5CF6); // Purple
      case AiIndexEntityType.lore:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  static AiIndexEntityType fromString(String? typeStr) {
    if (typeStr == null) return AiIndexEntityType.lore;
    final lower = typeStr.toLowerCase().trim();
    if (lower.contains('char') || lower.contains('person')) {
      return AiIndexEntityType.character;
    }
    if (lower.contains('loc') ||
        lower.contains('city') ||
        lower.contains('country') ||
        lower.contains('place') ||
        lower.contains('region')) {
      return AiIndexEntityType.location;
    }
    if (lower.contains('org') || lower.contains('guild') || lower.contains('company')) {
      return AiIndexEntityType.organization;
    }
    if (lower.contains('fact') || lower.contains('clan') || lower.contains('army')) {
      return AiIndexEntityType.faction;
    }
    if (lower.contains('relig') ||
        lower.contains('faith') ||
        lower.contains('cult') ||
        lower.contains('god') ||
        lower.contains('temple')) {
      return AiIndexEntityType.religion;
    }
    return AiIndexEntityType.lore;
  }
}

class AiIndexEntity {
  final String id;
  final String name;
  final AiIndexEntityType type;
  final String categoryKey;
  final String summary;
  final CharacterRole characterRole;
  final String? sourceChapterTitle;
  final String? sourceChapterId;
  final bool isAlreadyInIndex;
  final bool isAdded;
  final bool isSelected;

  const AiIndexEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryKey,
    required this.summary,
    this.characterRole = CharacterRole.supporting,
    this.sourceChapterTitle,
    this.sourceChapterId,
    this.isAlreadyInIndex = false,
    this.isAdded = false,
    this.isSelected = true,
  });

  AiIndexEntity copyWith({
    String? id,
    String? name,
    AiIndexEntityType? type,
    String? categoryKey,
    String? summary,
    CharacterRole? characterRole,
    String? sourceChapterTitle,
    String? sourceChapterId,
    bool? isAlreadyInIndex,
    bool? isAdded,
    bool? isSelected,
  }) {
    return AiIndexEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryKey: categoryKey ?? this.categoryKey,
      summary: summary ?? this.summary,
      characterRole: characterRole ?? this.characterRole,
      sourceChapterTitle: sourceChapterTitle ?? this.sourceChapterTitle,
      sourceChapterId: sourceChapterId ?? this.sourceChapterId,
      isAlreadyInIndex: isAlreadyInIndex ?? this.isAlreadyInIndex,
      isAdded: isAdded ?? this.isAdded,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory AiIndexEntity.fromJson(
    Map<String, dynamic> json, {
    String? sourceChapterTitle,
    String? sourceChapterId,
  }) {
    final type = AiIndexEntityType.fromString(json['type']?.toString());
    final rawRole = json['role']?.toString();
    final role = rawRole != null
        ? CharacterRole.fromString(rawRole)
        : CharacterRole.supporting;

    String defaultCategoryKey = 'concepts';
    switch (type) {
      case AiIndexEntityType.character:
        defaultCategoryKey = 'characters';
        break;
      case AiIndexEntityType.location:
        defaultCategoryKey = 'locations';
        break;
      case AiIndexEntityType.organization:
        defaultCategoryKey = 'organizations';
        break;
      case AiIndexEntityType.faction:
        defaultCategoryKey = 'factions';
        break;
      case AiIndexEntityType.religion:
        defaultCategoryKey = 'religions';
        break;
      case AiIndexEntityType.lore:
        defaultCategoryKey = 'concepts';
        break;
    }

    return AiIndexEntity(
      id: generateUuid(),
      name: (json['name'] ?? '').toString().trim(),
      type: type,
      categoryKey: (json['categoryKey'] ?? defaultCategoryKey).toString().trim(),
      summary: (json['summary'] ?? json['description'] ?? '').toString().trim(),
      characterRole: role,
      sourceChapterTitle: sourceChapterTitle,
      sourceChapterId: sourceChapterId,
      isAlreadyInIndex: false,
      isAdded: false,
      isSelected: true,
    );
  }
}
