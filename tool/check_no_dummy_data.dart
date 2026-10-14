import 'dart:io';

const bannedPatterns = <String>[
  "The Statesman's Machination",
  'The Silent Threshold',
  'Fragha',
  'Zael',
  'Kaela',
  'Cedric',
  'Julian',
  'Evelyn Ward',
  'Elena Vance',
  'Lord Vane',
  'House Vane',
  'House Malakar',
  'High Hold',
  'Oakhaven',
  'Obsidian Sigil',
  'Silver Crest',
  'Whispering Gallery',
  'Lorem ipsum',
  'lorem ipsum',
  'John Doe',
  'jane.doe@',
];

void main() {
  final directories = [Directory('lib'), Directory('assets')];
  var violations = 0;

  for (final dir in directories) {
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      // Skip binary files
      if (entity.path.endsWith('.png') ||
          entity.path.endsWith('.ttf') ||
          entity.path.endsWith('.ico') ||
          entity.path.endsWith('.jpg')) {
        continue;
      }

      final content = entity.readAsStringSync();
      for (final pattern in bannedPatterns) {
        if (content.contains(pattern)) {
          stderr.writeln(
            'ERROR: Dummy/placeholder data "$pattern" found in ${entity.path}',
          );
          violations++;
        }
      }
    }
  }

  if (violations > 0) {
    stderr.writeln(
      'check_no_dummy_data: $violations violation(s) found. Build failed.',
    );
    exit(1);
  } else {
    stdout.writeln('check_no_dummy_data: Passed. Zero dummy data detected.');
  }
}
