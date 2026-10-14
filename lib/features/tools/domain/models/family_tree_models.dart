/// Genealogical family relationship types strictly for character lineages.
enum FamilyRelationshipType {
  parent,
  child,
  spouse,
  sibling,
  ancestor,
  adoptive;

  String get label {
    switch (this) {
      case FamilyRelationshipType.parent:
        return 'Parent of';
      case FamilyRelationshipType.child:
        return 'Child of';
      case FamilyRelationshipType.spouse:
        return 'Spouse / Partner';
      case FamilyRelationshipType.sibling:
        return 'Sibling of';
      case FamilyRelationshipType.ancestor:
        return 'Ancestor of';
      case FamilyRelationshipType.adoptive:
        return 'Adopted / Foster';
    }
  }

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case FamilyRelationshipType.parent:
        return 'Orang Tua dari';
      case FamilyRelationshipType.child:
        return 'Anak dari';
      case FamilyRelationshipType.spouse:
        return 'Pasangan / Suami/Istri';
      case FamilyRelationshipType.sibling:
        return 'Saudara Kandung dari';
      case FamilyRelationshipType.ancestor:
        return 'Leluhur dari';
      case FamilyRelationshipType.adoptive:
        return 'Anak Angkat / Asuh';
    }
  }

  bool get isBidirectional =>
      this == FamilyRelationshipType.spouse ||
      this == FamilyRelationshipType.sibling;

  static FamilyRelationshipType fromString(String? val) {
    if (val == null) return FamilyRelationshipType.child;
    return FamilyRelationshipType.values.firstWhere(
      (e) => e.name == val || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => FamilyRelationshipType.child,
    );
  }
}

/// A character node strictly within a family lineage tree.
class FamilyTreeNode {
  final String id;
  final String treeId;
  final String? characterId; // Linked Character entity ID in novel
  final String name;
  final String? titleOrRole; // e.g. Patriarch, Matriarch, Crown Prince, Heir
  final int generation; // 0 = root/progenitor, -1 = parents, 1 = children
  final String? gender; // 'male', 'female', 'other'
  final String? status; // 'alive', 'deceased', 'unknown'
  final String? years; // e.g. "1040 - 1098" or "b. 1024"
  final String? notes;
  final String? avatarPath;
  final int? colorValue;
  final double x;
  final double y;

  const FamilyTreeNode({
    required this.id,
    required this.treeId,
    this.characterId,
    required this.name,
    this.titleOrRole,
    this.generation = 0,
    this.gender,
    this.status = 'alive',
    this.years,
    this.notes,
    this.avatarPath,
    this.colorValue,
    this.x = 0.0,
    this.y = 0.0,
  });

