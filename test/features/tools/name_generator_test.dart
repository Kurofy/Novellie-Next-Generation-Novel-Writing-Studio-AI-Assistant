import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/tools/application/tools_providers.dart';
import 'package:novellie/features/tools/data/repositories/name_repository.dart';
import 'package:novellie/features/tools/domain/models/name_models.dart';
import 'package:novellie/features/tools/presentation/screens/name_generator_screen.dart';
import 'package:novellie/features/tools/presentation/screens/tools_hub_screen.dart';
import 'package:novellie/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockCategories = [
    const NameCategoryData(
      category: 'Elf',
      male: NameGenderData(
        firstNames: ['Legolas', 'Elrond', 'Thranduil'],
        lastNames: ['Greenleaf', 'Moonshadow'],
      ),
      female: NameGenderData(
        firstNames: ['Galadriel', 'Arwen', 'Tauriel'],
        lastNames: ['Evenstar', 'Sunstrider'],
      ),
      unisex: NameGenderData(
        firstNames: ['Faelar', 'Sylph'],
        lastNames: ['Whisperwind'],
      ),
    ),
    const NameCategoryData(
      category: 'Demon',
      male: NameGenderData(
        firstNames: ['Malakor', 'Azazel'],
        lastNames: ['Bane', 'Shadow'],
      ),
      female: NameGenderData(
        firstNames: ['Lilith', 'Morrigan'],
        lastNames: ['Nightfall', 'Flame'],
      ),
      unisex: NameGenderData(
        firstNames: ['Kael', 'Vex'],
        lastNames: ['Abyss'],
      ),
    ),
  ];

  group('NameRepository & Mode 1 Generation', () {
    test('loads categories and generates basic names strictly from dataset', () async {
      final repo = NameRepository();
      final categories = await repo.loadCategories();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.category == 'Elf'), isTrue);
      expect(categories.any((c) => c.category == 'Demon'), isTrue);
      expect(categories.any((c) => c.category == 'Nordic'), isTrue);

      final elfCat = categories.firstWhere((c) => c.category == 'Elf');
      expect(elfCat.female.firstNames, isNotEmpty);
      expect(elfCat.female.lastNames, isNotEmpty);

      // Mode 1: strictly retrieves random first_name and last_name from matching arrays
      final generated = await repo.generateBasicNames(
        category: 'Elf',
        gender: 'female',
        count: 5,
      );

      expect(generated.length, equals(5));
      for (final item in generated) {
        expect(elfCat.female.firstNames.contains(item.firstName), isTrue);
        expect(elfCat.female.lastNames.contains(item.lastName), isTrue);
        expect(item.category, equals('Elf'));
        expect(item.gender, equals('female'));
        expect(item.isAiGenerated, isFalse);
      }
    });

    test('Mode 1 respects count parameter', () async {
      final repo = NameRepository();
      final generated1 = await repo.generateBasicNames(
        category: 'Roman',
        gender: 'male',
        count: 1,
      );
      expect(generated1.length, equals(1));

      final generated10 = await repo.generateBasicNames(
        category: 'Roman',
        gender: 'male',
        count: 10,
      );
      expect(generated10.length, equals(10));
    });
  });

  group('Tools UI Tests', () {
    Widget buildTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          nameCategoriesProvider.overrideWith((ref) => Future.value(mockCategories)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets('ToolsHubScreen renders Names Generator and active features without upcoming tools',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Names Generator'), findsOneWidget);
      expect(find.text('Family Tree'), findsOneWidget);
      expect(find.text('Mind Map'), findsOneWidget);
      expect(find.text('World Atlas'), findsOneWidget);
      expect(find.text('Writer Notes'), findsOneWidget);
      expect(find.text('Timeline & World Chronology'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);
    });

    testWidgets('NameGeneratorScreen switches between Mode 1 and Mode 2',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const NameGeneratorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Names Generator'), findsOneWidget);
      expect(find.text('Mode 1: Basic'), findsOneWidget);
      expect(find.text('Mode 2: Advanced (AI)'), findsOneWidget);

      // Verify Mode 1 elements (mode card removed)
      expect(find.text('Origin / Theme Category'), findsOneWidget);

      // Tap Mode 2
      await tester.tap(find.text('Mode 2: Advanced (AI)'));
      await tester.pumpAndSettle();

      // Verify Mode 2 elements (mode card removed)
      expect(
        find.text('Character Traits, Aesthetic & Background'),
        findsOneWidget,
      );
    });
  });
}
