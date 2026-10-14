import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const _family = 'Signika';

  static TextStyle _s(double size, double lineHeight, FontWeight w) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: w,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static final headlineHero = _s(32, 40, FontWeight.w600);
  static final headlineHeroMobile = _s(28, 36, FontWeight.w600);
  static final screenTitle = _s(24, 32, FontWeight.w600);
  static final sectionTitle = _s(18, 24, FontWeight.w600);
  static final cardTitle = _s(16, 22, FontWeight.w600);
  static final body = _s(15, 24, FontWeight.w400);
  static final bodySm = _s(13, 20, FontWeight.w400);
  static final labelMd = _s(12, 16, FontWeight.w500);
  static final labelSm = _s(11, 14, FontWeight.w400);
  static final manuscriptHeading = _s(20, 28, FontWeight.w600);
  static final numeric = _s(28, 32, FontWeight.w600)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
