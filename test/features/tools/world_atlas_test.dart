import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/novels/application/novel_providers.dart';
import 'package:novellie/features/novels/domain/models/novel_model.dart';
import 'package:novellie/features/tools/application/world_map_providers.dart';
import 'package:novellie/features/tools/data/repositories/world_map_repository.dart';
import 'package:novellie/features/tools/domain/models/world_map_models.dart';
import 'package:novellie/features/tools/presentation/screens/world_atlas_screen.dart';
import 'package:novellie/features/tools/presentation/widgets/map_pin_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testNovel = NovelModel(
    id: 'novel-atlas-1',
    title: 'Chronicles of Solaria',
    genre: 'Fantasy',
    status: NovelStatus.drafting,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('World Atlas Domain Models & SvgDimensionParser Tests', () {
    test('MapPin serializes and deserializes accurately with normalized coordinates', () {
      final pin = MapPin(
        id: 'pin-123',
        novelId: 'novel-1',
        mapId: 'map-1',
        title: 'Emerald Bastion',
        description: 'Impenetrable fortress of the high warden.',
        category: MapPinCategory.capital,
        x: 0.354,
        y: 0.782,
        linkedEntryId: 'codex-entry-42',
        linkedCharacterIds: ['char-1', 'char-2'],
        linkedChapterIds: ['chap-10'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final json = pin.toJson();
      expect(json['id'], 'pin-123');
      expect(json['x'], 0.354);
      expect(json['y'], 0.782);
      expect(json['category'], 'capital');
      expect(json['linkedEntryId'], 'codex-entry-42');
      expect(json['linkedCharacterIds'], ['char-1', 'char-2']);
      expect(json['linkedChapterIds'], ['chap-10']);

      final restored = MapPin.fromJson(json);
      expect(restored.id, pin.id);
      expect(restored.title, pin.title);
      expect(restored.category, MapPinCategory.capital);
      expect(restored.x, 0.354);
      expect(restored.y, 0.782);
      expect(restored.linkedCharacterIds.length, 2);
    });

    test('WorldMap serializes and deserializes with pins and SVG content', () {
      final map = WorldMap(
        id: 'map-abc',
        novelId: 'novel-1',
        title: 'Continent of Aethelgard',
        description: 'Primary western continent projection',
        svgContent: '<svg viewBox="0 0 1920 1080"></svg>',
        width: 1920,
        height: 1080,
        pins: [
          MapPin(
            id: 'p1',
            novelId: 'novel-1',
            mapId: 'map-abc',
            title: 'Port Valor',
            category: MapPinCategory.port,
            x: 0.1,
            y: 0.2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = map.toJson();
      expect(json['width'], 1920);
      expect(json['height'], 1080);
      expect((json['pins'] as List).length, 1);

      final restored = WorldMap.fromJson(json);
      expect(restored.title, 'Continent of Aethelgard');
      expect(restored.width, 1920);
      expect(restored.pins.first.title, 'Port Valor');
      expect(restored.pins.first.category, MapPinCategory.port);
    });

    test('SvgDimensionParser parses viewBox and width/height correctly', () {
      const svgWithViewBox = '<svg viewBox="0 0 2000 1200" xmlns="http://www.w3.org/2000/svg"></svg>';
      final size1 = SvgDimensionParser.parse(svgWithViewBox);
      expect(size1.width, 2000);
      expect(size1.height, 1200);

      const svgWithAttributes = '<svg width="1440px" height="900px"></svg>';
      final size2 = SvgDimensionParser.parse(svgWithAttributes);
      expect(size2.width, 1440);
      expect(size2.height, 900);

      const svgFallback = '<svg></svg>';
      final size3 = SvgDimensionParser.parse(svgFallback);
      expect(size3.width, 1600);
      expect(size3.height, 1000);
    });

    test('SvgSanitizer converts font-size 0.7% and relative percentages to valid pixel values', () {
      const azgaarSvgSample = '''
<svg viewBox="0 0 1600 1000" xmlns="http://www.w3.org/2000/svg">
  <style>
    #labels { font-family: "Signika"; font-size: 0.7%; }
    #states text { font-size: 2%; }
    #burgs text { font-size: 0.7% !important; }
  </style>
  <g id="labels">
    <text font-size="0.7%">Capital Fortress</text>
    <text style="font-size: 0.7%; fill: #ffffff;">Deepwood Haven</text>
    <text font-size="smaller">Minor Shrine</text>
  </g>
</svg>
''';

      final sanitized = SvgSanitizer.sanitize(azgaarSvgSample, width: 1600, height: 1000);

      // Verify font-size: 0.7% is converted to valid px (0.7% of 1600 = 11.2px)
      expect(sanitized.contains('0.7%'), isFalse);
      expect(sanitized.contains('11.2px'), isTrue);
      // Verify states 2% converted to 32px
      expect(sanitized.contains('32px'), isTrue);
      // Verify !important is stripped
      expect(sanitized.contains('!important'), isFalse);
      // Verify smaller is converted to 11.2px
      expect(sanitized.contains('smaller'), isFalse);
    });

    test('SvgSanitizer strips script tags and UTF-8 BOM', () {
      const svgWithScript = '\uFEFF<svg viewBox="0 0 800 600"><script>alert(1);</script><rect width="800" height="600"/></svg>';
      final sanitized = SvgSanitizer.sanitize(svgWithScript);

      expect(sanitized.startsWith('\uFEFF'), isFalse);
      expect(sanitized.contains('<script>'), isFalse);
      expect(sanitized.contains('alert(1)'), isFalse);
    });
  });

  group('MapPinWidget UI Tests', () {
    testWidgets('Renders pin with category icon and title badge', (tester) async {
      final pin = MapPin(
        id: 'test-pin',
        novelId: 'n1',
        mapId: 'm1',
        title: 'Sunken Crypt',
        category: MapPinCategory.dungeon,
        x: 0.5,
        y: 0.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: MapPinWidget(
              pin: pin,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Sunken Crypt'), findsOneWidget);
      expect(find.byIcon(MapPinCategory.dungeon.icon), findsOneWidget);
    });
  });

  group('WorldAtlasScreen UI & Interaction Tests', () {
    testWidgets('Renders Onboarding Guide when no SVG map is uploaded yet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            novelListStreamProvider.overrideWith(
              (ref) => Stream.value([testNovel]),
            ),
            activeNovelIdProvider.overrideWith(
              (ref) => testNovel.id,
            ),
            worldMapProvider(testNovel.id).overrideWith(
              (ref) => _MockWorldMapNotifier(null, testNovel.id),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const WorldAtlasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Onboarding Guide title and instructions
      expect(find.text('World Atlas Onboarding Guide'), findsOneWidget);
      expect(find.text('Upload .SVG Map File'), findsOneWidget);
      expect(find.text('Paste SVG Code'), findsOneWidget);
      expect(find.textContaining('Azgaar’s Fantasy Map Generator'), findsOneWidget);
      expect(find.text('Copy Azgaar Map Generator URL'), findsOneWidget);

      // Marker controls are NOT present in onboarding view
      expect(find.byType(TextField), findsNothing);
      expect(find.text('All'), findsNothing);
    });

    testWidgets('WorldAtlasScreen renders interactive vector canvas, markers, and controls when map uploaded', (tester) async {
      final defaultTestMap = WorldMap(
        id: 'map-test',
        novelId: testNovel.id,
        title: 'The Known Realms',
        svgContent: '<svg viewBox="0 0 800 600"><rect width="800" height="600" fill="#141E30"/></svg>',
        width: 800,
        height: 600,
        pins: [
          MapPin(
            id: 'pin-1',
            novelId: testNovel.id,
            mapId: 'map-test',
            title: 'High Crown Citadel',
            category: MapPinCategory.capital,
            x: 0.3,
            y: 0.4,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          MapPin(
            id: 'pin-2',
            novelId: testNovel.id,
            mapId: 'map-test',
            title: 'Ironfang Keep',
            category: MapPinCategory.dungeon,
            x: 0.7,
            y: 0.6,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            novelListStreamProvider.overrideWith(
              (ref) => Stream.value([testNovel]),
            ),
            activeNovelIdProvider.overrideWith(
              (ref) => testNovel.id,
            ),
            worldMapProvider(testNovel.id).overrideWith(
              (ref) => _MockWorldMapNotifier(defaultTestMap, testNovel.id),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const WorldAtlasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header title and active novel indicators
      expect(find.text('World Atlas'), findsOneWidget);
      expect(find.text('Vector'), findsOneWidget);
      expect(find.textContaining('Chronicles of Solaria'), findsOneWidget);

      // Markers rendered on canvas
      expect(find.text('High Crown Citadel'), findsOneWidget);
      expect(find.text('Ironfang Keep'), findsOneWidget);

      // Category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Capital City'), findsOneWidget);
      expect(find.text('Dungeon / Cave'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Tapping category chip filters pins
      await tester.tap(find.text('Dungeon / Cave'));
      await tester.pumpAndSettle();

      expect(find.text('Ironfang Keep'), findsOneWidget);
      expect(find.text('High Crown Citadel'), findsNothing);

      // Reset to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('High Crown Citadel'), findsOneWidget);
      expect(find.text('Ironfang Keep'), findsOneWidget);
    });

    testWidgets('WorldAtlasScreen renders SVG map containing font-size 0.7% without error', (tester) async {
      const azgaarSvg = '''
<svg viewBox="0 0 1600 1000" xmlns="http://www.w3.org/2000/svg">
  <style>
    #labels { font-size: 0.7%; }
    .burgs { font-size: 0.7% !important; }
  </style>
  <rect width="1600" height="1000" fill="#0b132b"/>
  <text font-size="0.7%" x="100" y="100">Solaria</text>
  <text style="font-size: 0.7%" x="200" y="200">Lunaria</text>
</svg>
''';

      final mapWithFontSizePercent = WorldMap(
        id: 'map-percent',
        novelId: testNovel.id,
        title: 'Cartographic Atlas',
        svgContent: azgaarSvg,
        width: 1600,
        height: 1000,
        pins: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            novelListStreamProvider.overrideWith(
              (ref) => Stream.value([testNovel]),
            ),
            activeNovelIdProvider.overrideWith(
              (ref) => testNovel.id,
            ),
            worldMapProvider(testNovel.id).overrideWith(
              (ref) => _MockWorldMapNotifier(mapWithFontSizePercent, testNovel.id),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const WorldAtlasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure the error builder is NOT triggered
      expect(find.text('Unable to render SVG markup as vector image'), findsNothing);
      expect(find.textContaining('could not parse font-size'), findsNothing);
      expect(find.text('World Atlas'), findsOneWidget);
    });
  });
}

class _MockWorldMapNotifier extends WorldMapNotifier {
  _MockWorldMapNotifier(WorldMap? initialMap, String novelId)
      : super(_FakeWorldMapRepository(initialMap), novelId) {
    state = AsyncValue.data(initialMap);
  }
}

class _FakeWorldMapRepository extends Fake implements WorldMapRepository {
  final WorldMap? _map;
  _FakeWorldMapRepository(this._map);

  @override
  Future<WorldMap?> loadMap(String novelId) async => _map;

  @override
  Future<void> saveMap(WorldMap map) async {}

  @override
  Future<void> deleteMap(String novelId) async {}
}
