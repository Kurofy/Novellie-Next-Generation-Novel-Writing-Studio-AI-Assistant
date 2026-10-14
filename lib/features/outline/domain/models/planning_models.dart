class TimelineEventModel {
  final String id;
  final String novelId;
  final String? periodId;
  final String title;
  final String? description;
  final String? dateText;
  final double sortKey;
  final String? notes;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimelineEventModel({
    required this.id,
    required this.novelId,
    this.periodId,
    required this.title,
    this.description,
    this.dateText,
    required this.sortKey,
    this.notes,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  TimelineEventModel copyWith({
    String? id,
    String? novelId,
    String? periodId,
    String? title,
    String? description,
    String? dateText,
    double? sortKey,
    String? notes,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimelineEventModel(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      periodId: periodId ?? this.periodId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateText: dateText ?? this.dateText,
      sortKey: sortKey ?? this.sortKey,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SceneCardModel {
  final String id;
  final String novelId;
  final String? arcId;
  final String? chapterId;
  final String title;
  final String? purpose;
  final String status;
  final String? dramaticQuestion;
  final String? openingValue;
  final String? closingValue;
  final String? desiredOutcome;
  final String? notes;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SceneCardModel({
    required this.id,
    required this.novelId,
    this.arcId,
    this.chapterId,
    required this.title,
    this.purpose,
    this.status = 'planned',
    this.dramaticQuestion,
    this.openingValue,
    this.closingValue,
    this.desiredOutcome,
    this.notes,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  SceneCardModel copyWith({
    String? id,
    String? novelId,
    String? arcId,
    String? chapterId,
    String? title,
    String? purpose,
    String? status,
    String? dramaticQuestion,
    String? openingValue,
    String? closingValue,
    String? desiredOutcome,
    String? notes,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SceneCardModel(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      arcId: arcId ?? this.arcId,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      dramaticQuestion: dramaticQuestion ?? this.dramaticQuestion,
      openingValue: openingValue ?? this.openingValue,
      closingValue: closingValue ?? this.closingValue,
      desiredOutcome: desiredOutcome ?? this.desiredOutcome,
      notes: notes ?? this.notes,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
