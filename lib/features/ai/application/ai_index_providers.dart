import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../characters/application/character_providers.dart';
import '../../characters/domain/repositories/character_repository.dart';
import '../../manuscript/application/manuscript_providers.dart';
import '../../manuscript/domain/models/manuscript_models.dart';
import '../../manuscript/domain/repositories/manuscript_repository.dart';
import '../../world/application/world_providers.dart';
import '../../world/domain/models/world_models.dart';
import '../../world/domain/repositories/world_repository.dart';
import '../data/services/ai_index_service.dart';
import '../domain/models/ai_index_models.dart';
import '../domain/models/ai_models.dart';
import 'ai_providers.dart';

enum AiIndexStatus { idle, scanning, success, error }

class AiIndexState {
  final AiIndexStatus status;
  final List<AiIndexEntity> entities;
  final AiIndexEntityType? selectedFilter;
  final String? selectedChapterId;
  final String? errorMessage;
  final int addedCount;
  final bool isAdding;

  const AiIndexState({
    this.status = AiIndexStatus.idle,
    this.entities = const [],
    this.selectedFilter,
    this.selectedChapterId,
    this.errorMessage,
    this.addedCount = 0,
    this.isAdding = false,
  });

  AiIndexState copyWith({
    AiIndexStatus? status,
    List<AiIndexEntity>? entities,
    AiIndexEntityType? selectedFilter,
    bool clearFilter = false,
    String? selectedChapterId,
    bool clearChapterId = false,
    String? errorMessage,
    int? addedCount,
    bool? isAdding,
  }) {
    return AiIndexState(
      status: status ?? this.status,
      entities: entities ?? this.entities,
      selectedFilter:
          clearFilter ? null : (selectedFilter ?? this.selectedFilter),
      selectedChapterId:
          clearChapterId ? null : (selectedChapterId ?? this.selectedChapterId),
      errorMessage: errorMessage ?? this.errorMessage,
      addedCount: addedCount ?? this.addedCount,
      isAdding: isAdding ?? this.isAdding,
    );
  }

  List<AiIndexEntity> get filteredEntities {
    if (selectedFilter == null) return entities;
    return entities.where((e) => e.type == selectedFilter).toList();
  }

  int get newCount =>
      entities.where((e) => !e.isAlreadyInIndex && !e.isAdded).length;

  int get selectedCount =>
      entities.where((e) => e.isSelected && !e.isAdded && !e.isAlreadyInIndex).length;
}

final aiIndexServiceProvider = Provider<AiIndexService>((ref) {
  return AiIndexService(ref.watch(aiClientServiceProvider));
});

final aiIndexNotifierProvider =
    StateNotifierProvider.autoDispose<AiIndexNotifier, AiIndexState>((ref) {
  return AiIndexNotifier(
    service: ref.watch(aiIndexServiceProvider),
    manuscriptRepo: ref.watch(manuscriptRepositoryProvider),
    characterRepo: ref.watch(characterRepositoryProvider),
    worldRepo: ref.watch(worldRepositoryProvider),
    ref: ref,
  );
});

class AiIndexNotifier extends StateNotifier<AiIndexState> {
  final AiIndexService _service;
  final ManuscriptRepository _manuscriptRepo;
  final CharacterRepository _characterRepo;
  final WorldRepository _worldRepo;
  final Ref _ref;

  AiIndexNotifier({
    required AiIndexService service,
    required ManuscriptRepository manuscriptRepo,
    required CharacterRepository characterRepo,
    required WorldRepository worldRepo,
    required Ref ref,
  })  : _service = service,
        _manuscriptRepo = manuscriptRepo,
        _characterRepo = characterRepo,
        _worldRepo = worldRepo,
        _ref = ref,
        super(const AiIndexState());

  void setFilter(AiIndexEntityType? filter) {
    if (filter == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(selectedFilter: filter);
    }
  }

  void setChapterId(String? chapterId) {
    if (chapterId == null) {
      state = state.copyWith(clearChapterId: true);
    } else {
      state = state.copyWith(selectedChapterId: chapterId);
    }
  }

  void toggleSelect(String entityId) {
    state = state.copyWith(
      entities: state.entities.map((e) {
        if (e.id == entityId) {
          return e.copyWith(isSelected: !e.isSelected);
        }
        return e;
      }).toList(),
    );
  }

  void selectAll(bool select, {AiIndexEntityType? type}) {
    state = state.copyWith(
      entities: state.entities.map((e) {
        if (e.isAlreadyInIndex || e.isAdded) return e;
        if (type == null || e.type == type) {
          return e.copyWith(isSelected: select);
        }
        return e;
      }).toList(),
    );
  }

