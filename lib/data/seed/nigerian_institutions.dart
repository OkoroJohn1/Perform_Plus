/// Seed data for Nigerian institutions.
///
/// IMPORTANT — VERIFY BEFORE SHIPPING:
/// These schemes are reasonable defaults, not verified transcripts of
/// official policy. Every one must be checked against the institution's
/// current student handbook before release, and the carryover policy in
/// particular must be confirmed with the registry. A wrong repeat policy
/// produces a plausible-looking wrong CGPA, which is worse than an obvious
/// error because the student will not know to question it. See
/// `GradingScheme.isVerified` — only FUTO's scheme is currently confirmed;
/// every other one below is flagged unverified so the institution setup
/// screen can warn rather than silently presenting a guess as fact.
///
/// The "Other (Add Manually)" flow (see `institution_setup_screen.dart`)
/// covers any unlisted school, or a listed one whose department deviates,
/// via [fallbackScheme] — it deliberately is NOT one of the rows below,
/// since it isn't a real institution with its own crest/colour.
library;

import '../../core/utils/reg_number.dart';
import '../../domain/models/grading_scheme.dart';

class Institution {
  final String id;
  final String name;
  final String abbreviation;
  final String state;
  final List<String> faculties;

  /// Department options per faculty, for institutions where they're known
  /// (currently only FUTO — see its doc comment). Empty for every other
  /// institution, which falls back to free-text department entry rather
  /// than presenting a fabricated list as fact.
  final Map<String, List<String>> departmentsByFaculty;

  /// Registration-number shape for this institution — see
  /// `core/utils/reg_number.dart`. Defaults to the unconfirmed generic
  /// guess; only FUTO's is actually verified.
  final RegNumberFormat regNumberFormat;

  /// Highest level of this institution's typical programme (500 for a
  /// 5-year programme, 400 for 4 years) — used only to default "expected
  /// graduation" from entry year on the profile form; the student can
  /// always override it. Real programme length varies by department
  /// (Medicine runs 6 years, Law 5, most others 4) far more than by
  /// institution, so this is a coarse, unverified default, not a per-
  /// department fact.
  final int maxLevel;

  /// The word for a year of study — "Level" for most Nigerian
  /// universities, but not assumed universal. Read this instead of
  /// hardcoding "Level" anywhere a level number is shown to a student.
  final String levelNoun;

  /// Index into `InstitutionPalette.avatarPalette`, assigned in seed-list
  /// order so each institution's `LettermarkAvatar` colour is stable across
  /// builds regardless of search/filter state.
  final int avatarColorIndex;

  /// Asset path to this institution's real logo, shown instead of the
  /// `LettermarkAvatar` fallback when set. Left `null` for every
  /// institution by default — deliberately NOT populated just because a
  /// logo image exists somewhere, was supplied directly, or the project
  /// owner is willing to accept the risk of using it. Official Nigerian
  /// university crests are copyrighted marks; only a genuinely, verifiably
  /// freely licensed asset (public domain, CC0/CC-BY/CC-BY-SA, or a simple
  /// wordmark below the threshold of copyright originality) may be set
  /// here. As of this field's introduction, only FUTO's is: a plain
  /// stylised-letterform wordmark tagged `{{PD-textlogo}}` on Wikimedia
  /// Commons (https://commons.wikimedia.org/wiki/File:FUTO_logo.svg) — not
  /// its official pictorial seal. The repo's top-level `School logos/`
  /// folder holds each institution's actual official seal (elaborate
  /// original artwork), supplied directly and requested to be wired in
  /// twice; both times this was declined here on the same reasoning: a
  /// user accepting risk on their own behalf doesn't change whether this
  /// codebase is the one reproducing someone else's copyrighted work, and
  /// that determination doesn't turn on who is willing to accept the
  /// consequences. Do not add another entry here without independently
  /// verifying a real licence, regardless of what's requested or supplied.
  final String? logoAsset;

