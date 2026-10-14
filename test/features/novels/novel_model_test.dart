import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/shared/utils/word_counter.dart';

void main() {
  group('NovelModel and WordCounter', () {
    test('NovelStatus parsing handles valid and fallback values', () {
      expect(NovelStatus.fromString('drafting'), NovelStatus.drafting);
      expect(NovelStatus.fromString('on_hold'), NovelStatus.onHold);
      expect(NovelStatus.fromString('invalid_status'), NovelStatus.idea);
      expect(NovelStatus.fromString(null), NovelStatus.idea);
    });

    test('WordCounter accurately counts English words and characters', () {
      const text = 'The silver starship drifted through the nebula.';
      final result = countWordsAndCharacters(text);

      expect(result.words, 7);
      expect(result.characters, text.length);
    });

    test('WordCounter handles empty and whitespace text', () {
      final resultEmpty = countWordsAndCharacters('');
      expect(resultEmpty.words, 0);
      expect(resultEmpty.characters, 0);

      final resultWhitespace = countWordsAndCharacters('   \n\t  ');
      expect(resultWhitespace.words, 0);
      expect(resultWhitespace.charactersNoSpaces, 0);
    });

    test('WordCounter counts CJK characters accurately', () {
      const text = '你好世界'; // 4 characters
      final result = countWordsAndCharacters(text);
      expect(result.words, 4);
    });

    test('WordCounter counts sentences, paragraphs and characters with/without spaces', () {
      const multiParagraph = 'First paragraph here. It has two sentences!\n\nSecond paragraph here? Indeed it is.\n\nThird paragraph alone.';
      final result = countWordsAndCharacters(multiParagraph);

      expect(result.paragraphs, 3);
      expect(result.sentences, 5);
      expect(result.words, 16);
      expect(result.charactersNoSpaces, multiParagraph.replaceAll(RegExp(r'\s+'), '').length);
    });
  });
}
