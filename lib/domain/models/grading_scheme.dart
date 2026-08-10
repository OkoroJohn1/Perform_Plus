/// Grading scheme model.
///
/// Deliberately separates four concerns that are commonly conflated:
///   1. score -> letter grade boundaries
///   2. letter -> grade point
///   3. CGPA -> degree classification bands
///   4. repeat / carryover policy
///
/// Every Nigerian university differs on at least one of these. Getting (4)
/// wrong silently corrupts the CGPA of any student with a carryover, which
/// is the fastest way to lose a user's trust permanently.
library;

import 'package:collection/collection.dart';

/// How an institution treats a repeated (previously failed) course.
enum RepeatPolicy {
  /// Original failure is removed entirely. Only the new attempt counts.
  /// Most generous. Used by some private universities.
  replaceOriginal,

  /// Both attempts remain in the denominator; both quality points count.
  /// Harshest and most common in Nigerian federal universities.
  countBothAttempts,

  /// New grade replaces the old, but is capped at a ceiling (often C / 3.0)
  /// regardless of the score actually achieved.
  replaceWithCap,
}

/// A single letter grade definition within a scheme.
class GradeDefinition {
  final String letter;
  final double point;
  final int minScore;
  final int maxScore;

  const GradeDefinition({
    required this.letter,
    required this.point,
    required this.minScore,
    required this.maxScore,
  });

  bool containsScore(int score) => score >= minScore && score <= maxScore;

  /// A grade is a failure when it carries zero quality points.
  bool get isFailing => point == 0;

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'point': point,
        'minScore': minScore,
        'maxScore': maxScore,
      };

  factory GradeDefinition.fromJson(Map<String, dynamic> json) =>
      GradeDefinition(
        letter: json['letter'] as String,
        point: (json['point'] as num).toDouble(),
        minScore: json['minScore'] as int,
        maxScore: json['maxScore'] as int,
      );
}

/// A degree classification band, e.g. First Class = 4.50 to 5.00.
class ClassificationBand {
  final String label;
  final String shortLabel;
  final double minCgpa;
  final double maxCgpa;

  const ClassificationBand({
    required this.label,
    required this.shortLabel,
    required this.minCgpa,
    required this.maxCgpa,
  });

  bool contains(double cgpa) => cgpa >= minCgpa && cgpa <= maxCgpa;

  Map<String, dynamic> toJson() => {
        'label': label,
        'shortLabel': shortLabel,
        'minCgpa': minCgpa,
        'maxCgpa': maxCgpa,
      };

  factory ClassificationBand.fromJson(Map<String, dynamic> json) =>
      ClassificationBand(
        label: json['label'] as String,
        shortLabel: json['shortLabel'] as String,
        minCgpa: (json['minCgpa'] as num).toDouble(),
        maxCgpa: (json['maxCgpa'] as num).toDouble(),
      );
}

/// A complete, versioned grading scheme for one institution.
///
/// [effectiveFrom] and [version] exist because universities revise their
/// scales. A student who entered in 2019 may be graded under a different
/// scheme than one who entered in 2024, and both must remain computable.
class GradingScheme {
  final String id;
  final String institutionId;
  final String name;
  final int version;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;

  final double maxPoint;
  final List<GradeDefinition> grades;
  final List<ClassificationBand> classifications;
  final RepeatPolicy repeatPolicy;

  /// Only meaningful when [repeatPolicy] is [RepeatPolicy.replaceWithCap].
  final double? repeatCapPoint;

  /// Whether this scheme was hand-entered by the user rather than seeded.
  final bool isCustom;

  const GradingScheme({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.version,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.maxPoint,
    required this.grades,
    required this.classifications,
    required this.repeatPolicy,
    this.repeatCapPoint,
    this.isCustom = false,
  });

  /// Resolve a letter grade to its point value.
  /// Returns null for an unrecognised letter rather than defaulting to 0 —
  /// a silent zero would corrupt the CGPA without any visible error.
  double? pointForLetter(String letter) {
    final normalised = letter.trim().toUpperCase();
    return grades
        .firstWhereOrNull((g) => g.letter.toUpperCase() == normalised)
        ?.point;
  }

  /// Resolve a raw score to its letter grade.
  String? letterForScore(int score) =>
      grades.firstWhereOrNull((g) => g.containsScore(score))?.letter;

  GradeDefinition? definitionForLetter(String letter) {
    final normalised = letter.trim().toUpperCase();
    return grades.firstWhereOrNull((g) => g.letter.toUpperCase() == normalised);
  }

  /// Whether a letter grade represents a failure under this scheme.
  bool isFailingLetter(String letter) =>
      definitionForLetter(letter)?.isFailing ?? false;

