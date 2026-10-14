/// Node types dedicated strictly to brainstorming, ideation sequences, chapter ordering, and story arcs.
enum MindMapNodeType {
  brainstorm, // Freeform brainstorm / ideation concept
  storyArc, // Major story arc (Main Arc, Sub-Plot, Character Journey)
  chapterOrder, // Chapter ordering sequence / narrative milestone beat
  plotPoint, // Inciting Incident, Climax, Reversal, Resolution
  theme; // Central motif / thematic premise

  String get label {
    switch (this) {
      case MindMapNodeType.brainstorm:
        return 'Brainstorm / Idea';
      case MindMapNodeType.storyArc:
        return 'Story Arc';
      case MindMapNodeType.chapterOrder:
        return 'Chapter Sequence';
      case MindMapNodeType.plotPoint:
        return 'Plot Point';
      case MindMapNodeType.theme:
        return 'Theme & Motif';
    }
  }

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case MindMapNodeType.brainstorm:
        return 'Brainstorm / Ide';
      case MindMapNodeType.storyArc:
        return 'Alur Cerita (Arc)';
      case MindMapNodeType.chapterOrder:
        return 'Urutan Bab';
      case MindMapNodeType.plotPoint:
        return 'Titik Plot';
      case MindMapNodeType.theme:
        return 'Tema & Motif';
    }
  }

  static MindMapNodeType fromString(String? val) {
    if (val == null) return MindMapNodeType.brainstorm;
    return MindMapNodeType.values.firstWhere(
      (e) => e.name == val || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => MindMapNodeType.brainstorm,
    );
  }
}

/// Connection types dedicated strictly to brainstorming sequences and narrative story structures.
enum MindMapConnectionType {
  leadsTo, // Sequence flow: Leads to / Follows chronologically
  causes, // Narrative cause & effect / Triggers
  parallelArc, // Parallel storyline running concurrently
  conflictsWith, // Dramatic tension / Opposition / Conflict
  subPlot, // Subplot branching off main arc
  supports, // Thematic support / Echoes
  custom; // Freeform ideation link

  String get label {
    switch (this) {
      case MindMapConnectionType.leadsTo:
        return 'Leads To (Sequence)';
      case MindMapConnectionType.causes:
        return 'Causes / Triggers';
      case MindMapConnectionType.parallelArc:
        return 'Parallel Arc';
      case MindMapConnectionType.conflictsWith:
        return 'Conflicts With';
      case MindMapConnectionType.subPlot:
        return 'Subplot Of';
      case MindMapConnectionType.supports:
        return 'Supports / Echoes';
      case MindMapConnectionType.custom:
        return 'Connected To';
    }
  }

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case MindMapConnectionType.leadsTo:
        return 'Menuju ke (Urutan)';
      case MindMapConnectionType.causes:
        return 'Menyebabkan / Memicu';
      case MindMapConnectionType.parallelArc:
        return 'Alur Paralel';
      case MindMapConnectionType.conflictsWith:
        return 'Konflik Dengan';
      case MindMapConnectionType.subPlot:
        return 'Subplot Dari';
      case MindMapConnectionType.supports:
        return 'Mendukung / Mencerminkan';
      case MindMapConnectionType.custom:
        return 'Terhubung Dengan';
    }
  }

  static MindMapConnectionType fromString(String? val) {
    if (val == null) return MindMapConnectionType.leadsTo;
    return MindMapConnectionType.values.firstWhere(
      (e) => e.name == val || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => MindMapConnectionType.custom,
    );
  }
}

/// A node dedicated strictly to brainstorming, story arcs, and chapter sequences.
class MindMapNode {
  final String id;
  final String novelId;
  final MindMapNodeType type;
  final String title;
  final String? description;
  final int? sequenceOrder; // Chapter or ideation sequence number (#1, #2, #3...)
  final String? storyArcName; // e.g. "Hero's Journey", "Act I", "Subplot B"
  final String? linkedChapterId; // Optional link to Chapter entity in manuscript
  final int? colorValue;
  final double x;
  final double y;

  const MindMapNode({
    required this.id,
    required this.novelId,
    this.type = MindMapNodeType.brainstorm,
    required this.title,
    this.description,
    this.sequenceOrder,
    this.storyArcName,
    this.linkedChapterId,
    this.colorValue,
    this.x = 0.0,
    this.y = 0.0,
  });

