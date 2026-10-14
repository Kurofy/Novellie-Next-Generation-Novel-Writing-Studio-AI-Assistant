import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novellie/features/characters/application/character_providers.dart';
import 'package:novellie/features/characters/domain/models/character_model.dart';
import 'package:novellie/features/characters/domain/repositories/character_repository.dart';
import 'package:novellie/features/manuscript/application/manuscript_providers.dart';
import 'package:novellie/features/manuscript/domain/models/manuscript_models.dart';
import 'package:novellie/features/manuscript/domain/repositories/manuscript_repository.dart';
import 'package:novellie/features/outline/application/planning_providers.dart';
import 'package:novellie/features/outline/domain/models/planning_models.dart';
import 'package:novellie/features/outline/domain/repositories/planning_repository.dart';
import 'package:novellie/features/world/application/world_providers.dart';
import 'package:novellie/features/world/domain/models/world_models.dart';
import 'package:novellie/features/world/domain/repositories/world_repository.dart';
import '../data/services/consistency_checker_service.dart';
import '../domain/models/ai_models.dart';
import '../domain/models/consistency_models.dart';
import 'ai_providers.dart';

enum ConsistencyScope {
  allChapters('All Chapters'),
  selectedChapters('Select Specific Chapters');

  final String label;
  const ConsistencyScope(this.label);
}

final consistencyCheckerServiceProvider =
    Provider<ConsistencyCheckerService>((ref) {
  final aiClient = ref.watch(aiClientServiceProvider);
  return ConsistencyCheckerService(aiClient);
});

final consistencyScopeProvider =
    StateProvider<ConsistencyScope>((ref) => ConsistencyScope.allChapters);

final selectedConsistencyChapterIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

final isAnalyzingConsistencyProvider = StateProvider<bool>((ref) => false);

final consistencyReportProvider =
    StateProvider<ConsistencyReport?>((ref) => null);

final consistencyControllerProvider = Provider<ConsistencyController>((ref) {
  return ConsistencyController(ref);
});

class ConsistencyController {
  final Ref _ref;

  ConsistencyController(this._ref);

  void toggleChapter(String chapterId) {
    final current =
        Set<String>.from(_ref.read(selectedConsistencyChapterIdsProvider));
    if (current.contains(chapterId)) {
      current.remove(chapterId);
    } else {
      current.add(chapterId);
    }
    _ref.read(selectedConsistencyChapterIdsProvider.notifier).state = current;
  }

  void setScope(ConsistencyScope scope) {
    _ref.read(consistencyScopeProvider.notifier).state = scope;
  }

  Future<void> runAnalysis(String novelId) async {
    _ref.read(isAnalyzingConsistencyProvider.notifier).state = true;

    try {
      final configAsync = _ref.read(aiConfigProvider);
      final config = configAsync.valueOrNull;

      final ManuscriptRepository repo =
          _ref.read(manuscriptRepositoryProvider);
      final List<ChapterModel> allChapters =
          await repo.watchChapters(novelId).first;

      final scope = _ref.read(consistencyScopeProvider);
      final selectedIds = _ref.read(selectedConsistencyChapterIdsProvider);

      final List<ChapterModel> targetChapters =
          scope == ConsistencyScope.allChapters
              ? allChapters
              : allChapters
                  .where((ChapterModel c) => selectedIds.contains(c.id))
                  .toList();

      final chapterPayloads =
          <({String id, String title, String plainText})>[];
      for (final ch in targetChapters) {
        final content = await repo.getChapterContent(ch.id);
        chapterPayloads.add((
          id: ch.id,
          title: ch.displayTitle,
          plainText: content.plainText,
        ),);
      }

      final CharacterRepository charRepo =
          _ref.read(characterRepositoryProvider);
      final List<CharacterModel> characters =
          await charRepo.watchCharacters(novelId).first;

      final WorldRepository worldRepo = _ref.read(worldRepositoryProvider);
      final List<WorldEntryModel> worldEntries =
          await worldRepo.watchEntries(novelId).first;

      final PlanningRepository planRepo =
          _ref.read(planningRepositoryProvider);
      final List<TimelineEventModel> events =
          await planRepo.watchEvents(novelId).first;

      final ConsistencyCheckerService service =
          _ref.read(consistencyCheckerServiceProvider);
      final report = await service.analyze(
        config: config ?? const AiConfigModel(),
        novelId: novelId,
        chapters: chapterPayloads,
        characters: characters,
        worldEntries: worldEntries,
        timelineEvents: events,
      );

      _ref.read(consistencyReportProvider.notifier).state = report;
    } catch (_) {
    } finally {
      _ref.read(isAnalyzingConsistencyProvider.notifier).state = false;
    }
  }
}
