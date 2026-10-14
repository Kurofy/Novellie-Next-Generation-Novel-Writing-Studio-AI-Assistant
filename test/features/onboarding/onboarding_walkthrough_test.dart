import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:novellie/core/theme/theme.dart';
import 'package:novellie/features/ai/application/ai_providers.dart';
import 'package:novellie/features/ai/domain/models/ai_models.dart';
import 'package:novellie/features/onboarding/application/onboarding_providers.dart';
import 'package:novellie/features/onboarding/domain/models/onboarding_step_model.dart';
import 'package:novellie/features/onboarding/presentation/widgets/onboarding_toast_guide.dart';
import 'package:novellie/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStatefulNavigationShell extends Fake
    implements StatefulNavigationShell {
  @override
  int get currentIndex => 0;

  @override
  void goBranch(int index, {bool? initialLocation}) {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeStatefulNavigationShell';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingStep Domain Model Tests', () {
    test('Sequence matches exact required workflow starting with Choose Language', () {
      const steps = OnboardingStep.values;
      expect(steps.length, 8);
      expect(steps[0], OnboardingStep.chooseLanguage);
      expect(steps[1], OnboardingStep.aiKeyPrompt);
      expect(steps[2], OnboardingStep.workspaceFeatures);
      expect(steps[3], OnboardingStep.characterWorldIndex);
      expect(steps[4], OnboardingStep.planningTab);
      expect(steps[5], OnboardingStep.toolsTab);
      expect(steps[6], OnboardingStep.aiTab);
      expect(steps[7], OnboardingStep.settingsTab);
    });

    test('Each step has descriptive titles, labels, icons, and target branches', () {
      for (final step in OnboardingStep.values) {
        expect(step.title.isNotEmpty, isTrue);
        expect(step.description.isNotEmpty, isTrue);
        expect(step.stepLabel.isNotEmpty, isTrue);
        expect(step.icon, isNotNull);
        expect(step.accentColor, isNotNull);
      }
    });
  });

  group('OnboardingNotifier State & Persistence Tests', () {
    test('Starts active on first launch when uncompleted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = OnboardingNotifier(prefs);
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStep, OnboardingStep.chooseLanguage);
      expect(notifier.state.hasCompleted, isFalse);
    });

    test('Does not start active if already completed', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingNotifier.prefKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final notifier = OnboardingNotifier(prefs);
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.hasCompleted, isTrue);
    });

    test('Progresses through all steps sequentially and completes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = OnboardingNotifier(prefs);
      expect(notifier.state.currentStep, OnboardingStep.chooseLanguage);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.aiKeyPrompt);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.workspaceFeatures);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.characterWorldIndex);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.planningTab);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.toolsTab);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.aiTab);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.settingsTab);
      expect(notifier.state.isLastStep, isTrue);

      notifier.nextStep();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.hasCompleted, isTrue);
      expect(prefs.getBool(OnboardingNotifier.prefKey), isTrue);
    });

    test('Back navigation and skip tour work accurately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = OnboardingNotifier(prefs);
      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.aiKeyPrompt);

      notifier.previousStep();
      expect(notifier.state.currentStep, OnboardingStep.chooseLanguage);

      await notifier.skipWalkthrough();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.hasCompleted, isTrue);
      expect(prefs.getBool(OnboardingNotifier.prefKey), isTrue);

      await notifier.restartWalkthrough();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStep, OnboardingStep.chooseLanguage);
      expect(notifier.state.hasCompleted, isFalse);
    });
  });

  group('OnboardingToastGuide UI Tests', () {
    late _FakeStatefulNavigationShell mockNavShell;

    setUp(() {
      mockNavShell = _FakeStatefulNavigationShell();
    });

    testWidgets('Renders Step 1 with Choose Your Language options and allows switching', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiConfigProvider.overrideWith(
              (ref) => _MockAiConfigNotifier(const AiConfigModel()),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Choose Your Language
      expect(find.text('Step 1 of 8 · Choose Language'), findsOneWidget);
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('Select Application Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);

      // Scroll to ensure visible and tap Bahasa Indonesia
      await tester.ensureVisible(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();

      // Tap Next -> moves to Step 2 AI Key Prompt
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 8 · Setup AI (BYOK)'), findsOneWidget);
      expect(find.text('Configure AI Provider Key (BYOK)'), findsOneWidget);
      expect(find.text('Configure Key'), findsOneWidget);
    });

    testWidgets('Tapping Next navigates steps smoothly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Choose Your Language
      expect(find.text('Choose Your Language'), findsOneWidget);

      // Tap Next -> Step 2: AI Key Prompt
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Configure AI Provider Key (BYOK)'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Tap Next -> Step 3: Workspace
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Novel Workspace & Manuscript'), findsOneWidget);

      // Tap Back -> returns to Step 2
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Configure AI Provider Key (BYOK)'), findsOneWidget);

      // Tap Back again -> returns to Step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsOneWidget);
    });

    testWidgets('Skip Tour dismisses toast guide', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsOneWidget);

      await tester.tap(find.text('Skip Tour'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsNothing);
    });

    testWidgets('Minimizing and expanding toast guide toggles compact pill', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially expanded
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('Step 1 of 8 · Choose Language'), findsOneWidget);

      // Tap minimize button
      final minimizeBtn = find.byTooltip('Minimize Guide');
      expect(minimizeBtn, findsOneWidget);
      await tester.tap(minimizeBtn);
      await tester.pumpAndSettle();

      // Title & Pro Tip are hidden in compact pill mode, but step label remains
      expect(find.text('Choose Your Language'), findsNothing);
      expect(find.text('Step 1 of 8 · Choose Language'), findsOneWidget);

      // Tap the label to expand again
      await tester.tap(find.text('Step 1 of 8 · Choose Language'));
      await tester.pumpAndSettle();

      // Card is expanded again
      expect(find.text('Choose Your Language'), findsOneWidget);
    });

    testWidgets('Tapping progress capsule jumps directly to target step', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1 initially
      expect(find.text('Choose Your Language'), findsOneWidget);

      // Tap capsule for Step 5 (Story Planning)
      final planningTooltip = find.byTooltip('Story Planning & Narrative Arcs');
      expect(planningTooltip, findsOneWidget);
      await tester.tap(planningTooltip);
      await tester.pumpAndSettle();

      // Verify jumped directly to Step 5
      expect(find.text('Story Planning & Narrative Arcs'), findsOneWidget);
      expect(find.text('Step 5 of 8 · Planning Tab'), findsOneWidget);
      expect(find.text('Go to Planning Tab'), findsOneWidget);
    });

    testWidgets('Renders iPhone Setup Assistant visual elements and feature highlights', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.text('Tour Mode'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);

      // Inset grouped capability card
      expect(find.text('Core Studio Capability'), findsOneWidget);
      expect(find.textContaining('Pro Tip:'), findsOneWidget);

      // Apple primary pill button
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('Swipe gestures navigate forward and backward like iOS setup', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: OnboardingToastGuide(navigationShell: mockNavShell),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsOneWidget);

      // Swipe left to advance (fling from right to left)
      await tester.fling(find.text('Choose Your Language'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Configure AI Provider Key (BYOK)'), findsOneWidget);

      // Swipe right to go back (fling from left to right)
      await tester.fling(find.text('Configure AI Provider Key (BYOK)'), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsOneWidget);
    });
  });
}

class _MockAiConfigNotifier extends StateNotifier<AsyncValue<AiConfigModel>>
    implements AiConfigNotifier {
  _MockAiConfigNotifier(AiConfigModel initial) : super(AsyncValue.data(initial));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
