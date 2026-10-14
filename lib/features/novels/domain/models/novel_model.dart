import '../../../../l10n/app_localizations.dart';

enum NovelStatus {
  idea,
  planning,
  drafting,
  revising,
  completed,
  onHold;

  String get label {
    switch (this) {
      case NovelStatus.idea:
        return 'Idea';
      case NovelStatus.planning:
        return 'Planning';
      case NovelStatus.drafting:
        return 'Drafting';
      case NovelStatus.revising:
        return 'Revising';
      case NovelStatus.completed:
        return 'Completed';
      case NovelStatus.onHold:
        return 'On Hold';
    }
  }

  String getLabel([AppLocalizations? l10n]) {
    if (l10n != null) {
      switch (this) {
        case NovelStatus.idea:
          return l10n.statusIdea;
        case NovelStatus.planning:
          return l10n.statusPlanning;
        case NovelStatus.drafting:
          return l10n.statusDrafting;
        case NovelStatus.revising:
          return l10n.statusRevising;
        case NovelStatus.completed:
          return l10n.statusCompleted;
        case NovelStatus.onHold:
          return l10n.statusOnHold;
      }
    }
    return label;
  }

  static NovelStatus fromString(String? value) {
    if (value == null) return NovelStatus.idea;
    return NovelStatus.values.firstWhere(
      (e) =>
          e.name == value ||
          e.name.toLowerCase() == value.replaceAll('_', '').toLowerCase(),
      orElse: () => NovelStatus.idea,
    );
  }
}

class NovelModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? author;
  final String? coverPath;
  final String? description;
  final String? genre;
  final NovelStatus status;
  final String language;
  final String? pov;
  final String? tense;
  final String? dialogueStyle;
  final String? quotationStyle;
  final int? chapterWordTarget;
  final int? novelWordTarget;
  final bool aiContextAllowed;
  final int totalWordCount;
  final int chapterCount;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  const NovelModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.author,
    this.coverPath,
    this.description,
    this.genre,
    this.status = NovelStatus.idea,
    this.language = 'en',
    this.pov,
    this.tense,
    this.dialogueStyle,
    this.quotationStyle,
    this.chapterWordTarget,
    this.novelWordTarget,
    this.aiContextAllowed = false,
    this.totalWordCount = 0,
    this.chapterCount = 0,
    this.lastOpenedAt,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });

  NovelModel copyWith({
    String? title,
    String? subtitle,
    String? author,
    String? coverPath,
    String? description,
    String? genre,
    NovelStatus? status,
    String? language,
    String? pov,
    String? tense,
    String? dialogueStyle,
    String? quotationStyle,
    int? chapterWordTarget,
    int? novelWordTarget,
    bool? aiContextAllowed,
    int? totalWordCount,
    int? chapterCount,
    DateTime? lastOpenedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
  }) {
    return NovelModel(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      language: language ?? this.language,
      pov: pov ?? this.pov,
      tense: tense ?? this.tense,
      dialogueStyle: dialogueStyle ?? this.dialogueStyle,
      quotationStyle: quotationStyle ?? this.quotationStyle,
      chapterWordTarget: chapterWordTarget ?? this.chapterWordTarget,
      novelWordTarget: novelWordTarget ?? this.novelWordTarget,
      aiContextAllowed: aiContextAllowed ?? this.aiContextAllowed,
      totalWordCount: totalWordCount ?? this.totalWordCount,
      chapterCount: chapterCount ?? this.chapterCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
