import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

ThemeData buildTheme(
  Brightness brightness, [
  AppThemeColor themeColor = AppThemeColor.ocean,
]) {
  final isDark = brightness == Brightness.dark;
  final c =
      isDark ? AppColors.darkFor(themeColor) : AppColors.lightFor(themeColor);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primaryFill,
    onPrimary: c.onPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.textPrimary,
    secondary: c.primary,
    onSecondary: c.onPrimary,
    secondaryContainer: c.surfaceSecondary,
    onSecondaryContainer: c.textPrimary,
    error: c.error,
    onError: c.canvas,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surfaceSoft,
    surfaceContainer: c.surfaceSecondary,
    surfaceContainerHigh: c.surfaceHigh,
    outline: c.textSecondary,
    outlineVariant: c.outlineVariant,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    fontFamily: 'Signika',
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      foregroundColor: c.textPrimary,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineHero,
      displayMedium: AppTypography.headlineHeroMobile,
      displaySmall: AppTypography.screenTitle,
      headlineLarge: AppTypography.headlineHero,
      headlineMedium: AppTypography.screenTitle,
      headlineSmall: AppTypography.manuscriptHeading,
      titleLarge: AppTypography.sectionTitle,
      titleMedium: AppTypography.cardTitle,
      titleSmall: AppTypography.cardTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.bodySm,
      labelLarge: AppTypography.cardTitle,
      labelMedium: AppTypography.labelMd,
      labelSmall: AppTypography.labelSm,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      titleTextStyle: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
      contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      hintStyle: AppTypography.body.copyWith(color: c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.outlineVariant,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primaryFill,
      foregroundColor: c.onPrimary,
      elevation: 4,
      focusElevation: 4,
      hoverElevation: 6,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceSecondary,
      selectedColor: c.primarySoft,
      checkmarkColor: c.textPrimary,
      iconTheme: IconThemeData(color: c.textPrimary, size: 16),
      labelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: c.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w500,
        );
      }),
      secondaryLabelStyle: TextStyle(
        color: c.primary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primarySoft;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.textPrimary;
          }
          return c.textSecondary;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.textPrimary;
          }
          return c.textSecondary;
        }),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return c.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.resolveWith((states) {
        return c.onPrimary;
      }),
      side: BorderSide(color: c.outlineVariant, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(),
  );
}
