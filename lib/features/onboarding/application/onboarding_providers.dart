import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/models/onboarding_step_model.dart';

class OnboardingState {
  final bool isActive;
  final OnboardingStep currentStep;
  final bool hasCompleted;

  const OnboardingState({
    this.isActive = false,
    this.currentStep = OnboardingStep.chooseLanguage,
    this.hasCompleted = false,
  });

  int get currentStepIndex => currentStep.index;
  int get totalSteps => OnboardingStep.values.length;
  bool get isFirstStep => currentStep.index == 0;
  bool get isLastStep => currentStep.index == totalSteps - 1;

  OnboardingState copyWith({
    bool? isActive,
    OnboardingStep? currentStep,
    bool? hasCompleted,
  }) {
    return OnboardingState(
      isActive: isActive ?? this.isActive,
      currentStep: currentStep ?? this.currentStep,
      hasCompleted: hasCompleted ?? this.hasCompleted,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  static const String prefKey = 'onboarding_walkthrough_completed_v1';
  final SharedPreferences? _prefs;

  OnboardingNotifier([this._prefs])
      : super(const OnboardingState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final completed = prefs.getBool(prefKey) ?? false;

    if (!completed) {
      // First-time app launch: automatically activate walkthrough starting with language selection
      state = const OnboardingState(
        isActive: true,
        currentStep: OnboardingStep.chooseLanguage,
        hasCompleted: false,
      );
    } else {
      state = state.copyWith(
        isActive: false,
        hasCompleted: true,
      );
    }
  }

  void nextStep() {
    if (!state.isActive) return;

    if (state.isLastStep) {
      completeWalkthrough();
    } else {
      final nextIndex = state.currentStepIndex + 1;
      state = state.copyWith(
        currentStep: OnboardingStep.values[nextIndex],
      );
    }
  }

  void previousStep() {
    if (!state.isActive || state.isFirstStep) return;

    final prevIndex = state.currentStepIndex - 1;
    state = state.copyWith(
      currentStep: OnboardingStep.values[prevIndex],
    );
  }

  void goToStep(OnboardingStep step) {
    if (!state.isActive) return;
    state = state.copyWith(currentStep: step);
  }

  Future<void> completeWalkthrough() async {
    state = state.copyWith(
      isActive: false,
      hasCompleted: true,
    );
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  Future<void> skipWalkthrough() async {
    await completeWalkthrough();
  }

  Future<void> restartWalkthrough() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(prefKey);
    state = const OnboardingState(
      isActive: true,
      currentStep: OnboardingStep.chooseLanguage,
      hasCompleted: false,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});
