import 'dart:convert';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../characters/domain/models/character_model.dart';
import '../../../outline/domain/models/planning_models.dart';
import '../../../world/domain/models/world_models.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/consistency_models.dart';
import 'ai_client_service.dart';

class ConsistencyCheckerService {
  final AiClientService _aiClient;

  ConsistencyCheckerService(this._aiClient);

  Future<ConsistencyReport> analyze({
    required AiConfigModel config,
    required String novelId,
    required List<({String id, String title, String plainText})> chapters,
    required List<CharacterModel> characters,
    required List<WorldEntryModel> worldEntries,
    required List<TimelineEventModel> timelineEvents,
  }) async {
    if (chapters.isEmpty) {
      return ConsistencyReport(
        novelId: novelId,
        consistencyScore: 100.0,
        inconsistencyScore: 0.0,
        totalIssues: 0,
        analyzedChapterCount: 0,
        issues: const [],
        summary: 'No chapter texts provided for consistency analysis.',
        analyzedAt: DateTime.now().toUtc(),
      );
    }

    if (config.isConfigured) {
      try {
        return await _runAiAnalysis(
          config: config,
          novelId: novelId,
          chapters: chapters,
          characters: characters,
          worldEntries: worldEntries,
          timelineEvents: timelineEvents,
        );
      } catch (_) {
        // Fallback to heuristic analysis on AI failure or network issue
        return _runHeuristicAnalysis(
          novelId: novelId,
          chapters: chapters,
          characters: characters,
          worldEntries: worldEntries,
          timelineEvents: timelineEvents,
        );
      }
    } else {
      return _runHeuristicAnalysis(
        novelId: novelId,
        chapters: chapters,
        characters: characters,
        worldEntries: worldEntries,
        timelineEvents: timelineEvents,
      );
    }
  }

  Future<ConsistencyReport> _runAiAnalysis({
    required AiConfigModel config,
    required String novelId,
    required List<({String id, String title, String plainText})> chapters,
    required List<CharacterModel> characters,
    required List<WorldEntryModel> worldEntries,
    required List<TimelineEventModel> timelineEvents,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Analyze the following novel content for narrative continuity errors, contradictions, lore violations, timeline paradoxes, and character trait drift.\n',
    );

    buffer.writeln('=== LORE & CHARACTERS ===');
    for (final char in characters) {
      buffer.writeln(
        '- Character: ${char.name} (Role: ${char.role.label}${char.appearance != null ? ", Appearance: ${char.appearance}" : ""}${char.backstory != null ? ", Backstory: ${char.backstory}" : ""})',
      );
    }
    for (final w in worldEntries) {
      buffer.writeln(
        '- World Entry: ${w.name}${w.subtitle != null ? " (${w.subtitle})" : ""}: ${w.summary ?? ""}',
      );
    }
    for (final ev in timelineEvents) {
      buffer.writeln(
        '- Timeline Event: ${ev.title} (${ev.dateText ?? "Unspecified timing"})',
      );
    }

    buffer.writeln('\n=== CHAPTERS ===');
    for (final ch in chapters) {
      final textPreview = ch.plainText.length > 2500
          ? '${ch.plainText.substring(0, 2500)}... [truncated]'
          : ch.plainText;
      buffer.writeln('--- Chapter: ${ch.title} ---');
      buffer.writeln(textPreview);
      buffer.writeln('');
    }

    const prompt = '''
You are an expert novel continuity editor. Analyze the chapters against each other and against the established lore/characters/timeline.
Return ONLY a valid JSON object matching this exact schema:
{
  "consistencyScore": 88,
  "summary": "Brief executive summary of findings",
  "issues": [
    {
      "title": "Short issue headline",
      "category": "character" | "timeline" | "location" | "lore" | "continuity",
      "severity": "high" | "medium" | "low",
      "chapterTitle": "Chapter title where error occurs",
      "citedExcerpt": "Exact or cited quote showing the contradiction",
      "issueBreakdown": "Clear explanation of why this contradicts prior text or lore",
      "suggestedCorrection": "Actionable revision advice"
    }
  ]
}
Do not include markdown code fence formatting or other wrapper text. Return only the raw JSON.
''';

    final response = await _aiClient.sendMessage(
      config: config,
      prompt: prompt,
      novelContext: buffer.toString(),
    );

    // Extract JSON from response
    final rawJson = response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    final score = (data['consistencyScore'] as num?)?.toDouble() ?? 85.0;
    final issuesRaw = data['issues'] as List<dynamic>? ?? [];

    final issues = issuesRaw.map((item) {
      final map = item as Map<String, dynamic>;
      return ConsistencyIssue(
        id: generateUuid(),
        title: map['title'] as String? ?? 'Continuity Discrepancy',
        category: ConsistencyCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == (map['category'] as String?)?.toLowerCase(),
          orElse: () => ConsistencyCategory.continuity,
        ),
        severity: ConsistencySeverity.values.firstWhere(
          (s) => s.name.toLowerCase() == (map['severity'] as String?)?.toLowerCase(),
          orElse: () => ConsistencySeverity.medium,
        ),
        chapterTitle: map['chapterTitle'] as String? ?? (chapters.isNotEmpty ? chapters.first.title : 'Chapter'),
        citedExcerpt: map['citedExcerpt'] as String? ?? '',
        issueBreakdown: map['issueBreakdown'] as String? ?? '',
        suggestedCorrection: map['suggestedCorrection'] as String? ?? '',
      );
    }).toList();

