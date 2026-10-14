import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AppEditorTypography {
  static const defaultFontSize = 16.0;
  static const defaultFontFamily = 'Signika';

  static const availableFontFamilies = <String>[
    'Signika',
    'Serif',
    'Sans-Serif',
    'Monospace',
  ];

  static TextStyle resolveTextStyle({
    required double fontSize,
    required String fontFamily,
    Color? color,
    double? height,
  }) {
    List<String>? fallback;
    String actualFamily;

    switch (fontFamily.toLowerCase()) {
      case 'serif':
        actualFamily = 'Georgia';
        fallback = const ['Times New Roman', 'Palatino', 'serif'];
        break;
      case 'sans-serif':
        actualFamily = 'Segoe UI';
        fallback = const [
          'Roboto',
          'San Francisco',
          'Helvetica Neue',
          'sans-serif',
        ];
        break;
      case 'monospace':
        actualFamily = 'Consolas';
        fallback = const ['Courier New', 'Menlo', 'monospace'];
        break;
      case 'signika':
      default:
        actualFamily = 'Signika';
        fallback = const ['Segoe UI', 'Roboto', 'sans-serif'];
        break;
    }

    return TextStyle(
      fontSize: fontSize,
      fontFamily: actualFamily,
      fontFamilyFallback: fallback,
      color: color,
      height: height ?? 1.6,
    );
  }

  static DefaultStyles buildQuillStyles(
    BuildContext context, {
    required double fontSize,
    required String fontFamily,
    Color? textColor,
  }) {
    final base = DefaultStyles.getInstance(context);
    final textStyle = resolveTextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      color: textColor,
    );

    return base.merge(
      DefaultStyles(
        paragraph: DefaultTextBlockStyle(
          textStyle,
          base.paragraph?.horizontalSpacing ?? const HorizontalSpacing(0, 0),
          base.paragraph?.verticalSpacing ?? const VerticalSpacing(0, 0),
          base.paragraph?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.paragraph?.decoration,
        ),
        placeHolder: DefaultTextBlockStyle(
          textStyle.copyWith(
            color: (textColor ?? Colors.grey).withValues(alpha: 0.6),
          ),
          base.placeHolder?.horizontalSpacing ?? const HorizontalSpacing(0, 0),
          base.placeHolder?.verticalSpacing ?? const VerticalSpacing(0, 0),
          base.placeHolder?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.placeHolder?.decoration,
        ),
        h1: DefaultTextBlockStyle(
          textStyle.copyWith(
            fontSize: fontSize * 1.6,
            fontWeight: FontWeight.bold,
          ),
          base.h1?.horizontalSpacing ?? const HorizontalSpacing(0, 0),
          base.h1?.verticalSpacing ?? const VerticalSpacing(16, 8),
          base.h1?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.h1?.decoration,
        ),
        h2: DefaultTextBlockStyle(
          textStyle.copyWith(
            fontSize: fontSize * 1.35,
            fontWeight: FontWeight.bold,
          ),
          base.h2?.horizontalSpacing ?? const HorizontalSpacing(0, 0),
          base.h2?.verticalSpacing ?? const VerticalSpacing(12, 6),
          base.h2?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.h2?.decoration,
        ),
        h3: DefaultTextBlockStyle(
          textStyle.copyWith(
            fontSize: fontSize * 1.15,
            fontWeight: FontWeight.w600,
          ),
          base.h3?.horizontalSpacing ?? const HorizontalSpacing(0, 0),
          base.h3?.verticalSpacing ?? const VerticalSpacing(8, 4),
          base.h3?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.h3?.decoration,
        ),
        lists: base.lists != null
            ? DefaultListBlockStyle(
                textStyle,
                base.lists!.horizontalSpacing,
                base.lists!.verticalSpacing,
                base.lists!.lineSpacing,
                base.lists!.decoration,
                base.lists!.checkboxUIBuilder,
              )
            : null,
        quote: DefaultTextBlockStyle(
          textStyle.copyWith(fontStyle: FontStyle.italic),
          base.quote?.horizontalSpacing ?? const HorizontalSpacing(16, 0),
          base.quote?.verticalSpacing ?? const VerticalSpacing(6, 6),
          base.quote?.lineSpacing ?? const VerticalSpacing(0, 0),
          base.quote?.decoration,
        ),
      ),
    );
  }
}