  Future<void> scanManuscript({
    required String novelId,
    String? specificChapterId,
  }) async {
    state = state.copyWith(
      status: AiIndexStatus.scanning,
      errorMessage: null,
      selectedChapterId: specificChapterId,
    );

    try {
      final config = _ref.read(aiConfigProvider).valueOrNull;

      // 1. Fetch Chapters
      final allChapters = await _manuscriptRepo.watchChapters(novelId).first;
      if (allChapters.isEmpty) {
        state = state.copyWith(
          status: AiIndexStatus.error,
          errorMessage: 'No chapters found in this novel to scan.',
        );
        return;
      }

      final targetChapters = specificChapterId != null
          ? allChapters.where((ChapterModel ch) => ch.id == specificChapterId).toList()
          : allChapters;

      if (targetChapters.isEmpty) {
        state = state.copyWith(
          status: AiIndexStatus.error,
          errorMessage: 'Selected chapter could not be found.',
        );
        return;
      }

      // 2. Fetch Chapter Contents
      final List<({String id, String title, String plainText})> chapterTexts = [];
      for (final ch in targetChapters) {
        final content = await _manuscriptRepo.getChapterContent(ch.id);
        if (content.plainText.trim().isNotEmpty) {
          chapterTexts.add((
            id: ch.id,
            title: ch.title,
            plainText: content.plainText,
          ),);
        }
      }

      if (chapterTexts.isEmpty) {
        state = state.copyWith(
          status: AiIndexStatus.error,
          errorMessage:
              'The selected chapter(s) have no written text yet. Write prose first to scan for index entities.',
        );
        return;
      }

      // 3. Fetch Existing Entities
      final existingChars =
          await _characterRepo.watchCharacters(novelId).first;
      final existingEntries =
          await _worldRepo.watchEntries(novelId).first;

      // 4. Run Scan
      final entities = await _service.scanManuscript(
        config: config ?? const AiConfigModel(),
        novelId: novelId,
        chapters: chapterTexts,
        existingCharacters: existingChars,
        existingWorldEntries: existingEntries,
      );

      state = state.copyWith(
        status: AiIndexStatus.success,
        entities: entities,
      );
    } catch (err) {
      state = state.copyWith(
        status: AiIndexStatus.error,
        errorMessage: err.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }

  Future<bool> addToIndex(AiIndexEntity entity, String novelId) async {
    try {
      if (entity.type == AiIndexEntityType.character) {
        await _characterRepo.createCharacter(
          novelId: novelId,
          name: entity.name,
          role: entity.characterRole,
          notes: entity.summary,
        );
      } else {
        // World entry
        final categories = await _worldRepo.watchCategories(novelId).first;
        String? targetCategoryId;

        // Attempt exact categoryKey match
        for (final cat in categories) {
          if (cat.key.toLowerCase() == entity.categoryKey.toLowerCase()) {
            targetCategoryId = cat.id;
            break;
          }
        }

        // Fallback type match
        if (targetCategoryId == null) {
          String fallbackKey = 'concepts';
          switch (entity.type) {
            case AiIndexEntityType.location:
              fallbackKey = 'locations';
              break;
            case AiIndexEntityType.organization:
              fallbackKey = 'organizations';
              break;
            case AiIndexEntityType.faction:
              fallbackKey = 'factions';
              break;
            case AiIndexEntityType.religion:
              fallbackKey = 'religions';
              break;
            default:
              fallbackKey = 'concepts';
          }
          final fallbackCat = categories.firstWhere(
            (WorldCategoryModel c) => c.key.toLowerCase() == fallbackKey,
            orElse: () => categories.isNotEmpty
                ? categories.first
                : throw StateError('No world categories found for novel.'),
          );
          targetCategoryId = fallbackCat.id;
        }

        await _worldRepo.createEntry(
          novelId: novelId,
          categoryId: targetCategoryId,
          name: entity.name,
          summary: entity.summary,
        );
      }

      state = state.copyWith(
        addedCount: state.addedCount + 1,
        entities: state.entities.map((e) {
          if (e.id == entity.id) {
            return e.copyWith(
              isAdded: true,
              isAlreadyInIndex: true,
              isSelected: false,
            );
          }
          return e;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> addSelected(String novelId) async {
    state = state.copyWith(isAdding: true);
    int added = 0;

    final toAdd = state.entities
        .where((e) => e.isSelected && !e.isAdded && !e.isAlreadyInIndex)
        .toList();

    for (final entity in toAdd) {
      final success = await addToIndex(entity, novelId);
      if (success) added++;
    }

    state = state.copyWith(isAdding: false);
    return added;
  }
}
