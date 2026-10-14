import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../domain/models/world_map_models.dart';

class WorldMapRepository {
  final AppDatabase? _db;

  WorldMapRepository([this._db]);

  String _mapKey(String novelId) => 'world_map_$novelId';

  /// Loads the world map for [novelId]. Returns null if no map has been uploaded yet.
  Future<WorldMap?> loadMap(String novelId) async {
    final db = _db;
    if (db == null) return null;

    final key = _mapKey(novelId);
    try {
      final row = await (db.select(db.appSettings)
            ..where((tbl) => tbl.key.equals(key)))
          .getSingleOrNull();

      if (row != null && row.value.isNotEmpty) {
        final decoded = jsonDecode(row.value) as Map<String, dynamic>;
        final map = WorldMap.fromJson(decoded);
        if (map.svgContent.trim().isNotEmpty) {
          return map;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Persists [map] to the database.
  Future<void> saveMap(WorldMap map) async {
    final db = _db;
    if (db == null) return;

    final key = _mapKey(map.novelId);
    final jsonStr = jsonEncode(map.toJson());
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonStr,
            updatedAt: now,
          ),
        );
  }

  /// Deletes the world map for [novelId].
  Future<void> deleteMap(String novelId) async {
    final db = _db;
    if (db == null) return;

    final key = _mapKey(novelId);
    await (db.delete(db.appSettings)..where((tbl) => tbl.key.equals(key))).go();
  }

  /// Imports a new SVG vector map, calculating dimensions and preserving existing pins.
  Future<WorldMap> importSvg({
    required String novelId,
    required String svgContent,
    String? title,
    String? description,
  }) async {
    final current = await loadMap(novelId);
    final parsedSize = SvgDimensionParser.parse(svgContent);
    final sanitizedSvg = SvgSanitizer.sanitize(
      svgContent,
      width: parsedSize.width,
      height: parsedSize.height,
    );
    final now = DateTime.now();

    final updatedMap = (current != null)
        ? current.copyWith(
            title: title ?? current.title,
            description: description ?? current.description,
            svgContent: sanitizedSvg,
            width: parsedSize.width,
            height: parsedSize.height,
            updatedAt: now,
          )
        : WorldMap(
            id: 'map_${novelId}_${now.millisecondsSinceEpoch}',
            novelId: novelId,
            title: title ?? 'Realm World Map',
            description: description ?? 'Custom cartographic projection',
            svgContent: sanitizedSvg,
            width: parsedSize.width,
            height: parsedSize.height,
            pins: const [],
            createdAt: now,
            updatedAt: now,
          );

    await saveMap(updatedMap);
    return updatedMap;
  }
}