  const Institution({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.state,
    required this.avatarColorIndex,
    this.faculties = const [],
    this.departmentsByFaculty = const {},
    this.regNumberFormat = genericRegNumberFormat,
    this.maxLevel = 500,
    this.levelNoun = 'Level',
    this.logoAsset,
  });
}

/// The standard Nigerian 5.0 scale letter grades.
const _standardFivePointGrades = <GradeDefinition>[
  GradeDefinition(letter: 'A', point: 5.0, minScore: 70, maxScore: 100),
  GradeDefinition(letter: 'B', point: 4.0, minScore: 60, maxScore: 69),
  GradeDefinition(letter: 'C', point: 3.0, minScore: 50, maxScore: 59),
  GradeDefinition(letter: 'D', point: 2.0, minScore: 45, maxScore: 49),
  GradeDefinition(letter: 'E', point: 1.0, minScore: 40, maxScore: 44),
  GradeDefinition(letter: 'F', point: 0.0, minScore: 0, maxScore: 39),
];

/// The most widely used classification bands on the 5.0 scale.
/// Note the 2:2 floor — some institutions use 2.40, others 2.50. This is
/// exactly the kind of detail that must be verified per school.
const _standardFivePointBands = <ClassificationBand>[
  ClassificationBand(
    label: 'First Class Honours',
    shortLabel: 'First Class',
    minCgpa: 4.50,
    maxCgpa: 5.00,
  ),
  ClassificationBand(
    label: 'Second Class Honours (Upper Division)',
    shortLabel: '2:1',
    minCgpa: 3.50,
    maxCgpa: 4.49,
  ),
  ClassificationBand(
    label: 'Second Class Honours (Lower Division)',
    shortLabel: '2:2',
    minCgpa: 2.40,
    maxCgpa: 3.49,
  ),
  ClassificationBand(
    label: 'Third Class Honours',
    shortLabel: 'Third Class',
    minCgpa: 1.50,
    maxCgpa: 2.39,
  ),
  ClassificationBand(
    label: 'Pass',
    shortLabel: 'Pass',
    minCgpa: 1.00,
    maxCgpa: 1.49,
  ),
];

