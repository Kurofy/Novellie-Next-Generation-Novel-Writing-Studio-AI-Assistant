import 'package:flutter/material.dart';

enum AppThemeColor {
  ocean(
    id: 'ocean',
    displayName: 'Ocean Blue',
    description: 'Current signature primary palette',
    previewColor: Color(0xFF2B5F8E),
    isDefault: true,
  ),
  purple(
    id: 'purple',
    displayName: 'Royal Purple',
    description: 'Creative and mystical plum hue',
    previewColor: Color(0xFF5E35B1),
    isDefault: false,
  ),
  green(
    id: 'green',
    displayName: 'Forest Green',
    description: 'Calm and natural evergreen tone',
    previewColor: Color(0xFF2E7D32),
    isDefault: false,
  ),
  red(
    id: 'red',
    displayName: 'Crimson Red',
    description: 'Bold and passionate ruby hue',
    previewColor: Color(0xFFA4262C),
    isDefault: false,
  ),
  amber(
    id: 'amber',
    displayName: 'Warm Amber',
    description: 'Golden radiant warm sunrise tone',
    previewColor: Color(0xFF8F5100),
    isDefault: false,
  ),
  teal(
    id: 'teal',
    displayName: 'Nordic Teal',
    description: 'Serene crisp coastal teal tone',
    previewColor: Color(0xFF00695C),
    isDefault: false,
  );

  const AppThemeColor({
    required this.id,
    required this.displayName,
    required this.description,
    required this.previewColor,
    required this.isDefault,
  });

  final String id;
  final String displayName;
  final String description;
  final Color previewColor;
  final bool isDefault;

