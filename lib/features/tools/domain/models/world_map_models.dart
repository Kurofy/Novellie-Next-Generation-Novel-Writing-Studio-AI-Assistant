import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Categories for map markers with visual styling and icons.
enum MapPinCategory {
  settlement('Settlement', Symbols.location_city, Color(0xFFD97706)),
  capital('Capital City', Symbols.castle, Color(0xFF7C3AED)),
  dungeon('Dungeon / Cave', Symbols.skull, Color(0xFFDC2626)),
  battlefield('Battlefield', Symbols.swords, Color(0xFFEA580C)),
  landmark('Landmark', Symbols.landscape, Color(0xFF059669)),
  ruin('Ancient Ruins', Symbols.temple_buddhist, Color(0xFF0891B2)),
  port('Port / Harbor', Symbols.sailing, Color(0xFF2563EB)),
  custom('Point of Interest', Symbols.pin_drop, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;

  const MapPinCategory(this.label, this.icon, this.color);

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case MapPinCategory.settlement:
        return 'Pemukiman';
      case MapPinCategory.capital:
        return 'Ibu Kota';
      case MapPinCategory.dungeon:
        return 'Dungeon / Gua';
      case MapPinCategory.battlefield:
        return 'Medan Tempur';
      case MapPinCategory.landmark:
        return 'Markah Tanah';
      case MapPinCategory.ruin:
        return 'Reruntuhan Kuno';
      case MapPinCategory.port:
        return 'Pelabuhan';
      case MapPinCategory.custom:
        return 'Titik Menarik';
    }
  }

  static MapPinCategory fromString(String? val) {
    if (val == null) return MapPinCategory.custom;
    return MapPinCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => MapPinCategory.custom,
    );
  }
}

/// A pin placed on a [WorldMap] with normalized coordinates (0.0 to 1.0).
class MapPin {
  final String id;
  final String novelId;
  final String mapId;
  final String title;
  final String? description;
  final MapPinCategory category;

  /// Normalized X coordinate (0.0 .. 1.0) relative to the map canvas width.
  final double x;

  /// Normalized Y coordinate (0.0 .. 1.0) relative to the map canvas height.
  final double y;

  /// Linked Codex / World Entry ID (from WorldEntryModel).
  final String? linkedEntryId;

  /// Linked Character IDs (characters born or residing at this location).
  final List<String> linkedCharacterIds;

  /// Linked Chapter IDs (chapters featuring events or scenes at this location).
  final List<String> linkedChapterIds;

