import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/ai/data/services/ai_client_service.dart';
import 'package:novellie/features/ai/data/services/consistency_checker_service.dart';
import 'package:novellie/features/ai/domain/models/ai_models.dart';
import 'package:novellie/features/ai/domain/models/consistency_models.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';
import 'package:novellie/features/outline/domain/models/planning_models.dart';
import 'package:novellie/features/world/domain/models/world_models.dart';

void main() {
  group('ConsistencyCheckerService', () {
    late ConsistencyCheckerService service;

    setUp(() {
      final dio = Dio();
      final aiClient = AiClientService(dio);
      service = ConsistencyCheckerService(aiClient);
    });

    test('performs heuristic analysis when no AI key is configured', () async {
      final now = DateTime.now();
      const chapters = [
        (
          id: 'ch-1',
          title: 'Chapter 1: The Encounter',
          plainText:
              'Elena has piercing blue eyes and stands tall in the Great Citadel.',
        ),
        (
          id: 'ch-2',
          title: 'Chapter 2: The Return',
          plainText:
              'Elena looked through her deep dark brown eyes, wandering away from the Great Citadel.',
        ),
      ];

      final characters = [
        CharacterModel(
          id: 'char-1',
          novelId: 'novel-1',
          name: 'Elena',
          appearance: 'blue eyes, silver cloak',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final report = await service.analyze(
        novelId: 'novel-1',
        chapters: chapters,
        characters: characters,
        worldEntries: const <WorldEntryModel>[],
        timelineEvents: const <TimelineEventModel>[],
        config: const AiConfigModel(
          provider: AiProviderType.gemini,
          apiKey: '', // Empty API key triggers heuristic engine
        ),
      );

      expect(report.analyzedChapterCount, 2);
      expect(report.consistencyScore, inInclusiveRange(0.0, 100.0));
      expect(report.inconsistencyScore, inInclusiveRange(0.0, 100.0));
      expect(report.issues, isNotEmpty);
      expect(
        report.issues.any(
          (ConsistencyIssue issue) =>
              issue.category == ConsistencyCategory.character,
        ),
        isTrue,
      );
    });

    test('consistency report serializes and deserializes accurately', () {
      final now = DateTime.now();
      final report = ConsistencyReport(
        novelId: 'novel-123',
        consistencyScore: 92.5,
        inconsistencyScore: 7.5,
        totalIssues: 1,
        analyzedChapterCount: 5,
        summary: 'Minor issue found',
        analyzedAt: now,
        issues: const [
          ConsistencyIssue(
            id: 'issue-1',
            title: 'Eyes Color Shift',
            category: ConsistencyCategory.character,
            severity: ConsistencySeverity.medium,
            chapterTitle: 'Chapter 2',
            citedExcerpt: 'Elena looked through her deep dark brown eyes',
            issueBreakdown: 'Elena previously established with blue eyes',
            suggestedCorrection: 'Change to piercing blue eyes',
          ),
        ],
      );

      final json = report.toJson();
      final reconstructed = ConsistencyReport.fromJson(json);

      expect(reconstructed.novelId, 'novel-123');
      expect(reconstructed.consistencyScore, 92.5);
      expect(reconstructed.inconsistencyScore, 7.5);
      expect(reconstructed.totalIssues, 1);
      expect(reconstructed.issues.first.title, 'Eyes Color Shift');
      expect(reconstructed.issues.first.severity, ConsistencySeverity.medium);
    });
  });
}
