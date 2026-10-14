import 'dart:convert';
import '../../../characters/domain/models/character_model.dart';
import '../../../world/domain/models/world_models.dart';
import '../../domain/models/ai_index_models.dart';
import '../../domain/models/ai_models.dart';
import 'ai_client_service.dart';

class AiIndexService {
  final AiClientService _aiClient;

  AiIndexService(this._aiClient);

  Future<List<AiIndexEntity>> scanManuscript({
    required AiConfigModel config,
    required String novelId,
    required List<({String id, String title, String plainText})> chapters,
    required List<CharacterModel> existingCharacters,
    required List<WorldEntryModel> existingWorldEntries,
  }) async {
    if (chapters.isEmpty) return [];

    List<AiIndexEntity> extracted = [];

    if (config.isConfigured) {
      try {
        extracted = await _runAiExtraction(
          config: config,
          novelId: novelId,
          chapters: chapters,
        );
      } catch (_) {
        // Fallback to heuristic scanner if AI call fails
        extracted = _runHeuristicExtraction(chapters);
      }
    } else {
      extracted = _runHeuristicExtraction(chapters);
    }

    // Deduplicate extracted items by lowercase name
    final Map<String, AiIndexEntity> uniqueMap = {};
    for (final entity in extracted) {
      final key = entity.name.toLowerCase().trim();
      if (key.isNotEmpty && !uniqueMap.containsKey(key)) {
        uniqueMap[key] = entity;
      }
    }
    final uniqueList = uniqueMap.values.toList();

    // Cross-reference with existing characters and world entries
    final existingCharNames = existingCharacters
        .map((c) => c.displayName.toLowerCase().trim())
        .toSet();
    final existingEntryNames = existingWorldEntries
        .map((e) => e.name.toLowerCase().trim())
        .toSet();

    return uniqueList.map((entity) {
      final key = entity.name.toLowerCase().trim();
      final alreadyExists =
          existingCharNames.contains(key) || existingEntryNames.contains(key);

      return entity.copyWith(
        isAlreadyInIndex: alreadyExists,
        isSelected: !alreadyExists,
      );
    }).toList();
  }

  Future<List<AiIndexEntity>> _runAiExtraction({
    required AiConfigModel config,
    required String novelId,
    required List<({String id, String title, String plainText})> chapters,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are a master story archivist and indexer. Analyze the following chapter(s) from a novel manuscript and extract every named character, location, organization, faction, religion, and world lore entity.',
    );
    buffer.writeln('Categorize each entity accurately:');
    buffer.writeln('- character: Named people, gods in human form, or primary figures.');
    buffer.writeln('- location: Cities, kingdoms, continents, taverns, castles, regions, landmarks.');
    buffer.writeln('- organization: Guilds, institutes, orders, businesses, schools.');
    buffer.writeln('- faction: Political factions, rebel groups, war alliances, clans.');
    buffer.writeln('- religion: Faiths, cults, deities, churches, pantheons.');
    buffer.writeln('- lore: Magic systems, legendary artifacts, creatures, economic concepts.');
    buffer.writeln();
    buffer.writeln('Respond ONLY with a valid JSON array of objects. Example:');
    buffer.writeln(r'''
[
  {
    "name": "Kaelen Drake",
    "type": "character",
    "role": "protagonist",
    "summary": "A disgraced celestial knight seeking redemption in the outlands."
  },
  {
    "name": "Valenhold",
    "type": "location",
    "categoryKey": "cities",
    "summary": "The mountain fortress city guarding the Frostpass gap."
  },
  {
    "name": "The Obsidian Order",
    "type": "organization",
    "categoryKey": "organizations",
    "summary": "An ancient brotherhood studying forbidden blood alchemy."
  },
  {
    "name": "Iron Pact",
    "type": "faction",
    "categoryKey": "factions",
    "summary": "A coalition of frontier clans resisting imperial taxation."
  },
  {
    "name": "Solar Pantheon",
    "type": "religion",
    "categoryKey": "religions",
    "summary": "The dominant state religion worshipping the Golden Dawn."
  },
  {
    "name": "Aetherium Shards",
    "type": "lore",
    "categoryKey": "important_objects",
    "summary": "Crystallized mana remnants used to power arcane siege engines."
  }
]
''');
    buffer.writeln('\n--- MANUSCRIPT EXCERPTS ---');

    for (final ch in chapters) {
      buffer.writeln('\n### Chapter: ${ch.title}');
      // Bound chapter length to keep within context window
      final text = ch.plainText.trim();
      final excerpt = text.length > 8000 ? text.substring(0, 8000) : text;
      buffer.writeln(excerpt);
    }

    final response = await _aiClient.sendMessage(
      config: config,
      prompt: buffer.toString(),
    );

    return _parseJsonResponse(response, chapters.firstOrNull?.title);
  }

