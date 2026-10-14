import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/character_model.dart';
import '../../domain/repositories/character_repository.dart';

class DriftCharacterRepository implements CharacterRepository {
  final AppDatabase _db;

  DriftCharacterRepository(this._db);

  CharacterModel _toDomain(Character row) {
    String? race;
    if (row.notes != null && row.notes!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(row.notes!);
        if (decoded is Map<String, dynamic>) {
          race = decoded['race'] as String?;
        }
      } catch (_) {}
    }

    try {
      return CharacterModel(
        id: row.id,
        novelId: row.novelId,
        name: row.name,
        nickname: row.nickname,
        ageText: row.ageText,
        gender: row.gender,
        race: race,
        pronouns: row.pronouns,
        role: CharacterRole.fromString(row.role),
        moralAlignment: row.moralAlignment,
        status: row.status,
        appearance: row.appearance,
        personality: row.personality,
        motivation: row.motivation,
        goal: row.goal,
        fear: row.fear,
        secret: row.secret,
        flaw: row.flaw,
        strengths: row.strengths,
        weaknesses: row.weaknesses,
        backstory: row.backstory,
        arcType: row.arcType,
        arcSummary: row.arcSummary,
        portraitPath: row.portraitPath,
        notes: row.notes,
        createdAt: row.createdAt > 0
            ? DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true)
            : DateTime.now().toUtc(),
        updatedAt: row.updatedAt > 0
            ? DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true)
            : DateTime.now().toUtc(),
      );
    } catch (_) {
      return CharacterModel(
        id: row.id,
        novelId: row.novelId,
        name: row.name.isNotEmpty ? row.name : 'Character',
        gender: row.gender,
        race: race,
        role: CharacterRole.supporting,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Stream<List<CharacterModel>> watchCharacters(String novelId) {
    final query = _db.select(_db.characters)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch().map((rows) {
      final list = <CharacterModel>[];
      for (final r in rows) {
        try {
          list.add(_toDomain(r));
        } catch (_) {
          list.add(
            CharacterModel(
              id: r.id,
              novelId: r.novelId,
              name: r.name,
              gender: r.gender,
              role: CharacterRole.supporting,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        }
      }
      return list;
    });
  }

  @override
  Stream<CharacterModel?> watchCharacter(String characterId) {
    final query = _db.select(_db.characters)
      ..where((tbl) => tbl.id.equals(characterId) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      try {
        return _toDomain(row);
      } catch (_) {
        return CharacterModel(
          id: row.id,
          novelId: row.novelId,
          name: row.name,
          gender: row.gender,
          role: CharacterRole.supporting,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
      }
    });
  }

  @override
  Future<CharacterModel?> getCharacter(String characterId) async {
    final query = _db.select(_db.characters)
      ..where((tbl) => tbl.id.equals(characterId) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
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
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();

    String? notesJson = notes;
    if (race != null && race.trim().isNotEmpty) {
      Map<String, dynamic> map = {};
      if (notesJson != null && notesJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(notesJson);
          if (decoded is Map<String, dynamic>) map = decoded;
        } catch (_) {
          map['summary'] = notesJson;
        }
      }
      map['race'] = race.trim();
      notesJson = jsonEncode(map);
    }

    await _db.into(_db.characters).insert(
          CharactersCompanion(
            id: Value(id),
            novelId: Value(novelId),
            name: Value(name.trim()),
            nickname: Value(nickname?.trim()),
            role: Value(role.name),
            ageText: Value(ageText?.trim()),
            gender: Value(gender?.trim()),
            appearance: Value(appearance?.trim()),
            goal: Value(goal?.trim()),
            flaw: Value(flaw?.trim()),
            fear: Value(fear?.trim()),
            secret: Value(secret?.trim()),
            backstory: Value(backstory?.trim()),
            portraitPath: Value(portraitPath?.trim()),
            notes: Value(notesJson),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final created = await getCharacter(id);
    return created!;
  }

  @override
  Future<void> updateCharacter(CharacterModel character) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    String? notesJson = character.notes;
    if (character.race != null && character.race!.trim().isNotEmpty) {
      Map<String, dynamic> map = {};
      if (notesJson != null && notesJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(notesJson);
          if (decoded is Map<String, dynamic>) map = decoded;
        } catch (_) {
          map['summary'] = notesJson;
        }
      }
      map['race'] = character.race!.trim();
      notesJson = jsonEncode(map);
    }

    await (_db.update(_db.characters)..where((tbl) => tbl.id.equals(character.id)))
        .write(
      CharactersCompanion(
        name: Value(character.name),
        nickname: Value(character.nickname),
        role: Value(character.role.name),
        ageText: Value(character.ageText),
        gender: Value(character.gender),
        pronouns: Value(character.pronouns),
        status: Value(character.status),
        appearance: Value(character.appearance),
        personality: Value(character.personality),
        motivation: Value(character.motivation),
        goal: Value(character.goal),
        fear: Value(character.fear),
        secret: Value(character.secret),
        flaw: Value(character.flaw),
        strengths: Value(character.strengths),
        weaknesses: Value(character.weaknesses),
        backstory: Value(character.backstory),
        arcType: Value(character.arcType),
        arcSummary: Value(character.arcSummary),
        portraitPath: Value(character.portraitPath),
        notes: Value(notesJson),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteCharacter(String characterId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.characters)..where((tbl) => tbl.id.equals(characterId)))
        .write(
      CharactersCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Stream<List<CharacterRelationshipModel>> watchCharacterRelationships(
    String characterId,
  ) {
    final query = _db.select(_db.characterRelationships)
      ..where(
        (tbl) =>
            (tbl.characterAId.equals(characterId) |
                tbl.characterBId.equals(characterId)) &
            tbl.deletedAt.isNull(),
      )
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    return query.watch().asyncMap((rows) async {
      final list = <CharacterRelationshipModel>[];
      for (final r in rows) {
        final targetId =
            r.characterAId == characterId ? r.characterBId : r.characterAId;
        final targetChar = await getCharacter(targetId);
        list.add(
          CharacterRelationshipModel(
            id: r.id,
            novelId: r.novelId,
            characterAId: r.characterAId,
            characterBId: r.characterBId,
            targetCharacterName: targetChar?.name ?? 'Unknown Character',
            targetCharacterPortrait: targetChar?.portraitPath,
            targetCharacterGender: targetChar?.gender,
            type: r.type,
            customLabel: r.customLabel,
            description: r.description,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        );
      }
      return list;
    });
  }

  @override
  Future<CharacterRelationshipModel> addRelationship({
    required String novelId,
    required String characterAId,
    required String characterBId,
    required String type,
    String? customLabel,
    String? description,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();

    await _db.into(_db.characterRelationships).insert(
          CharacterRelationshipsCompanion(
            id: Value(id),
            novelId: Value(novelId),
            characterAId: Value(characterAId),
            characterBId: Value(characterBId),
            type: Value(type),
            customLabel: Value(customLabel),
            description: Value(description),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final targetChar = await getCharacter(characterBId);
    return CharacterRelationshipModel(
      id: id,
      novelId: novelId,
      characterAId: characterAId,
      characterBId: characterBId,
      targetCharacterName: targetChar?.name,
      targetCharacterPortrait: targetChar?.portraitPath,
      targetCharacterGender: targetChar?.gender,
      type: type,
      customLabel: customLabel,
      description: description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
    );
  }

  @override
  Future<void> deleteRelationship(String relationshipId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.characterRelationships)
          ..where((tbl) => tbl.id.equals(relationshipId)))
        .write(
      CharacterRelationshipsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