  MindMapNode copyWith({
    String? id,
    String? novelId,
    MindMapNodeType? type,
    String? title,
    String? description,
    int? sequenceOrder,
    String? storyArcName,
    String? linkedChapterId,
    int? colorValue,
    double? x,
    double? y,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      storyArcName: storyArcName ?? this.storyArcName,
      linkedChapterId: linkedChapterId ?? this.linkedChapterId,
      colorValue: colorValue ?? this.colorValue,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'novelId': novelId,
        'type': type.name,
        'title': title,
        'description': description,
        'sequenceOrder': sequenceOrder,
        'storyArcName': storyArcName,
        'linkedChapterId': linkedChapterId,
        'colorValue': colorValue,
        'x': x,
        'y': y,
      };

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    // Graceful backward compatibility for previous custom/concept labels
    final rawType = json['type'] as String?;
    final resolvedType = MindMapNodeType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () {
        if (rawType == 'character' || rawType == 'worldEntry') {
          return MindMapNodeType.storyArc;
        }
        return MindMapNodeType.brainstorm;
      },
    );

    return MindMapNode(
      id: json['id'] as String,
      novelId: json['novelId'] as String? ?? '',
      type: resolvedType,
      title: json['title'] as String? ??
          (json['label'] as String? ?? 'Untitled Concept'),
      description: json['description'] as String? ??
          (json['notes'] as String? ?? json['subtitle'] as String?),
      sequenceOrder: (json['sequenceOrder'] as num?)?.toInt(),
      storyArcName: json['storyArcName'] as String?,
      linkedChapterId: json['linkedChapterId'] as String? ??
          json['linkedEntityId'] as String?,
      colorValue: (json['colorValue'] as num?)?.toInt(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A connection dedicated to story sequence progression and brainstorming links.
class MindMapEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final MindMapConnectionType type;
  final String? customLabel;
  final String? notes;
  final bool isBidirectional;
  final int? strength;
  final int? colorValue;

  const MindMapEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.type = MindMapConnectionType.leadsTo,
    this.customLabel,
    this.notes,
    this.isBidirectional = false,
    this.strength,
    this.colorValue,
  });

  String get displayLabel =>
      customLabel != null && customLabel!.trim().isNotEmpty
          ? customLabel!
          : type.label;

  String localizedDisplayLabel([bool isIndo = false]) =>
      customLabel != null && customLabel!.trim().isNotEmpty
          ? customLabel!
          : type.localizedLabel(isIndo);

  MindMapEdge copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    MindMapConnectionType? type,
    String? customLabel,
    String? notes,
    bool? isBidirectional,
    int? strength,
    int? colorValue,
  }) {
    return MindMapEdge(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      type: type ?? this.type,
      customLabel: customLabel ?? this.customLabel,
      notes: notes ?? this.notes,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      strength: strength ?? this.strength,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        'type': type.name,
        'customLabel': customLabel,
        'notes': notes,
        'isBidirectional': isBidirectional,
        'strength': strength,
        'colorValue': colorValue,
      };

  factory MindMapEdge.fromJson(Map<String, dynamic> json) {
    return MindMapEdge(
      id: json['id'] as String,
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      type: MindMapConnectionType.fromString(json['type'] as String?),
      customLabel: json['customLabel'] as String?,
      notes: json['notes'] as String?,
      isBidirectional: json['isBidirectional'] as bool? ?? false,
      strength: (json['strength'] as num?)?.toInt(),
      colorValue: (json['colorValue'] as num?)?.toInt(),
    );
  }
}

/// Dedicated Mind Map graph for story brainstorming, ideation sequences, chapter ordering, and story arcs.
class MindMapGraph {
  final String novelId;
  final List<MindMapNode> nodes;
  final List<MindMapEdge> edges;

  const MindMapGraph({
    required this.novelId,
    this.nodes = const [],
    this.edges = const [],
  });

  MindMapGraph copyWith({
    String? novelId,
    List<MindMapNode>? nodes,
    List<MindMapEdge>? edges,
  }) {
    return MindMapGraph(
      novelId: novelId ?? this.novelId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  Map<String, dynamic> toJson() => {
        'novelId': novelId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  factory MindMapGraph.fromJson(Map<String, dynamic> json) {
    return MindMapGraph(
      novelId: json['novelId'] as String? ?? '',
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => MindMapEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