  List<AiIndexEntity> _parseJsonResponse(String rawResponse, String? defaultSourceTitle) {
    try {
      String clean = rawResponse.trim();
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

      final startBracket = clean.indexOf('[');
      final endBracket = clean.lastIndexOf(']');
      if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
        clean = clean.substring(startBracket, endBracket + 1);
      }

      final dynamic decoded = jsonDecode(clean);
      if (decoded is List) {
        return decoded
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) => AiIndexEntity.fromJson(
                Map<String, dynamic>.from(item),
                sourceChapterTitle: defaultSourceTitle,
              ),
            )
            .where((e) => e.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fast local heuristic scanner for proper nouns, titles, and lore patterns
  List<AiIndexEntity> _runHeuristicExtraction(
    List<({String id, String title, String plainText})> chapters,
  ) {
    final List<AiIndexEntity> results = [];
    final seen = <String>{};

    for (final ch in chapters) {
      final text = ch.plainText;
      if (text.trim().isEmpty) continue;

      // 1. Character Title patterns
      final charRegex = RegExp(
        r'\b(King|Queen|Lord|Lady|Prince|Princess|Captain|General|Sir|Lady|Master|Commander|Duke|Duchess|Emperor|Empress|Elder|Archmage|Priest|Father)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
      );
      for (final match in charRegex.allMatches(text)) {
        final title = match.group(1)!;
        final name = match.group(2)!;
        final fullName = '$title $name';
        if (seen.add(fullName.toLowerCase())) {
          results.add(
            AiIndexEntity(
              id: fullName,
              name: fullName,
              type: AiIndexEntityType.character,
              categoryKey: 'characters',
              characterRole: CharacterRole.supporting,
              summary: 'Discovered in ${ch.title} bearing title of $title.',
              sourceChapterTitle: ch.title,
              sourceChapterId: ch.id,
            ),
          );
        }
      }

      // 2. Location patterns
      final locRegex = RegExp(
        r'\b(Kingdom|Empire|Realm|City|Port|Mount|Castle|Fortress|Tower|Valley|Forest|Sea|River)\s+(?:of\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
      );
      for (final match in locRegex.allMatches(text)) {
        final fullLoc = match.group(0)!;
        if (seen.add(fullLoc.toLowerCase())) {
          results.add(
            AiIndexEntity(
              id: fullLoc,
              name: fullLoc,
              type: AiIndexEntityType.location,
              categoryKey: 'locations',
              summary: 'Geographic entity referenced in ${ch.title}.',
              sourceChapterTitle: ch.title,
              sourceChapterId: ch.id,
            ),
          );
        }
      }

      // 3. Organization & Faction patterns
      final orgRegex = RegExp(
        r'\b(Order|Guild|Brotherhood|Clan|House|Company|Legion|Alliance|Syndicate|Coven)\s+(?:of\s+)?(?:the\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
      );
      for (final match in orgRegex.allMatches(text)) {
        final fullOrg = match.group(0)!;
        if (seen.add(fullOrg.toLowerCase())) {
          final isFaction = fullOrg.toLowerCase().contains('clan') ||
              fullOrg.toLowerCase().contains('legion') ||
              fullOrg.toLowerCase().contains('alliance');
          results.add(
            AiIndexEntity(
              id: fullOrg,
              name: fullOrg,
              type: isFaction
                  ? AiIndexEntityType.faction
                  : AiIndexEntityType.organization,
              categoryKey: isFaction ? 'factions' : 'organizations',
              summary: 'Group entity referenced in ${ch.title}.',
              sourceChapterTitle: ch.title,
              sourceChapterId: ch.id,
            ),
          );
        }
      }

      // 4. Religion & Deity patterns
      final relRegex = RegExp(
        r'\b(Church|Temple|Cult|Faith|Pantheon|Shrine)\s+(?:of\s+)?(?:the\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
      );
      for (final match in relRegex.allMatches(text)) {
        final fullRel = match.group(0)!;
        if (seen.add(fullRel.toLowerCase())) {
          results.add(
            AiIndexEntity(
              id: fullRel,
              name: fullRel,
              type: AiIndexEntityType.religion,
              categoryKey: 'religions',
              summary:
                  'Religious or theological entity referenced in ${ch.title}.',
              sourceChapterTitle: ch.title,
              sourceChapterId: ch.id,
            ),
          );
        }
      }
    }

    return results;
  }
}