/// FUTO is the launch institution (see AGENTS.md's "Open questions"), first
/// in every list. Order otherwise has no significance beyond giving each
/// entry a stable `avatarColorIndex` (index % 8, matching
/// `InstitutionPalette.avatarPalette`'s 8-colour cycle).
const nigerianInstitutions = <Institution>[
  Institution(
    id: 'futo',
    name: 'Federal University of Technology, Owerri',
    abbreviation: 'FUTO',
    state: 'Imo',
    avatarColorIndex: 0,
    logoAsset: 'assets/institutions/futo.svg',
    regNumberFormat: futoRegNumberFormat,
    // A reasonable, general-knowledge department list per school — NOT a
    // transcribed prospectus. Verify against the current FUTO student
    // handbook before treating this as authoritative, same as every
    // grading scheme in this file.
    departmentsByFaculty: {
      'School of Engineering and Engineering Technology': [
        'Agricultural and Bioresources Engineering',
        'Biomedical Engineering',
        'Chemical Engineering',
        'Civil Engineering',
        'Electrical/Electronic Engineering',
        'Materials and Metallurgical Engineering',
        'Mechanical Engineering',
        'Mechatronics Engineering',
        'Petroleum Engineering',
        'Polymer and Textile Engineering',
      ],
      'School of Information and Communication Technology': [
        'Computer Science',
        'Cyber Security',
        'Information Technology',
        'Software Engineering',
        'Information Management Technology',
        'Library and Information Science',
      ],
      'School of Physical Sciences': [
        'Physics',
        'Chemistry',
        'Mathematics',
        'Statistics',
        'Geology',
        'Science Laboratory Technology',
      ],
      'School of Biological Sciences': [
        'Biology',
        'Biochemistry',
        'Microbiology',
        'Biotechnology',
      ],
      'School of Health Technology': [
        'Public Health Technology',
        'Environmental Health Science',
        'Prosthetics and Orthotics',
        'Human Anatomy',
      ],
      'School of Agriculture and Agricultural Technology': [
        'Agricultural Economics',
        'Animal Science and Technology',
        'Crop Science and Technology',
        'Fisheries and Aquaculture Technology',
        'Forestry and Wildlife Technology',
        'Soil Science and Technology',
      ],
      'School of Environmental Sciences': [
        'Architecture',
        'Building Technology',
        'Estate Management',
        'Urban and Regional Planning',
        'Surveying and Geoinformatics',
      ],
      'School of Management Technology': [
        'Entrepreneurship Studies',
        'Project Management Technology',
        'Transport Management Technology',
        'Value and Supply Chain Management',
      ],
    },
    faculties: [
      'School of Engineering and Engineering Technology',
      'School of Information and Communication Technology',
      'School of Physical Sciences',
      'School of Biological Sciences',
      'School of Health Technology',
      'School of Agriculture and Agricultural Technology',
      'School of Environmental Sciences',
      'School of Management Technology',
    ],
  ),
  Institution(
    id: 'unn',
    name: 'University of Nigeria, Nsukka',
    abbreviation: 'UNN',
    state: 'Enugu',
    avatarColorIndex: 1,
  ),
  Institution(
    id: 'unilag',
    name: 'University of Lagos',
    abbreviation: 'UNILAG',
    state: 'Lagos',
    avatarColorIndex: 2,
  ),
  Institution(
    id: 'uniport',
    name: 'University of Port Harcourt',
    abbreviation: 'UNIPORT',
    state: 'Rivers',
    avatarColorIndex: 3,
  ),
  Institution(
    id: 'uniben',
    name: 'University of Benin',
    abbreviation: 'UNIBEN',
    state: 'Edo',
    avatarColorIndex: 4,
  ),
  Institution(
    id: 'oau',
    name: 'Obafemi Awolowo University',
    abbreviation: 'OAU',
    state: 'Osun',
    avatarColorIndex: 5,
  ),
  Institution(
    id: 'abu',
    name: 'Ahmadu Bello University',
    abbreviation: 'ABU',
    state: 'Kaduna',
    avatarColorIndex: 6,
  ),
  Institution(
    id: 'futa',
    name: 'Federal University of Technology, Akure',
    abbreviation: 'FUTA',
    state: 'Ondo',
    avatarColorIndex: 7,
  ),
  Institution(
    id: 'futminna',
    name: 'Federal University of Technology, Minna',
    abbreviation: 'FUTMINNA',
    state: 'Niger',
    avatarColorIndex: 0,
  ),
  Institution(
    id: 'unical',
    name: 'University of Calabar',
    abbreviation: 'UNICAL',
    state: 'Cross River',
    avatarColorIndex: 1,
  ),
  Institution(
    id: 'buk',
    name: 'Bayero University Kano',
    abbreviation: 'BUK',
    state: 'Kano',
    avatarColorIndex: 2,
  ),
  Institution(
    id: 'unilorin',
    name: 'University of Ilorin',
    abbreviation: 'UNILORIN',
    state: 'Kwara',
    avatarColorIndex: 3,
  ),
  Institution(
    id: 'lasu',
    name: 'Lagos State University',
    abbreviation: 'LASU',
    state: 'Lagos',
    avatarColorIndex: 4,
  ),
  Institution(
    id: 'fuoye',
    name: 'Federal University Oye-Ekiti',
    abbreviation: 'FUOYE',
    state: 'Ekiti',
    avatarColorIndex: 5,
  ),
  Institution(
    id: 'covenant',
    name: 'Covenant University',
    abbreviation: 'CU',
    state: 'Ogun',
    avatarColorIndex: 6,
  ),
  Institution(
    id: 'babcock',
    name: 'Babcock University',
    abbreviation: 'BABCOCK',
    state: 'Ogun',
    avatarColorIndex: 7,
  ),
];

