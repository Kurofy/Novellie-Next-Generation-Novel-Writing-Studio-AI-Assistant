class WorldCategoryModel {
  final String id;
  final String novelId;
  final String key;
  final String name;
  final String? icon;
  final int position;
  final bool isBuiltin;

  const WorldCategoryModel({
    required this.id,
    required this.novelId,
    required this.key,
    required this.name,
    this.icon,
    required this.position,
    this.isBuiltin = false,
  });
}

class WorldEntryModel {
  final String id;
  final String novelId;
  final String categoryId;
  final String? parentId;
  final String name;
  final String? subtitle;
  final String? summary;
  final String? coverPath;
  final bool verifiedCanon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldEntryModel({
    required this.id,
    required this.novelId,
    required this.categoryId,
    this.parentId,
    required this.name,
    this.subtitle,
    this.summary,
    this.coverPath,
    this.verifiedCanon = false,
    required this.createdAt,
    required this.updatedAt,
  });

  WorldEntryModel copyWith({
    String? categoryId,
    String? parentId,
    String? name,
    String? subtitle,
    String? summary,
    String? coverPath,
    bool? verifiedCanon,
    DateTime? updatedAt,
  }) {
    return WorldEntryModel(
      id: id,
      novelId: novelId,
      categoryId: categoryId ?? this.categoryId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      summary: summary ?? this.summary,
      coverPath: coverPath ?? this.coverPath,
      verifiedCanon: verifiedCanon ?? this.verifiedCanon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
