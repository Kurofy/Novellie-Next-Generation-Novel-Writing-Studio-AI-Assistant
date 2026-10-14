import 'dart:io';

final prohibitedTokenPatterns = <RegExp>[
  RegExp(r'\bColors\.(?!(transparent)\b)[a-zA-Z]+'),
  RegExp(r'\bColor\(0x[0-9a-fA-F]+\)'),
  RegExp(r'\bColor\.(fromRGBO|fromARGB)\('),
  RegExp(r'\bTextStyle\([^)]*(fontSize|fontFamily|fontWeight):'),
  RegExp(r'\bBorderRadius\.circular\(\d+\)'),
  RegExp(r'\bIcons\.[a-zA-Z_]+'),
];

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stdout.writeln('No lib directory found.');
    return;
  }

  var violations = 0;
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    // Allowed in lib/core/theme/
    final normalizedPath = entity.path.replaceAll(r'\', '/');
    if (normalizedPath.contains('lib/core/theme/')) {
      continue;
    }
    // Generated files are excluded
    if (normalizedPath.endsWith('.g.dart') ||
        normalizedPath.endsWith('.freezed.dart')) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//')) continue;

      for (final pattern in prohibitedTokenPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          stderr.writeln(
            'ERROR: Prohibited design token usage "${match.group(0)}" at ${entity.path}:${i + 1}',
          );
          violations++;
        }
      }

      // Check BoxShadow outside app_shadows.dart
      if (!normalizedPath.endsWith('app_shadows.dart') &&
          line.contains('BoxShadow(')) {
        stderr.writeln(
          'ERROR: BoxShadow usage outside app_shadows.dart at ${entity.path}:${i + 1}',
        );
        violations++;
      }
    }
  }

  if (violations > 0) {
    stderr.writeln(
      'check_design_tokens: $violations violation(s) found. Build failed.',
    );
    exit(1);
  } else {
    stdout.writeln('check_design_tokens: Passed. All tokens compliant.');
  }
}