  static AppThemeColor fromId(String? id) {
    if (id == null) return AppThemeColor.ocean;
    return AppThemeColor.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AppThemeColor.ocean,
    );
  }
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceSecondary,
    required this.surfaceHigh,
    required this.primarySoft,
    required this.timelineTrack,
    required this.progressTrack,
    required this.outlineVariant,
    required this.primaryFill,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceSecondary;
  final Color surfaceHigh;
  final Color primarySoft;
  final Color timelineTrack;
  final Color progressTrack;
  final Color outlineVariant;
  final Color primaryFill;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;

  static const light = AppColors(
    canvas: Color(0xFFF4F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF8F9F6),
    surfaceSecondary: Color(0xFFEEF1ED),
    surfaceHigh: Color(0xFFE4EAE3),
    primarySoft: Color(0xFFEDF4F8),
    timelineTrack: Color(0xFFEEF1ED),
    progressTrack: Color(0xFFDCEAF5),
    outlineVariant: Color(0xFFC2C7D0),
    primaryFill: Color(0xFF4778A8),
    primary: Color(0xFF2B5F8E),
    primaryPressed: Color(0xFF315C86),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    success: Color(0xFF2E7D5B),
    successContainer: Color(0xFFDDEFE5),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFBEBC8),
  );

  static const dark = AppColors(
    canvas: Color(0xFF151A17),
    surface: Color(0xFF1D231F),
    surfaceSoft: Color(0xFF232A25),
    surfaceSecondary: Color(0xFF2A322C),
    surfaceHigh: Color(0xFF333C35),
    primarySoft: Color(0xFF22303B),
    timelineTrack: Color(0xFF2A322C),
    progressTrack: Color(0xFF2C3A45),
    outlineVariant: Color(0xFF424A44),
    primaryFill: Color(0xFF2563EB),
    primary: Color(0xFF9BCBFF),
    primaryPressed: Color(0xFF1D4ED8),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textMuted: Color(0xFF9CA3AF),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF5C1A17),
    onErrorContainer: Color(0xFFFFB4AB),
    success: Color(0xFF7FD1A5),
    successContainer: Color(0xFF1F3A2E),
    warning: Color(0xFFF0C36B),
    warningContainer: Color(0xFF3F3116),
  );

  static AppColors lightFor([AppThemeColor themeColor = AppThemeColor.ocean]) {
    switch (themeColor) {
      case AppThemeColor.ocean:
        return light;
      case AppThemeColor.purple:
        return light.copyWith(
          primary: const Color(0xFF5E35B1),
          primaryFill: const Color(0xFF5E35B1),
          primaryPressed: const Color(0xFF4527A0),
          primarySoft: const Color(0xFFF3E5F5),
          progressTrack: const Color(0xFFE1BEE7),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.green:
        return light.copyWith(
          primary: const Color(0xFF2E7D32),
          primaryFill: const Color(0xFF2E7D32),
          primaryPressed: const Color(0xFF1B5E20),
          primarySoft: const Color(0xFFE8F5E9),
          progressTrack: const Color(0xFFC8E6C9),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.red:
        return light.copyWith(
          primary: const Color(0xFFA4262C),
          primaryFill: const Color(0xFFA4262C),
          primaryPressed: const Color(0xFF8B1E22),
          primarySoft: const Color(0xFFFFEBEE),
          progressTrack: const Color(0xFFFFCDD2),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.amber:
        return light.copyWith(
          primary: const Color(0xFF8F5100),
          primaryFill: const Color(0xFF8F5100),
          primaryPressed: const Color(0xFF6D3D00),
          primarySoft: const Color(0xFFFFF8E1),
          progressTrack: const Color(0xFFFFE082),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.teal:
        return light.copyWith(
          primary: const Color(0xFF00695C),
          primaryFill: const Color(0xFF00695C),
          primaryPressed: const Color(0xFF004D40),
          primarySoft: const Color(0xFFE0F2F1),
          progressTrack: const Color(0xFFB2DFDB),
          onPrimary: const Color(0xFFFFFFFF),
        );
    }
  }

  static AppColors darkFor([AppThemeColor themeColor = AppThemeColor.ocean]) {
    switch (themeColor) {
      case AppThemeColor.ocean:
        return dark;
      case AppThemeColor.purple:
        return dark.copyWith(
          primary: const Color(0xFFD0BCFF),
          primaryFill: const Color(0xFF7C4DFF),
          primaryPressed: const Color(0xFF651FFF),
          primarySoft: const Color(0xFF381E72),
          progressTrack: const Color(0xFF4F378B),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.green:
        return dark.copyWith(
          primary: const Color(0xFF81C784),
          primaryFill: const Color(0xFF047857),
          primaryPressed: const Color(0xFF065F46),
          primarySoft: const Color(0xFF1B4332),
          progressTrack: const Color(0xFF2D6A4F),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.red:
        return dark.copyWith(
          primary: const Color(0xFFFF8A80),
          primaryFill: const Color(0xFFDC2626),
          primaryPressed: const Color(0xFFB91C1C),
          primarySoft: const Color(0xFF4A181A),
          progressTrack: const Color(0xFF6B2628),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.amber:
        return dark.copyWith(
          primary: const Color(0xFFFFB74D),
          primaryFill: const Color(0xFFB45309),
          primaryPressed: const Color(0xFF92400E),
          primarySoft: const Color(0xFF3E2700),
          progressTrack: const Color(0xFF5D3900),
          onPrimary: const Color(0xFFFFFFFF),
        );
      case AppThemeColor.teal:
        return dark.copyWith(
          primary: const Color(0xFF4DB6AC),
          primaryFill: const Color(0xFF0F766E),
          primaryPressed: const Color(0xFF115E59),
          primarySoft: const Color(0xFF003737),
          progressTrack: const Color(0xFF004D4D),
          onPrimary: const Color(0xFFFFFFFF),
        );
    }
  }

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceSecondary,
    Color? surfaceHigh,
    Color? primarySoft,
    Color? timelineTrack,
    Color? progressTrack,
    Color? outlineVariant,
    Color? primaryFill,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      primarySoft: primarySoft ?? this.primarySoft,
      timelineTrack: timelineTrack ?? this.timelineTrack,
      progressTrack: progressTrack ?? this.progressTrack,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primaryFill: primaryFill ?? this.primaryFill,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t) ?? surfaceSoft,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ??
              surfaceSecondary,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t) ?? surfaceHigh,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      timelineTrack:
          Color.lerp(timelineTrack, other.timelineTrack, t) ?? timelineTrack,
      progressTrack:
          Color.lerp(progressTrack, other.progressTrack, t) ?? progressTrack,
      outlineVariant:
          Color.lerp(outlineVariant, other.outlineVariant, t) ?? outlineVariant,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t) ?? primaryFill,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      error: Color.lerp(error, other.error, t) ?? error,
      errorContainer:
          Color.lerp(errorContainer, other.errorContainer, t) ?? errorContainer,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t) ??
              onErrorContainer,
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
              successContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
              warningContainer,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
