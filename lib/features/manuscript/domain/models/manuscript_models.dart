enum ChapterStatus {
  planned,
  drafting,
  drafted,
  revised,
  complete;

  String get label {
    switch (this) {
      case ChapterStatus.planned:
        return 'Planned';
      case ChapterStatus.drafting:
        return 'Drafting';
      case ChapterStatus.drafted:
        return 'Drafted';
      case ChapterStatus.revised:
        return 'Revised';
      case ChapterStatus.complete:
        return 'Complete';
    }
  }

  static ChapterStatus fromString(String? value) {
    if (value == null) return ChapterStatus.planned;
    return ChapterStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChapterStatus.planned,
    );
  }
}

class VolumeModel {
  final String id;
  final String novelId;
  final String title;
  final String? description;
  final int position;
  final bool collapsed;

  const VolumeModel({
    required this.id,
    required this.novelId,
    required this.title,
    this.description,
    required this.position,
    this.collapsed = false,
  });
}

class ArcModel {
  final String id;
  final String novelId;
  final String volumeId;
  final String title;
  final String? description;
  final int position;
  final bool collapsed;

  const ArcModel({
    required this.id,
    required this.novelId,
    required this.volumeId,
    required this.title,
    this.description,
    required this.position,
    this.collapsed = false,
  });
}

class ChapterModel {
  final String id;
  final String novelId;
  final String arcId;
  final String title;
  final int position;
  final int sequenceNumber;
  final ChapterStatus status;
  final int wordCount;
  final String? summary;
  final String? authorNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChapterModel({
    required this.id,
    required this.novelId,
    required this.arcId,
    required this.title,
    required this.position,
    required this.sequenceNumber,
    this.status = ChapterStatus.planned,
    this.wordCount = 0,
    this.summary,
    this.authorNote,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle =>
      title.isNotEmpty ? title : 'Chapter $sequenceNumber';
}

class ChapterContentModel {
  final String chapterId;
  final String deltaJson;
  final String plainText;
  final int wordCount;
  final int charCount;
  final int formatVersion;
  final DateTime updatedAt;

  const ChapterContentModel({
    required this.chapterId,
    required this.deltaJson,
    required this.plainText,
    required this.wordCount,
    required this.charCount,
    this.formatVersion = 1,
    required this.updatedAt,
  });

  static const defaultDelta = '[{"insert":"\\n"}]';
}
