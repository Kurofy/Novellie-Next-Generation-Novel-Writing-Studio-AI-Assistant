class WordCountResult {
  final int words;
  final int characters;
  final int charactersNoSpaces;
  final int sentences;
  final int paragraphs;
  final int readingTimeMinutes;

  const WordCountResult({
    required this.words,
    required this.characters,
    required this.charactersNoSpaces,
    this.sentences = 0,
    this.paragraphs = 0,
    required this.readingTimeMinutes,
  });

  static const zero = WordCountResult(
    words: 0,
    characters: 0,
    charactersNoSpaces: 0,
    sentences: 0,
    paragraphs: 0,
    readingTimeMinutes: 0,
  );
}

int countSentences(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final segments = trimmed.split(RegExp(r'[.!?…]+(?:\s+|$)'));
  return segments.where((s) => s.trim().isNotEmpty).length;
}

int countParagraphs(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final paras = trimmed.split(RegExp(r'\n+'));
  return paras.where((p) => p.trim().isNotEmpty).length;
}

WordCountResult countWordsAndCharacters(String text) {
  if (text.isEmpty) {
    return WordCountResult.zero;
  }

  final characters = text.length;
  final charactersNoSpaces = text.replaceAll(RegExp(r'\s'), '').length;

  int wordCount = 0;

  // Regex matching CJK characters (Chinese, Japanese Kanji/Kana, Korean Hangul)
  final cjkRegex = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]',
  );

  // Remove CJK characters from the text while counting them as individual words
  final nonCjkText = text.replaceAllMapped(cjkRegex, (match) {
    wordCount++;
    return ' ';
  });

  // Count Latin/alphanumeric words separated by whitespace
  final words = nonCjkText.trim().split(RegExp(r'\s+'));
  for (final word in words) {
    if (word.isNotEmpty && RegExp(r'\w').hasMatch(word)) {
      wordCount++;
    }
  }

  final sentences = countSentences(text);
  final paragraphs = countParagraphs(text);

  // Reading time at average 225 words per minute
  final readingMinutes = (wordCount / 225).ceil();

  return WordCountResult(
    words: wordCount,
    characters: characters,
    charactersNoSpaces: charactersNoSpaces,
    sentences: sentences,
    paragraphs: paragraphs,
    readingTimeMinutes: readingMinutes,
  );
}

int countWords(String text) => countWordsAndCharacters(text).words;
