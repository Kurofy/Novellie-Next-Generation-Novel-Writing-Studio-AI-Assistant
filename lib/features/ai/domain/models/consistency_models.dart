enum ConsistencyCategory {
  character('Character Traits', 'Traits, appearances, motivations, and relationships'),
  timeline('Timeline & Chronology', 'Sequence of events, pacing, and chronological paradoxes'),
  location('Location & Geography', 'Geography, travel times, environments, and distances'),
  lore('World Lore & Magic', 'Magic system rules, faction dynamics, and world rules'),
  continuity('General Continuity', 'Item continuity, scene transitions, and factual details');

  final String label;
  final String description;
  const ConsistencyCategory(this.label, this.description);

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case ConsistencyCategory.character:
        return 'Sifat Karakter';
      case ConsistencyCategory.timeline:
        return 'Garis Waktu & Kronologi';
      case ConsistencyCategory.location:
        return 'Lokasi & Geografi';
      case ConsistencyCategory.lore:
        return 'Lore Dunia & Sihir';
      case ConsistencyCategory.continuity:
        return 'Kontinuitas Umum';
    }
  }

  String localizedDescription([bool isIndo = false]) {
    if (!isIndo) return description;
    switch (this) {
      case ConsistencyCategory.character:
        return 'Sifat, penampilan, motivasi, dan hubungan antar karakter';
      case ConsistencyCategory.timeline:
        return 'Urutan peristiwa, tempo, dan paradoks kronologis';
      case ConsistencyCategory.location:
        return 'Geografi, waktu perjalanan, lingkungan, dan jarak';
      case ConsistencyCategory.lore:
        return 'Aturan sistem sihir, dinamika faksi, dan hukum dunia';
      case ConsistencyCategory.continuity:
        return 'Kontinuitas benda, transisi adegan, dan detail faktual';
    }
  }
}

enum ConsistencySeverity {
  high('High', 'Breaks narrative logic or directly contradicts established canon'),
  medium('Medium', 'Noticeable inconsistency in character or world details'),
  low('Low', 'Minor phrasing or stylistic discrepancy');

  final String label;
  final String description;
  const ConsistencySeverity(this.label, this.description);

  String localizedLabel([bool isIndo = false]) {
    if (!isIndo) return label;
    switch (this) {
      case ConsistencySeverity.high:
        return 'Tinggi';
      case ConsistencySeverity.medium:
        return 'Sedang';
      case ConsistencySeverity.low:
        return 'Rendah';
    }
  }

  String localizedDescription([bool isIndo = false]) {
    if (!isIndo) return description;
    switch (this) {
      case ConsistencySeverity.high:
        return 'Merusak logika narasi atau langsung bertentangan dengan kanon';
      case ConsistencySeverity.medium:
        return 'Inkonsistensi nyata pada detail karakter atau dunia';
      case ConsistencySeverity.low:
        return 'Perbedaan kecil dalam frasa atau gaya bahasa';
    }
  }
}

class ConsistencyIssue {
  final String id;
  final String title;
  final ConsistencyCategory category;
  final ConsistencySeverity severity;
  final String chapterTitle;
  final String citedExcerpt;
  final String issueBreakdown;
  final String suggestedCorrection;

  const ConsistencyIssue({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.chapterTitle,
    required this.citedExcerpt,
    required this.issueBreakdown,
    required this.suggestedCorrection,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'severity': severity.name,
        'chapterTitle': chapterTitle,
        'citedExcerpt': citedExcerpt,
        'issueBreakdown': issueBreakdown,
        'suggestedCorrection': suggestedCorrection,
      };

  factory ConsistencyIssue.fromJson(Map<String, dynamic> json) =>
      ConsistencyIssue(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Continuity Discrepancy',
        category: ConsistencyCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ConsistencyCategory.continuity,
        ),
        severity: ConsistencySeverity.values.firstWhere(
          (s) => s.name == json['severity'],
          orElse: () => ConsistencySeverity.medium,
        ),
        chapterTitle: json['chapterTitle'] as String? ?? 'Manuscript',
        citedExcerpt: json['citedExcerpt'] as String? ?? '',
        issueBreakdown: json['issueBreakdown'] as String? ?? '',
        suggestedCorrection: json['suggestedCorrection'] as String? ?? '',
      );
}

class ConsistencyReport {
  final String novelId;
  final double consistencyScore; // 0.0 to 100.0%
  final double inconsistencyScore; // 0.0 to 100.0%
  final int totalIssues;
  final int analyzedChapterCount;
  final List<ConsistencyIssue> issues;
  final String summary;
  final DateTime analyzedAt;

  const ConsistencyReport({
    required this.novelId,
    required this.consistencyScore,
    required this.inconsistencyScore,
    required this.totalIssues,
    required this.analyzedChapterCount,
    required this.issues,
    required this.summary,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
        'novelId': novelId,
        'consistencyScore': consistencyScore,
        'inconsistencyScore': inconsistencyScore,
        'totalIssues': totalIssues,
        'analyzedChapterCount': analyzedChapterCount,
        'issues': issues.map((i) => i.toJson()).toList(),
        'summary': summary,
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory ConsistencyReport.fromJson(Map<String, dynamic> json) =>
      ConsistencyReport(
        novelId: json['novelId'] as String? ?? '',
        consistencyScore:
            (json['consistencyScore'] as num?)?.toDouble() ?? 100.0,
        inconsistencyScore:
            (json['inconsistencyScore'] as num?)?.toDouble() ?? 0.0,
        totalIssues: (json['totalIssues'] as num?)?.toInt() ?? 0,
        analyzedChapterCount:
            (json['analyzedChapterCount'] as num?)?.toInt() ?? 0,
        issues: (json['issues'] as List<dynamic>?)
                ?.map((i) => ConsistencyIssue.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        summary: json['summary'] as String? ?? 'Analysis completed.',
        analyzedAt: DateTime.tryParse(json['analyzedAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
}
