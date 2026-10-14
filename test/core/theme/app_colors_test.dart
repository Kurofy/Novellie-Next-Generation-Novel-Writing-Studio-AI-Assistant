import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/core/theme/theme.dart';

double _luminance(Color c) {
  // Relative luminance per WCAG 2.0
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppColors Contrast Verification', () {
    test('Light theme contrast passes WCAG AA for essential text', () {
      const c = AppColors.light;
      // textPrimary on surface >= 4.5:1
      expect(
        _contrastRatio(c.textPrimary, c.surface),
        greaterThanOrEqualTo(4.5),
      );
      // textPrimary on canvas >= 4.5:1
      expect(
        _contrastRatio(c.textPrimary, c.canvas),
        greaterThanOrEqualTo(4.5),
      );
      // textSecondary on surface >= 4.5:1
      expect(
        _contrastRatio(c.textSecondary, c.surface),
        greaterThanOrEqualTo(4.5),
      );
      // onPrimary on primaryFill >= 4.5:1
      expect(
        _contrastRatio(c.onPrimary, c.primaryFill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('Dark theme contrast passes WCAG AA for essential text', () {
      const c = AppColors.dark;
      // textPrimary on surface >= 4.5:1
      expect(
        _contrastRatio(c.textPrimary, c.surface),
        greaterThanOrEqualTo(4.5),
      );
      // textSecondary on surface >= 4.5:1
      expect(
        _contrastRatio(c.textSecondary, c.surface),
        greaterThanOrEqualTo(4.5),
      );
      // onPrimary on primaryFill >= 4.5:1
      expect(
        _contrastRatio(c.onPrimary, c.primaryFill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('All theme color palettes pass WCAG AA onPrimary contrast in light mode', () {
      for (final themeColor in AppThemeColor.values) {
        final colors = AppColors.lightFor(themeColor);
        expect(
          _contrastRatio(colors.onPrimary, colors.primaryFill),
          greaterThanOrEqualTo(4.5),
          reason: '${themeColor.displayName} light onPrimary contrast failed',
        );
      }
    });

    test('All theme color palettes pass WCAG AA onPrimary contrast in dark mode', () {
      for (final themeColor in AppThemeColor.values) {
        final colors = AppColors.darkFor(themeColor);
        expect(
          _contrastRatio(colors.onPrimary, colors.primaryFill),
          greaterThanOrEqualTo(4.5),
          reason: '${themeColor.displayName} dark onPrimary contrast failed',
        );
      }
    });

    test('All theme color palettes pass WCAG AA for primary text on primarySoft in both light and dark modes', () {
      for (final themeColor in AppThemeColor.values) {
        final lightColors = AppColors.lightFor(themeColor);
        expect(
          _contrastRatio(lightColors.primary, lightColors.primarySoft),
          greaterThanOrEqualTo(4.5),
          reason: '${themeColor.displayName} light primary on primarySoft contrast failed',
        );

        final darkColors = AppColors.darkFor(themeColor);
        expect(
          _contrastRatio(darkColors.primary, darkColors.primarySoft),
          greaterThanOrEqualTo(4.5),
          reason: '${themeColor.displayName} dark primary on primarySoft contrast failed',
        );
      }
    });

    test('Chip theme has readable text colors in both light and dark modes', () {
      final lightTheme = buildTheme(Brightness.light);
      final darkTheme = buildTheme(Brightness.dark);

      final lightChipTheme = lightTheme.chipTheme;
      final darkChipTheme = darkTheme.chipTheme;

      // In light mode, selected label must NOT be white / onPrimary
      expect(lightChipTheme.secondaryLabelStyle?.color, isNot(equals(const Color(0xFFFFFFFF))));
      expect(lightChipTheme.secondaryLabelStyle?.color, equals(AppColors.light.primary));

      // In dark mode, selected label must NOT be dark / onPrimary
      expect(darkChipTheme.secondaryLabelStyle?.color, isNot(equals(AppColors.dark.onPrimary)));
      expect(darkChipTheme.secondaryLabelStyle?.color, equals(AppColors.dark.primary));

      // Check WidgetState resolving on labelStyle
      final selectedState = {WidgetState.selected};
      final unselectedState = <WidgetState>{};

      final lightSelected = (lightChipTheme.labelStyle as WidgetStateTextStyle).resolve(selectedState);
      final lightUnselected = (lightChipTheme.labelStyle as WidgetStateTextStyle).resolve(unselectedState);
      expect(lightSelected.color, equals(AppColors.light.primary));
      expect(lightUnselected.color, equals(AppColors.light.textPrimary));

      final darkSelected = (darkChipTheme.labelStyle as WidgetStateTextStyle).resolve(selectedState);
      final darkUnselected = (darkChipTheme.labelStyle as WidgetStateTextStyle).resolve(unselectedState);
      expect(darkSelected.color, equals(AppColors.dark.primary));
      expect(darkUnselected.color, equals(AppColors.dark.textPrimary));
    });
  });
}
