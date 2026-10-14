import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double x2 = 24;
  static const double x3 = 32;
  static const double x4 = 40;
  static const double x5 = 48;

  static double screenMargin(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 375 ? lg : xl;
}
