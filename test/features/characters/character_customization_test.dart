import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';
import 'package:novellie/features/characters/presentation/screens/character_detail_screen.dart';

void main() {
  group('Customizable Psychological Core & Avatar', () {
    test('PsychologicalData parses and serializes summary and dynamic traits', () {
      // 1. Initial raw notes with summary and traits
      final jsonNotes = jsonEncode({
        'summary': 'A deeply conflicted anti-hero driven by past trauma.',
        'traits': [
          {
            'id': 'trait-1',
            'name': 'Moral Ambiguity',
            'description': 'Willing to compromise ethical rules to protect family.',
          },
          {
            'id': 'trait-2',
            'name': 'Tragic Tell',
            'description': 'Taps his ring whenever remembering the incident.',
          },
        ],
      });

      final parsed = PsychologicalData.fromRawNotes(jsonNotes);
      expect(parsed.summary, equals('A deeply conflicted anti-hero driven by past trauma.'));
      expect(parsed.traits.length, equals(2));
      expect(parsed.traits[0].name, equals('Moral Ambiguity'));
      expect(parsed.traits[1].name, equals('Tragic Tell'));

      // 2. Dynamically add a new trait
      final updatedTraits = [
        ...parsed.traits,
        const PsychologicalTrait(
          id: 'trait-3',
          name: 'Hyper-vigilance',
          description: 'Never sits with his back to the door.',
        ),
      ];
      final withAddedTrait = parsed.copyWith(traits: updatedTraits);
      expect(withAddedTrait.traits.length, equals(3));
      expect(withAddedTrait.traits[2].name, equals('Hyper-vigilance'));

      // 3. Dynamically edit an existing trait
      final editedTraits = withAddedTrait.traits.map((t) {
        if (t.id == 'trait-1') {
          return const PsychologicalTrait(
            id: 'trait-1',
            name: 'Strict Moral Code',
            description: 'Refuses to let innocents be harmed.',
          );
        }
        return t;
      }).toList();
      final withEditedTrait = withAddedTrait.copyWith(traits: editedTraits);
      expect(withEditedTrait.traits[0].name, equals('Strict Moral Code'));

      // 4. Dynamically remove a trait
      final withoutTrait = withEditedTrait.copyWith(
        traits: withEditedTrait.traits.where((t) => t.id != 'trait-2').toList(),
      );
      expect(withoutTrait.traits.length, equals(2));
      expect(withoutTrait.traits.any((t) => t.id == 'trait-2'), isFalse);

      // 5. Update summary
      final withNewSummary = withoutTrait.copyWith(
        summary: 'Redeemed protector finding a new purpose.',
      );
      expect(withNewSummary.summary, equals('Redeemed protector finding a new purpose.'));

      // 6. Roundtrip JSON serialization
      final serializedJson = withNewSummary.toJsonString();
      final roundtrip = PsychologicalData.fromRawNotes(serializedJson);
      expect(roundtrip.summary, equals('Redeemed protector finding a new purpose.'));
      expect(roundtrip.traits.length, equals(2));
    });

    test('PsychologicalData handles legacy unstructured text notes safely', () {
      const legacyNote = 'Met in chapter 3 outside the bakery.';
      final data = PsychologicalData.fromRawNotes(legacyNote);

      expect(data.summary, equals(legacyNote));
      expect(data.traits, isEmpty);
    });

    test('CharacterModel supports portraitPath and copyWith operations', () {
      final now = DateTime.now().toUtc();
      final character = CharacterModel(
        id: 'char-100',
        novelId: 'novel-1',
        name: 'Elena Rostova',
        nickname: 'The Ghost',
        role: CharacterRole.protagonist,
        portraitPath: '/data/portraits/elena.png',
        createdAt: now,
        updatedAt: now,
      );

      expect(character.portraitPath, equals('/data/portraits/elena.png'));
      expect(character.displayName, equals('Elena Rostova "The Ghost"'));

      // Update portrait via copyWith
      final updated = character.copyWith(
        portraitPath: 'https://images.example.com/elena_hq.jpg',
      );
      expect(updated.portraitPath, equals('https://images.example.com/elena_hq.jpg'));
      expect(updated.name, equals('Elena Rostova'));
    });

    test('CharacterGender parses standard and Indonesian gender strings accurately', () {
      expect(CharacterGender.fromString('male'), equals(CharacterGender.male));
      expect(CharacterGender.fromString('laki-laki'), equals(CharacterGender.male));
      expect(CharacterGender.fromString('pria'), equals(CharacterGender.male));
      expect(CharacterGender.fromString('m'), equals(CharacterGender.male));

      expect(CharacterGender.fromString('female'), equals(CharacterGender.female));
      expect(CharacterGender.fromString('perempuan'), equals(CharacterGender.female));
      expect(CharacterGender.fromString('wanita'), equals(CharacterGender.female));
      expect(CharacterGender.fromString('f'), equals(CharacterGender.female));

      expect(CharacterGender.fromString('custom'), equals(CharacterGender.custom));
      expect(CharacterGender.fromString('non-binary'), equals(CharacterGender.custom));
      expect(CharacterGender.fromString(null), equals(CharacterGender.custom));
    });

    test('CharacterRacePreset contains standard fantasy presets', () {
      expect(CharacterRacePreset.presets, containsAll([
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
      ]),);
    });

    test('CharacterModel parses and stores race in notes metadata', () {
      final now = DateTime.now().toUtc();
      final elfChar = CharacterModel(
        id: 'char-elf',
        novelId: 'novel-1',
        name: 'Legolas',
        gender: 'male',
        race: 'Elf',
        notes: jsonEncode({'race': 'Elf', 'summary': 'Master archer.'}),
        createdAt: now,
        updatedAt: now,
      );

      expect(elfChar.race, equals('Elf'));
      expect(elfChar.genderCategory, equals(CharacterGender.male));
    });
  });
}