  final Map<String, dynamic> customMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MapPin({
    required this.id,
    required this.novelId,
    required this.mapId,
    required this.title,
    this.description,
    this.category = MapPinCategory.custom,
    required this.x,
    required this.y,
    this.linkedEntryId,
    this.linkedCharacterIds = const [],
    this.linkedChapterIds = const [],
    this.customMetadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  MapPin copyWith({
    String? id,
    String? novelId,
    String? mapId,
    String? title,
    String? description,
    MapPinCategory? category,
    double? x,
    double? y,
    String? linkedEntryId,
    List<String>? linkedCharacterIds,
    List<String>? linkedChapterIds,
    Map<String, dynamic>? customMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MapPin(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      mapId: mapId ?? this.mapId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      x: x ?? this.x,
      y: y ?? this.y,
      linkedEntryId: linkedEntryId ?? this.linkedEntryId,
      linkedCharacterIds: linkedCharacterIds ?? this.linkedCharacterIds,
      linkedChapterIds: linkedChapterIds ?? this.linkedChapterIds,
      customMetadata: customMetadata ?? this.customMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'novelId': novelId,
      'mapId': mapId,
      'title': title,
      'description': description,
      'category': category.name,
      'x': x,
      'y': y,
      'linkedEntryId': linkedEntryId,
      'linkedCharacterIds': linkedCharacterIds,
      'linkedChapterIds': linkedChapterIds,
      'customMetadata': customMetadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MapPin.fromJson(Map<String, dynamic> json) {
    return MapPin(
      id: json['id'] as String? ?? '',
      novelId: json['novelId'] as String? ?? '',
      mapId: json['mapId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Pin',
      description: json['description'] as String?,
      category: MapPinCategory.fromString(json['category'] as String?),
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      linkedEntryId: json['linkedEntryId'] as String?,
      linkedCharacterIds: (json['linkedCharacterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      linkedChapterIds: (json['linkedChapterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      customMetadata: (json['customMetadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Represents a vector World Map with dimensions and pins.
class WorldMap {
  final String id;
  final String novelId;
  final String title;
  final String? description;
  final String svgContent;
  final double width;
  final double height;
  final List<MapPin> pins;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldMap({
    required this.id,
    required this.novelId,
    required this.title,
    this.description,
    required this.svgContent,
    required this.width,
    required this.height,
    this.pins = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  WorldMap copyWith({
    String? id,
    String? novelId,
    String? title,
    String? description,
    String? svgContent,
    double? width,
    double? height,
    List<MapPin>? pins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorldMap(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      title: title ?? this.title,
      description: description ?? this.description,
      svgContent: svgContent ?? this.svgContent,
      width: width ?? this.width,
      height: height ?? this.height,
      pins: pins ?? this.pins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'novelId': novelId,
      'title': title,
      'description': description,
      'svgContent': svgContent,
      'width': width,
      'height': height,
      'pins': pins.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns SVG markup sanitized and normalized for flutter_svg vector rendering.
  String get sanitizedSvgContent => SvgSanitizer.sanitize(
        svgContent,
        width: width,
        height: height,
      );

  factory WorldMap.fromJson(Map<String, dynamic> json) {
    final width = (json['width'] as num?)?.toDouble() ?? 1600.0;
    final height = (json['height'] as num?)?.toDouble() ?? 1000.0;
    final rawSvg = json['svgContent'] as String? ?? '';
    return WorldMap(
      id: json['id'] as String? ?? '',
      novelId: json['novelId'] as String? ?? '',
      title: json['title'] as String? ?? 'Realm Map',
      description: json['description'] as String?,
      svgContent: SvgSanitizer.sanitize(rawSvg, width: width, height: height),
      width: width,
      height: height,
      pins: (json['pins'] as List<dynamic>?)
              ?.map((p) => MapPin.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Helper to parse SVG viewBox or dimensions.
class SvgDimensionParser {
  static Size parse(String svgContent, {Size fallback = const Size(1600, 1000)}) {
    // 1. Try viewBox: viewBox="0 0 1920 1080" or viewBox="0,0,1920,1080"
    final viewBoxRegex = RegExp(
      r'viewBox=["\x27]\s*(-?[\d.]+)[,\s]+(-?[\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)["\x27]',
      caseSensitive: false,
    );
    final vbMatch = viewBoxRegex.firstMatch(svgContent);
    if (vbMatch != null) {
      final w = double.tryParse(vbMatch.group(3) ?? '');
      final h = double.tryParse(vbMatch.group(4) ?? '');
      if (w != null && h != null && w > 0 && h > 0) {
        return Size(w, h);
      }
    }

    // 2. Try width & height attributes
    final widthRegex = RegExp(
      r'<svg[^>]*\bwidth=["\x27]([\d.]+)p?x?["\x27]',
      caseSensitive: false,
    );
    final heightRegex = RegExp(
      r'<svg[^>]*\bheight=["\x27]([\d.]+)p?x?["\x27]',
      caseSensitive: false,
    );
    final wMatch = widthRegex.firstMatch(svgContent);
    final hMatch = heightRegex.firstMatch(svgContent);

    if (wMatch != null && hMatch != null) {
      final w = double.tryParse(wMatch.group(1) ?? '');
      final h = double.tryParse(hMatch.group(1) ?? '');
      if (w != null && h != null && w > 0 && h > 0) {
        return Size(w, h);
      }
    }

    return fallback;
  }
}

/// Sanitizes and normalizes SVG vector markup for compatibility with
/// flutter_svg and vector_graphics_compiler.
///
/// Converts unsupported percentage font sizes (e.g. `font-size: 0.7%` common
/// in Azgaar Fantasy Map Generator exports), relative keywords, and removes
/// `!important` modifiers that cause flutter_svg parser crashes.
class SvgSanitizer {
  static String sanitize(String rawSvg, {double? width, double? height}) {
    if (rawSvg.trim().isEmpty) return rawSvg;

    var sanitized = rawSvg;

    // 1. Remove UTF-8 BOM if present
    if (sanitized.startsWith('\uFEFF')) {
      sanitized = sanitized.substring(1);
    }

    // 2. Strip script tags (scripts may contain JS and crash/warn in vector parser)
    sanitized = sanitized.replaceAll(
      RegExp(r'<script\b[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
      '',
    );

    // 3. Resolve canvas dimensions for proportional calculations
    double refWidth = (width != null && width > 0) ? width : 0;
    double refHeight = (height != null && height > 0) ? height : 0;

    if (refWidth <= 0 || refHeight <= 0) {
      final parsedSize = SvgDimensionParser.parse(sanitized);
      if (refWidth <= 0) refWidth = parsedSize.width;
      if (refHeight <= 0) refHeight = parsedSize.height;
    }
    if (refWidth <= 0) refWidth = 1600.0;
    if (refHeight <= 0) refHeight = 1000.0;

    // 4. Sanitize font-size in CSS property declarations (both <style> and style="")
    final cssFontSizeRegex = RegExp(
      r'font-size\s*:\s*([^;}"\x27\r\n]+)',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(cssFontSizeRegex, (match) {
      final rawVal = match.group(1)?.trim() ?? '';
      final converted = _convertFontSizeValue(rawVal, refWidth, refHeight);
      return 'font-size: $converted';
    });

    // 5. Sanitize font-size in SVG XML attributes: font-size="..." or font-size='...'
    final attrFontSizeRegex = RegExp(
      r'\bfont-size\s*=\s*(["\x27])(.*?)\1',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(attrFontSizeRegex, (match) {
      final quote = match.group(1) ?? '"';
      final rawVal = match.group(2)?.trim() ?? '';
      final converted = _convertFontSizeValue(rawVal, refWidth, refHeight);
      return 'font-size=$quote$converted$quote';
    });

    // 6. Strip `!important` across CSS styles (vector_graphics_compiler cannot parse !important)
    sanitized = sanitized.replaceAll(
      RegExp(r'\s*!important', caseSensitive: false),
      '',
    );

    return sanitized;
  }

  static String _convertFontSizeValue(
    String raw,
    double refWidth,
    double refHeight,
  ) {
    final val = raw.replaceAll(RegExp(r'\s*!important', caseSensitive: false), '').trim();

    // Check for percentage (e.g., "0.7%", "0.7 %", "1.2%", "100%", ".7%")
    final percentMatch = RegExp(r'^([+-]?[0-9.]*)\s*%$').firstMatch(val);
    if (percentMatch != null) {
      final rawNum = percentMatch.group(1);
      final percent = double.tryParse(rawNum ?? '');
      if (percent != null) {
        final px = _calculatePercentPx(percent, refWidth, refHeight);
        return _formatPx(px);
      }
    }

    // Check for unsupported relative keywords in vector_graphics_compiler
    final lower = val.toLowerCase();
    switch (lower) {
      case 'smaller':
        return _formatPx(11.2);
      case 'larger':
        return _formatPx(16.8);
      case 'inherit':
      case 'initial':
      case 'unset':
        return _formatPx(14.0);
    }

    // If unitless number string, format to explicit px
    final numOnly = RegExp(r'^[+-]?[0-9.]+$').firstMatch(val);
    if (numOnly != null) {
      final n = double.tryParse(val);
      if (n != null) {
        return _formatPx(n);
      }
    }

    return val;
  }

  static double _calculatePercentPx(
    double percent,
    double refWidth,
    double refHeight,
  ) {
    if (percent <= 10.0) {
      // Cartographic maps (Azgaar / GIS) use small percentages (e.g., 0.5% - 5.0%)
      // relative to map canvas width/viewBox. E.g., 0.7% of 1600 = 11.2px
      final px = (percent / 100.0) * refWidth;
      return px.clamp(4.0, 300.0);
    } else {
      // Standard CSS font-size percentages (e.g. 80%, 100%, 120%) relative to base 14px
      final px = (percent / 100.0) * 14.0;
      return px.clamp(4.0, 300.0);
    }
  }

  static String _formatPx(double px) {
    final fixed = px.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '${fixed}px';
  }
}
