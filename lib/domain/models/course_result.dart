/// Course result and semester models.
library;

enum SemesterTerm { first, second }

extension SemesterTermLabel on SemesterTerm {
  String get label => switch (this) {
        SemesterTerm.first => 'First Semester',
        SemesterTerm.second => 'Second Semester',
      };

  String get shortLabel => switch (this) {
        SemesterTerm.first => '1st',
        SemesterTerm.second => '2nd',
      };
}

/// How a result entered the system. Tracked because imported rows carry
/// OCR uncertainty and should be surfaced differently in the review table.
enum ResultSource { manual, ocrImport, seeded }

/// A single course result for one student in one semester.
class CourseResult {
  final String id;
  final String semesterId;

  final String courseCode;
  final String? courseTitle;
  final int creditUnit;

  /// The letter grade as recorded. Resolution to a point value happens in
  /// the engine against the active [GradingScheme], never here — the same
  /// letter can mean different things under different schemes.
  final String grade;

  /// Optional raw score. When present the engine can re-derive the letter
  /// if the scheme changes, which matters for scheme corrections.
  final int? score;

  /// Attempt number. 1 for a first sitting, 2+ for a repeat.
  /// Drives carryover handling in the engine.
  final int attempt;

  /// Set on a repeat row to point at the original failed attempt.
  final String? supersedesResultId;

  final ResultSource source;

  /// Confidence from OCR extraction, 0.0 to 1.0. Null for manual entry.
  /// Rows below the review threshold get flagged in the confirm table.
  final double? extractionConfidence;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseResult({
    required this.id,
    required this.semesterId,
    required this.courseCode,
    this.courseTitle,
    required this.creditUnit,
    required this.grade,
    this.score,
    this.attempt = 1,
    this.supersedesResultId,
    this.source = ResultSource.manual,
    this.extractionConfidence,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRepeat => attempt > 1;

  bool get needsReview =>
      extractionConfidence != null && extractionConfidence! < 0.85;

  CourseResult copyWith({
    String? courseCode,
    String? courseTitle,
    int? creditUnit,
    String? grade,
    int? score,
    int? attempt,
    String? supersedesResultId,
    ResultSource? source,
    double? extractionConfidence,
    DateTime? updatedAt,
  }) =>
      CourseResult(
        id: id,
        semesterId: semesterId,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        creditUnit: creditUnit ?? this.creditUnit,
        grade: grade ?? this.grade,
        score: score ?? this.score,
        attempt: attempt ?? this.attempt,
        supersedesResultId: supersedesResultId ?? this.supersedesResultId,
        source: source ?? this.source,
        extractionConfidence:
            extractionConfidence ?? this.extractionConfidence,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'semesterId': semesterId,
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'creditUnit': creditUnit,
        'grade': grade,
        'score': score,
        'attempt': attempt,
        'supersedesResultId': supersedesResultId,
        'source': source.name,
        'extractionConfidence': extractionConfidence,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CourseResult.fromJson(Map<String, dynamic> json) => CourseResult(
        id: json['id'] as String,
        semesterId: json['semesterId'] as String,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String?,
        creditUnit: json['creditUnit'] as int,
        grade: json['grade'] as String,
        score: json['score'] as int?,
        attempt: json['attempt'] as int? ?? 1,
        supersedesResultId: json['supersedesResultId'] as String?,
        source: ResultSource.values
            .firstWhere((s) => s.name == json['source'],
                orElse: () => ResultSource.manual),
        extractionConfidence:
            (json['extractionConfidence'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// One academic semester containing a set of course results.
class Semester {
  final String id;
  final String profileId;

  /// Academic session as written on the result slip, e.g. "2024/2025".
  final String session;
  final SemesterTerm term;

  /// Level in the Nigerian system: 100, 200, 300, 400, 500, 600.
  final int level;

  final List<CourseResult> results;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Semester({
    required this.id,
    required this.profileId,
    required this.session,
    required this.term,
    required this.level,
    this.results = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get label => '$level Level — ${term.label}';
  String get shortLabel => '${level}L ${term.shortLabel}';

  /// Chronological ordering key. Level dominates, term breaks the tie.
  int get sortKey => level * 10 + term.index;

  bool get isEmpty => results.isEmpty;

  Semester copyWith({
    String? session,
    SemesterTerm? term,
    int? level,
    List<CourseResult>? results,
    DateTime? updatedAt,
  }) =>
      Semester(
        id: id,
        profileId: profileId,
        session: session ?? this.session,
        term: term ?? this.term,
        level: level ?? this.level,
        results: results ?? this.results,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'session': session,
        'term': term.name,
        'level': level,
        'results': results.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        session: json['session'] as String,
        term: SemesterTerm.values.firstWhere((t) => t.name == json['term']),
        level: json['level'] as int,
        results: (json['results'] as List? ?? [])
            .map((r) => CourseResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
