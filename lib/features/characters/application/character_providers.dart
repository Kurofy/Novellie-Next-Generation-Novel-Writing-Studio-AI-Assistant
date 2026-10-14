import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/drift_character_repository.dart';
import '../domain/models/character_model.dart';
import '../domain/repositories/character_repository.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCharacterRepository(db);
});

final charactersStreamProvider =
    StreamProvider.family<List<CharacterModel>, String>((ref, novelId) {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.watchCharacters(novelId);
});

final characterDetailStreamProvider =
    StreamProvider.family<CharacterModel?, String>((ref, characterId) {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.watchCharacter(characterId);
});

final characterRelationshipsStreamProvider =
    StreamProvider.family<List<CharacterRelationshipModel>, String>(
        (ref, characterId) {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.watchCharacterRelationships(characterId);
});

class CharacterActionsController {
  final CharacterRepository _repo;

  CharacterActionsController(this._repo);

  Future<CharacterModel> createCharacter({
    required String novelId,
    required String name,
    String? nickname,
    CharacterRole role = CharacterRole.supporting,
    String? ageText,
    String? gender,
    String? race,
    String? appearance,
    String? goal,
    String? flaw,
    String? fear,
    String? secret,
    String? backstory,
    String? portraitPath,
    String? notes,
  }) {
    return _repo.createCharacter(
      novelId: novelId,
      name: name,
      nickname: nickname,
      role: role,
      ageText: ageText,
      gender: gender,
      race: race,
      appearance: appearance,
      goal: goal,
      flaw: flaw,
      fear: fear,
      secret: secret,
      backstory: backstory,
      portraitPath: portraitPath,
      notes: notes,
    );
  }

  Future<void> updateCharacter(CharacterModel character) {
    return _repo.updateCharacter(character);
  }

  Future<void> deleteCharacter(String characterId) {
    return _repo.deleteCharacter(characterId);
  }

  Future<CharacterRelationshipModel> addRelationship({
    required String novelId,
    required String characterAId,
    required String characterBId,
    required String type,
    String? customLabel,
    String? description,
  }) {
    return _repo.addRelationship(
      novelId: novelId,
      characterAId: characterAId,
      characterBId: characterBId,
      type: type,
      customLabel: customLabel,
      description: description,
    );
  }

  Future<void> deleteRelationship(String relationshipId) {
    return _repo.deleteRelationship(relationshipId);
  }
}

final characterActionsControllerProvider =
    Provider<CharacterActionsController>((ref) {
  final repo = ref.watch(characterRepositoryProvider);
  return CharacterActionsController(repo);
});
