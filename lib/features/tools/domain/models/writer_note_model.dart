import 'package:flutter/material.dart';

/// Preset color palette for writer notes, inspired by Google Keep.
enum NoteColorPreset {
  defaultColor(
    id: 'default',
    name: 'Default',
    lightColor: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1E293B),
    lightBorder: Color(0xFFE2E8F0),
    darkBorder: Color(0xFF334155),
  ),
  amber(
    id: 'amber',
    name: 'Warm Sun',
    lightColor: Color(0xFFFEF3C7),
    darkColor: Color(0xFF451A03),
    lightBorder: Color(0xFFFDE68A),
    darkBorder: Color(0xFF78350F),
  ),
  peach(
    id: 'peach',
    name: 'Peach Orange',
    lightColor: Color(0xFFFFEDD5),
    darkColor: Color(0xFF431407),
    lightBorder: Color(0xFFFED7AA),
    darkBorder: Color(0xFF7C2D12),
  ),
  coral(
    id: 'coral',
    name: 'Coral Red',
    lightColor: Color(0xFFFFE4E6),
    darkColor: Color(0xFF4C0519),
    lightBorder: Color(0xFFFECDD3),
    darkBorder: Color(0xFF881337),
  ),
  rose(
    id: 'rose',
    name: 'Blush Pink',
    lightColor: Color(0xFFFCE7F3),
    darkColor: Color(0xFF500724),
    lightBorder: Color(0xFFFBCFE8),
    darkBorder: Color(0xFF831843),
  ),
  lavender(
    id: 'lavender',
    name: 'Lavender Purple',
    lightColor: Color(0xFFF3E8FF),
    darkColor: Color(0xFF3B0764),
    lightBorder: Color(0xFFE9D5FF),
    darkBorder: Color(0xFF581C87),
  ),
  sky(
    id: 'sky',
    name: 'Sky Blue',
    lightColor: Color(0xFFE0F2FE),
    darkColor: Color(0xFF082F49),
    lightBorder: Color(0xFFBAE6FD),
    darkBorder: Color(0xFF0369A1),
  ),
  teal(
    id: 'teal',
    name: 'Teal Lake',
    lightColor: Color(0xFFCCFBF1),
    darkColor: Color(0xFF042F2C),
    lightBorder: Color(0xFF99F6E4),
    darkBorder: Color(0xFF0F766E),
  ),
  mint(
    id: 'mint',
    name: 'Mint Green',
    lightColor: Color(0xFFDCFCE7),
    darkColor: Color(0xFF064E3B),
    lightBorder: Color(0xFFBBF7D0),
    darkBorder: Color(0xFF047857),
  ),
  graphite(
    id: 'graphite',
    name: 'Graphite Slate',
    lightColor: Color(0xFFF1F5F9),
    darkColor: Color(0xFF0F172A),
    lightBorder: Color(0xFFCBD5E1),
    darkBorder: Color(0xFF1E293B),
  );

  const NoteColorPreset({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.lightBorder,
    required this.darkBorder,
  });

  final String id;
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color lightBorder;
  final Color darkBorder;

  Color resolveBackground(bool isDark) => isDark ? darkColor : lightColor;
  Color resolveBorder(bool isDark) => isDark ? darkBorder : lightBorder;

  String localizedName([bool isIndo = false]) {
    if (!isIndo) return name;
    switch (this) {
      case NoteColorPreset.defaultColor:
        return 'Standar';
      case NoteColorPreset.amber:
        return 'Kuning Hangat';
      case NoteColorPreset.peach:
        return 'Oranye Persik';
      case NoteColorPreset.coral:
        return 'Merah Karang';
      case NoteColorPreset.rose:
        return 'Merah Muda';
      case NoteColorPreset.lavender:
        return 'Ungu Lavender';
      case NoteColorPreset.sky:
        return 'Biru Langit';
      case NoteColorPreset.teal:
        return 'Hijau Toska';
      case NoteColorPreset.mint:
        return 'Hijau Mint';
      case NoteColorPreset.graphite:
        return 'Abu Grafit';
    }
  }

  static NoteColorPreset fromId(String? id) {
    if (id == null) return NoteColorPreset.defaultColor;
    return NoteColorPreset.values.firstWhere(
      (e) => e.id == id,
      orElse: () => NoteColorPreset.defaultColor,
    );
  }
}

/// A checklist item within a note.
class NoteChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const NoteChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  NoteChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return NoteChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory NoteChecklistItem.fromJson(Map<String, dynamic> json) {
    return NoteChecklistItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

/// A writer's note model in Tools, inspired by Google Keep.
class WriterNote {
  final String id;
  final String? novelId; // Associated novel ID or null for global note
  final String? novelTitle; // Cached novel title for display
  final String title;
  final String content;
  final bool isPinned;
  final bool isArchived;
  final String colorId; // Matches NoteColorPreset.id
  final List<String> labels; // e.g. ["#Plot", "#Lore", "#Dialogue"]
  final List<NoteChecklistItem> checklist;
  final bool isChecklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WriterNote({
    required this.id,
    this.novelId,
    this.novelTitle,
    required this.title,
    this.content = '',
    this.isPinned = false,
    this.isArchived = false,
    this.colorId = 'default',
    this.labels = const [],
    this.checklist = const [],
    this.isChecklist = false,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteColorPreset get colorPreset => NoteColorPreset.fromId(colorId);

  bool get isEmpty =>
      title.trim().isEmpty &&
      content.trim().isEmpty &&
      (checklist.isEmpty || checklist.every((item) => item.text.trim().isEmpty));

  WriterNote copyWith({
    String? id,
    String? novelId,
    String? novelTitle,
    String? title,
    String? content,
    bool? isPinned,
    bool? isArchived,
    String? colorId,
    List<String>? labels,
    List<NoteChecklistItem>? checklist,
    bool? isChecklist,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WriterNote(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      novelTitle: novelTitle ?? this.novelTitle,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      colorId: colorId ?? this.colorId,
      labels: labels ?? this.labels,
      checklist: checklist ?? this.checklist,
      isChecklist: isChecklist ?? this.isChecklist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'novelId': novelId,
        'novelTitle': novelTitle,
        'title': title,
        'content': content,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'colorId': colorId,
        'labels': labels,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'isChecklist': isChecklist,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WriterNote.fromJson(Map<String, dynamic> json) {
    return WriterNote(
      id: json['id'] as String? ?? '',
      novelId: json['novelId'] as String?,
      novelTitle: json['novelTitle'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      colorId: json['colorId'] as String? ?? 'default',
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => NoteChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isChecklist: json['isChecklist'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