  FamilyTreeNode copyWith({
    String? id,
    String? treeId,
    String? characterId,
    String? name,
    String? titleOrRole,
    int? generation,
    String? gender,
    String? status,
    String? years,
    String? notes,
    String? avatarPath,
    int? colorValue,
    double? x,
    double? y,
  }) {
    return FamilyTreeNode(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      titleOrRole: titleOrRole ?? this.titleOrRole,
      generation: generation ?? this.generation,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      years: years ?? this.years,
      notes: notes ?? this.notes,
      avatarPath: avatarPath ?? this.avatarPath,
      colorValue: colorValue ?? this.colorValue,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  String localizedGender([bool isIndo = false]) {
    if (!isIndo) {
      if (gender == 'male') return 'Male';
      if (gender == 'female') return 'Female';
      return gender ?? 'Other';
    }
    if (gender == 'male') return 'Laki-laki';
    if (gender == 'female') return 'Perempuan';
    return gender != null ? 'Lainnya' : 'Tidak ditentukan';
  }

  String localizedStatus([bool isIndo = false]) {
    if (!isIndo) {
      if (status == 'alive') return 'Alive';
      if (status == 'deceased') return 'Deceased';
      return status ?? 'Unknown';
    }
    if (status == 'alive') return 'Hidup';
    if (status == 'deceased') return 'Meninggal';
    return 'Tidak Diketahui';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'treeId': treeId,
        'characterId': characterId,
        'name': name,
        'titleOrRole': titleOrRole,
        'generation': generation,
        'gender': gender,
        'status': status,
        'years': years,
        'notes': notes,
        'avatarPath': avatarPath,
        'colorValue': colorValue,
        'x': x,
        'y': y,
      };

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    return FamilyTreeNode(
      id: json['id'] as String,
      treeId: json['treeId'] as String? ?? '',
      characterId: json['characterId'] as String?,
      name: json['name'] as String? ?? 'Unnamed',
      titleOrRole: json['titleOrRole'] as String?,
      generation: (json['generation'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String?,
      status: json['status'] as String? ?? 'alive',
      years: json['years'] as String?,
      notes: json['notes'] as String?,
      avatarPath: json['avatarPath'] as String?,
      colorValue: (json['colorValue'] as num?)?.toInt(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A strictly genealogical lineage edge between two family tree nodes.
class FamilyTreeEdge {
  final String id;
  final String treeId;
  final String fromNodeId;
  final String toNodeId;
  final FamilyRelationshipType relationshipType;
  final String? customLabel;
  final String? notes;
  final bool isBidirectional;
  final int? colorValue;

  const FamilyTreeEdge({
    required this.id,
    required this.treeId,
    required this.fromNodeId,
    required this.toNodeId,
    this.relationshipType = FamilyRelationshipType.child,
    this.customLabel,
    this.notes,
    this.isBidirectional = false,
    this.colorValue,
  });

  String get displayLabel =>
      customLabel != null && customLabel!.trim().isNotEmpty
          ? customLabel!
          : relationshipType.label;

  String localizedDisplayLabel([bool isIndo = false]) =>
      customLabel != null && customLabel!.trim().isNotEmpty
          ? customLabel!
          : relationshipType.localizedLabel(isIndo);

  FamilyTreeEdge copyWith({
    String? id,
    String? treeId,
    String? fromNodeId,
    String? toNodeId,
    FamilyRelationshipType? relationshipType,
    String? customLabel,
    String? notes,
    bool? isBidirectional,
    int? colorValue,
  }) {
    return FamilyTreeEdge(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      relationshipType: relationshipType ?? this.relationshipType,
      customLabel: customLabel ?? this.customLabel,
      notes: notes ?? this.notes,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'treeId': treeId,
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        'relationshipType': relationshipType.name,
        'customLabel': customLabel,
        'notes': notes,
        'isBidirectional': isBidirectional,
        'colorValue': colorValue,
      };

  factory FamilyTreeEdge.fromJson(Map<String, dynamic> json) {
    return FamilyTreeEdge(
      id: json['id'] as String,
      treeId: json['treeId'] as String? ?? '',
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      relationshipType:
          FamilyRelationshipType.fromString(json['relationshipType'] as String?),
      customLabel: json['customLabel'] as String?,
      notes: json['notes'] as String?,
      isBidirectional: json['isBidirectional'] as bool? ?? false,
      colorValue: (json['colorValue'] as num?)?.toInt(),
    );
  }
}

/// A distinct Family Tree dedicated to a character's family lineage or dynasty.
class FamilyTree {
  final String id;
  final String novelId;
  final String name; // e.g., "House Blackwood", "Elena's Lineage"
  final String? description;
  final String? rootCharacterId; // Primary character this tree originated for
  final List<FamilyTreeNode> nodes;
  final List<FamilyTreeEdge> edges;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyTree({
    required this.id,
    required this.novelId,
    required this.name,
    this.description,
    this.rootCharacterId,
    this.nodes = const [],
    this.edges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  FamilyTree copyWith({
    String? id,
    String? novelId,
    String? name,
    String? description,
    String? rootCharacterId,
    List<FamilyTreeNode>? nodes,
    List<FamilyTreeEdge>? edges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyTree(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      name: name ?? this.name,
      description: description ?? this.description,
      rootCharacterId: rootCharacterId ?? this.rootCharacterId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'novelId': novelId,
        'name': name,
        'description': description,
        'rootCharacterId': rootCharacterId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FamilyTree.fromJson(Map<String, dynamic> json) {
    return FamilyTree(
      id: json['id'] as String,
      novelId: json['novelId'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Family Tree',
      description: json['description'] as String?,
      rootCharacterId: json['rootCharacterId'] as String?,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => FamilyTreeNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => FamilyTreeEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