  /// The classification band a CGPA falls into.
  ClassificationBand? classify(double cgpa) =>
      classifications.firstWhereOrNull((c) => c.contains(cgpa));

  /// Bands ordered best-first. Used by the goal picker and by the
  /// "nearest achievable target" fallback in the projection solver.
  List<ClassificationBand> get bandsDescending {
    final sorted = [...classifications];
    sorted.sort((a, b) => b.minCgpa.compareTo(a.minCgpa));
    return sorted;
  }

  /// Validation run before a custom scheme is accepted.
  /// Returns an empty list when the scheme is internally consistent.
  List<String> validate() {
    final issues = <String>[];

    if (grades.isEmpty) {
      issues.add('Scheme must define at least one grade.');
    }
    if (classifications.isEmpty) {
      issues.add('Scheme must define at least one classification band.');
    }
    if (maxPoint <= 0) {
      issues.add('Maximum grade point must be greater than zero.');
    }

    final highest =
        grades.map((g) => g.point).fold<double>(0, (a, b) => a > b ? a : b);
    if (grades.isNotEmpty && highest != maxPoint) {
      issues.add(
        'Highest grade point ($highest) does not match declared maximum '
        '($maxPoint).',
      );
    }

    // Score ranges must not overlap — an overlap makes score->letter
    // resolution order-dependent and therefore unpredictable.
    final sortedByScore = [...grades]
      ..sort((a, b) => a.minScore.compareTo(b.minScore));
    for (var i = 0; i < sortedByScore.length - 1; i++) {
      if (sortedByScore[i].maxScore >= sortedByScore[i + 1].minScore) {
        issues.add(
          'Score ranges overlap between ${sortedByScore[i].letter} and '
          '${sortedByScore[i + 1].letter}.',
        );
      }
    }

    // Classification bands must not overlap either.
    final sortedBands = [...classifications]
      ..sort((a, b) => a.minCgpa.compareTo(b.minCgpa));
    for (var i = 0; i < sortedBands.length - 1; i++) {
      if (sortedBands[i].maxCgpa >= sortedBands[i + 1].minCgpa) {
        issues.add(
          'Classification bands overlap between ${sortedBands[i].label} and '
          '${sortedBands[i + 1].label}.',
        );
      }
    }

    if (repeatPolicy == RepeatPolicy.replaceWithCap && repeatCapPoint == null) {
      issues.add('Repeat cap policy requires a cap point to be set.');
    }

    return issues;
  }

  GradingScheme copyWith({
    String? name,
    double? maxPoint,
    List<GradeDefinition>? grades,
    List<ClassificationBand>? classifications,
    RepeatPolicy? repeatPolicy,
    double? repeatCapPoint,
    bool? isCustom,
  }) =>
      GradingScheme(
        id: id,
        institutionId: institutionId,
        name: name ?? this.name,
        version: version,
        effectiveFrom: effectiveFrom,
        effectiveUntil: effectiveUntil,
        maxPoint: maxPoint ?? this.maxPoint,
        grades: grades ?? this.grades,
        classifications: classifications ?? this.classifications,
        repeatPolicy: repeatPolicy ?? this.repeatPolicy,
        repeatCapPoint: repeatCapPoint ?? this.repeatCapPoint,
        isCustom: isCustom ?? this.isCustom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'institutionId': institutionId,
        'name': name,
        'version': version,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'effectiveUntil': effectiveUntil?.toIso8601String(),
        'maxPoint': maxPoint,
        'grades': grades.map((g) => g.toJson()).toList(),
        'classifications': classifications.map((c) => c.toJson()).toList(),
        'repeatPolicy': repeatPolicy.name,
        'repeatCapPoint': repeatCapPoint,
        'isCustom': isCustom,
      };

  factory GradingScheme.fromJson(Map<String, dynamic> json) => GradingScheme(
        id: json['id'] as String,
        institutionId: json['institutionId'] as String,
        name: json['name'] as String,
        version: json['version'] as int,
        effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
        effectiveUntil: json['effectiveUntil'] == null
            ? null
            : DateTime.parse(json['effectiveUntil'] as String),
        maxPoint: (json['maxPoint'] as num).toDouble(),
        grades: (json['grades'] as List)
            .map((g) => GradeDefinition.fromJson(g as Map<String, dynamic>))
            .toList(),
        classifications: (json['classifications'] as List)
            .map((c) => ClassificationBand.fromJson(c as Map<String, dynamic>))
            .toList(),
        repeatPolicy: RepeatPolicy.values
            .firstWhere((p) => p.name == json['repeatPolicy']),
        repeatCapPoint: (json['repeatCapPoint'] as num?)?.toDouble(),
        isCustom: json['isCustom'] as bool? ?? false,
      );
}
