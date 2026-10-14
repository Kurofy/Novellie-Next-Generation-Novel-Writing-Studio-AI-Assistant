import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../data/repositories/world_map_repository.dart';
import '../domain/models/world_map_models.dart';

final worldMapRepositoryProvider = Provider<WorldMapRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorldMapRepository(db);
});

class WorldMapNotifier extends StateNotifier<AsyncValue<WorldMap?>> {
  final WorldMapRepository _repository;
  final String novelId;

  WorldMapNotifier(this._repository, this.novelId)
      : super(const AsyncValue.loading()) {
    loadMap();
  }

  Future<void> loadMap() async {
    try {
      final map = await _repository.loadMap(novelId);
      state = AsyncValue.data(map);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importSvg(String svgContent, {String? title, String? description}) async {
    try {
      final updated = await _repository.importSvg(
        novelId: novelId,
        svgContent: svgContent,
        title: title,
        description: description,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMap() async {
    try {
      await _repository.deleteMap(novelId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPin(MapPin pin) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPins = [...current.pins, pin];
    final updated = current.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await _repository.saveMap(updated);
  }

  Future<void> updatePin(MapPin updatedPin) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPins = current.pins.map((p) {
      return p.id == updatedPin.id ? updatedPin : p;
    }).toList();

    final updated = current.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await _repository.saveMap(updated);
  }

  Future<void> deletePin(String pinId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPins = current.pins.where((p) => p.id != pinId).toList();
    final updated = current.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await _repository.saveMap(updated);
  }

  Future<void> updateTitle(String title, [String? description]) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      title: title,
      description: description ?? current.description,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    await _repository.saveMap(updated);
  }
}

final worldMapProvider = StateNotifierProvider.family<WorldMapNotifier,
    AsyncValue<WorldMap?>, String>((ref, novelId) {
  final repo = ref.watch(worldMapRepositoryProvider);
  return WorldMapNotifier(repo, novelId);
});

/// Category filter provider for active map view
final activeMapCategoryFilterProvider = StateProvider<MapPinCategory?>((ref) => null);

/// Search query provider for filtering pins by title/description
final mapPinSearchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected/highlighted pin ID on the map
final selectedPinIdProvider = StateProvider<String?>((ref) => null);