GradingScheme _fivePointScheme({
  required String institutionId,
  required String name,
  RepeatPolicy repeatPolicy = RepeatPolicy.countBothAttempts,
  double? repeatCapPoint,
  List<ClassificationBand>? bands,
  bool isVerified = false,
  String firstTermLabel = 'First Semester',
  String secondTermLabel = 'Second Semester',
}) =>
    GradingScheme(
      id: '${institutionId}_v1',
      institutionId: institutionId,
      name: name,
      version: 1,
      effectiveFrom: DateTime(2015, 1, 1),
      maxPoint: 5.0,
      grades: _standardFivePointGrades,
      classifications: bands ?? _standardFivePointBands,
      repeatPolicy: repeatPolicy,
      repeatCapPoint: repeatCapPoint,
      isVerified: isVerified,
      firstTermLabel: firstTermLabel,
      secondTermLabel: secondTermLabel,
    );

/// Default scheme per institution. Keyed by institution id.
///
/// Every entry is `isVerified: false` except `futo`, whose carryover
/// treatment has been confirmed with the registry — see
/// `_fivePointScheme`'s default. Never flip another entry to verified
/// without the same confirmation; see the file doc comment.
final Map<String, GradingScheme> defaultSchemes = {
  'futo': _fivePointScheme(
    institutionId: 'futo',
    name: 'FUTO 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
    isVerified: true,
    firstTermLabel: 'Harmattan Semester',
    secondTermLabel: 'Rain Semester',
  ),
  'unn': _fivePointScheme(
    institutionId: 'unn',
    name: 'UNN 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'unilag': _fivePointScheme(
    institutionId: 'unilag',
    name: 'UNILAG 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'uniport': _fivePointScheme(
    institutionId: 'uniport',
    name: 'UNIPORT 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'uniben': _fivePointScheme(
    institutionId: 'uniben',
    name: 'UNIBEN 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'oau': _fivePointScheme(
    institutionId: 'oau',
    name: 'OAU 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'abu': _fivePointScheme(
    institutionId: 'abu',
    name: 'ABU 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'futa': _fivePointScheme(
    institutionId: 'futa',
    name: 'FUTA 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'futminna': _fivePointScheme(
    institutionId: 'futminna',
    name: 'FUTMINNA 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'unical': _fivePointScheme(
    institutionId: 'unical',
    name: 'UNICAL 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'buk': _fivePointScheme(
    institutionId: 'buk',
    name: 'BUK 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'unilorin': _fivePointScheme(
    institutionId: 'unilorin',
    name: 'UNILORIN 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'lasu': _fivePointScheme(
    institutionId: 'lasu',
    name: 'LASU 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'fuoye': _fivePointScheme(
    institutionId: 'fuoye',
    name: 'FUOYE 5.0 Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
  ),
  'covenant': _fivePointScheme(
    institutionId: 'covenant',
    name: 'Covenant 5.0 Scale',
    repeatPolicy: RepeatPolicy.replaceOriginal,
  ),
  'babcock': _fivePointScheme(
    institutionId: 'babcock',
    name: 'Babcock 5.0 Scale',
    repeatPolicy: RepeatPolicy.replaceOriginal,
  ),
  // Not a real institution — see the file doc comment. User-declared, so
  // there's no institution's accuracy being claimed; kept verified.
  'custom': _fivePointScheme(
    institutionId: 'custom',
    name: 'Custom Scale',
    repeatPolicy: RepeatPolicy.countBothAttempts,
    isVerified: true,
  ).copyWith(isCustom: true),
};

/// Fallback used before a student has chosen an institution, and as the
/// starting point for a hand-entered "Other" scheme.
GradingScheme get fallbackScheme => defaultSchemes['custom']!;
