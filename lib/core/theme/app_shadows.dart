import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0D202622), offset: Offset(0, 6), blurRadius: 20),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0A202622), offset: Offset(0, 2), blurRadius: 10),
  ];
  static const floating = [
    BoxShadow(color: Color(0x14202622), offset: Offset(0, 8), blurRadius: 24),
  ];
  static const navigation = [
    BoxShadow(color: Color(0x0F202622), offset: Offset(0, -4), blurRadius: 20),
  ];
  static const appBar = [
    BoxShadow(color: Color(0x0A202622), offset: Offset(0, 1), blurRadius: 8),
  ];

  /// Shadows are not used in dark mode; elevation is tonal (design.md §3.4).
  static List<BoxShadow> resolve(BuildContext context, List<BoxShadow> light) =>
      Theme.of(context).brightness == Brightness.dark ? const [] : light;
}
