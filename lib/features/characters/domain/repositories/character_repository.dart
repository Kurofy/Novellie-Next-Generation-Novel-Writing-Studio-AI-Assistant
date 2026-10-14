import '../models/character_model.dart';

abstract class CharacterRepository {
  Stream<List<CharacterModel>> watchCharacters(String novelId);
  Stream<CharacterModel?> watchCharacter(String characterId);
  Future<CharacterModel?> getCharacter(String characterId);
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
  });
  Future<void> updateCharacter(CharacterModel character);
  Future<void> deleteCharacter(String characterId);

  Stream<List<CharacterRelationshipModel>> watchCharacterRelationships(
    String characterId,
  );
  Future<CharacterRelationshipModel> addRelationship({
    required String novelId,
    required String characterAId,
    required String characterBId,
    required String type,
    String? customLabel,
    String? description,
  });
  Future<void> deleteRelationship(String relationshipId);
}