    return ConsistencyReport(
      novelId: novelId,
      consistencyScore: score.clamp(0.0, 100.0),
      inconsistencyScore: (100.0 - score).clamp(0.0, 100.0),
      totalIssues: issues.length,
      analyzedChapterCount: chapters.length,
      issues: issues,
      summary: data['summary'] as String? ??
          'Analyzed ${chapters.length} chapters against established lore.',
      analyzedAt: DateTime.now().toUtc(),
    );
  }

  ConsistencyReport _runHeuristicAnalysis({
    required String novelId,
    required List<({String id, String title, String plainText})> chapters,
    required List<CharacterModel> characters,
    required List<WorldEntryModel> worldEntries,
    required List<TimelineEventModel> timelineEvents,
  }) {
    final issues = <ConsistencyIssue>[];

    // Heuristic 1: Check for character mention frequency & spelling variations
    for (final char in characters) {
      final occurrences = <String>[];
      for (final ch in chapters) {
        if (ch.plainText.toLowerCase().contains(char.name.toLowerCase())) {
          occurrences.add(ch.title);
        }
      }

      // If character has an appearance specified, verify consistency hints
      if (char.appearance != null && char.appearance!.isNotEmpty && occurrences.length >= 2) {
        final text = chapters.map((c) => c.plainText).join(' ');
        // Check for common color/feature shifts like eye color or hair
        if (char.appearance!.toLowerCase().contains('blue eye') &&
            text.toLowerCase().contains('brown eye')) {
          issues.add(
            ConsistencyIssue(
              id: generateUuid(),
              title: '${char.name}: Eye Color Discrepancy',
              category: ConsistencyCategory.character,
              severity: ConsistencySeverity.medium,
              chapterTitle: occurrences.last,
              citedExcerpt:
                  'Character lore establishes "${char.name}" with "${char.appearance}", but later scene mentions "brown eyes".',
              issueBreakdown:
                  'Physical appearance description diverges from canon profile established in the project Index.',
              suggestedCorrection:
                  'Standardize references to match canonical description: "${char.appearance}".',
            ),
          );
        }
      }
    }

    // Heuristic 2: Check for World Entry references
    for (final entry in worldEntries) {
      int foundCount = 0;
      for (final ch in chapters) {
        if (ch.plainText.toLowerCase().contains(entry.name.toLowerCase())) {
          foundCount++;
        }
      }
      if (foundCount == 0 && chapters.length >= 3) {
        issues.add(
          ConsistencyIssue(
            id: generateUuid(),
            title: 'Unreferenced Key Lore: "${entry.name}"',
            category: ConsistencyCategory.lore,
            severity: ConsistencySeverity.low,
            chapterTitle: chapters.first.title,
            citedExcerpt:
                'Encyclopedia entry "${entry.name}" is marked canon but not referenced in the analyzed scope.',
            issueBreakdown:
                'Key worldbuilding details exist in your Index but have not appeared in chapter manuscripts.',
            suggestedCorrection:
                'Consider integrating foreshadowing or scene atmosphere referencing this faction or location.',
          ),
        );
      }
    }

    // Heuristic 3: Check for Timeline flow
    if (timelineEvents.length >= 2 && chapters.length >= 2) {
      issues.add(
        ConsistencyIssue(
          id: generateUuid(),
          title: 'Timeline Progression Check',
          category: ConsistencyCategory.timeline,
          severity: ConsistencySeverity.low,
          chapterTitle: chapters.last.title,
          citedExcerpt:
              'Pacing transition between "${chapters.first.title}" and "${chapters.last.title}".',
          issueBreakdown:
              'Verify that travel duration and night/day shifts align with chronological markers in your timeline outline.',
          suggestedCorrection:
              'Add a sensory transition phrase establishing how many days or hours have elapsed.',
        ),
      );
    }

    final inconsistencyPct = (issues.length * 7.5).clamp(0.0, 45.0);
    final consistencyScore = (100.0 - inconsistencyPct).clamp(55.0, 100.0);

    return ConsistencyReport(
      novelId: novelId,
      consistencyScore: consistencyScore,
      inconsistencyScore: inconsistencyPct,
      totalIssues: issues.length,
      analyzedChapterCount: chapters.length,
      issues: issues,
      summary: issues.isEmpty
          ? 'Great continuity! No major lore or timeline discrepancies detected across ${chapters.length} chapters.'
          : 'Detected ${issues.length} continuity items to review across ${chapters.length} chapters.',
      analyzedAt: DateTime.now().toUtc(),
    );
  }
}
