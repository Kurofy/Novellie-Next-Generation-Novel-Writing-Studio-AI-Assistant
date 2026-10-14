import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/ai/data/services/ai_client_service.dart';
import 'package:novellie/features/ai/data/services/ai_index_service.dart';
import 'package:novellie/features/ai/domain/models/ai_index_models.dart';
import 'package:novellie/features/ai/domain/models/ai_models.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';

class _FakeAiClientService extends Fake implements AiClientService {
  final String? response;
  _FakeAiClientService({this.response});

  @override
  Future<String> sendMessage({
    required AiConfigModel config,
    required String prompt,
    String? novelContext,
  }) async {
    if (response != null) return response!;
    throw Exception('Simulated network failure');
  }
}

void main() {
  group('AiIndexService', () {
    test('extracts structured entities from JSON response', () async {
      const mockJson = '''
```json
[
  {
    "name": "Eldrin Vale",
    "type": "character",
    "role": "protagonist",
    "summary": "A rebel spellsword who fled the imperial capital."
  },
  {
    "name": "Sunspire Citadel",
    "type": "location",
    "categoryKey": "cities",
    "summary": "An ancient fortress perched upon the crystal cliff."
  },
  {
    "name": "Iron Brotherhood",
    "type": "organization",
    "categoryKey": "organizations",
    "summary": "A mercenary company guarding the northern border."
  },
  {
    "name": "Obsidian Rebellion",
    "type": "faction",
    "categoryKey": "factions",
    "summary": "Insurgents fighting against the divine emperor."
  },
  {
    "name": "Order of the Eclipse",
    "type": "religion",
    "categoryKey": "religions",
    "summary": "A secretive cult worshipping the dark moon."
  }
]
```
''';

      final service = AiIndexService(_FakeAiClientService(response: mockJson));
      final chapters = [
        (
          id: 'ch-1',
          title: 'Chapter 1: The Gathering',
          plainText: 'Eldrin Vale walked towards the Sunspire Citadel.',
        ),
      ];

      final results = await service.scanManuscript(
        config: const AiConfigModel(apiKey: 'fake-key'),
        novelId: 'novel-1',
        chapters: chapters,
        existingCharacters: [],
        existingWorldEntries: [],
      );

      expect(results.length, 5);
      expect(results[0].name, 'Eldrin Vale');
      expect(results[0].type, AiIndexEntityType.character);
      expect(results[0].characterRole, CharacterRole.protagonist);
      expect(results[0].isAlreadyInIndex, false);
      expect(results[0].isSelected, true);

      expect(results[1].name, 'Sunspire Citadel');
      expect(results[1].type, AiIndexEntityType.location);

      expect(results[2].name, 'Iron Brotherhood');
      expect(results[2].type, AiIndexEntityType.organization);

      expect(results[3].name, 'Obsidian Rebellion');
      expect(results[3].type, AiIndexEntityType.faction);

      expect(results[4].name, 'Order of the Eclipse');
      expect(results[4].type, AiIndexEntityType.religion);
    });

    test('correctly cross-references existing entities in index', () async {
      const mockJson = '''
[
  {
    "name": "Eldrin Vale",
    "type": "character",
    "role": "protagonist",
    "summary": "A rebel spellsword."
  },
  {
    "name": "Sunspire Citadel",
    "type": "location",
    "summary": "An ancient fortress."
  }
]
''';

      final service = AiIndexService(_FakeAiClientService(response: mockJson));
      final existingChar = CharacterModel(
        id: 'char-1',
        novelId: 'novel-1',
        name: 'Eldrin Vale',
        role: CharacterRole.protagonist,
        moralAlignment: 'Neutral Good',
        status: 'Active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final results = await service.scanManuscript(
        config: const AiConfigModel(apiKey: 'fake-key'),
        novelId: 'novel-1',
        chapters: [(id: 'ch-1', title: 'Chapter 1', plainText: 'Some prose.')],
        existingCharacters: [existingChar],
        existingWorldEntries: [],
      );

      final eldrin = results.firstWhere((e) => e.name == 'Eldrin Vale');
      final sunspire = results.firstWhere((e) => e.name == 'Sunspire Citadel');

      expect(eldrin.isAlreadyInIndex, true);
      expect(eldrin.isSelected, false); // Already cataloged, don't auto-select

      expect(sunspire.isAlreadyInIndex, false);
      expect(sunspire.isSelected, true);
    });

    test('falls back to heuristic scanner on offline or unconfigured AI', () async {
      final service = AiIndexService(_FakeAiClientService());
      final chapters = [
        (
          id: 'ch-1',
          title: 'Chapter 1',
          plainText: '''
            Lord Brandon arrived at the Kingdom of Valoria.
            There he met with the Brotherhood of Iron and prayed at the Temple of the Dawn.
          ''',
        ),
      ];

      final results = await service.scanManuscript(
        config: const AiConfigModel(), // Unconfigured
        novelId: 'novel-1',
        chapters: chapters,
        existingCharacters: [],
        existingWorldEntries: [],
      );

      expect(results.any((e) => e.name == 'Lord Brandon'), true);
      expect(results.any((e) => e.name.contains('Valoria')), true);
      expect(results.any((e) => e.name.contains('Brotherhood of Iron')), true);
      expect(results.any((e) => e.name.contains('Temple of the Dawn')), true);
    });
  });
}
