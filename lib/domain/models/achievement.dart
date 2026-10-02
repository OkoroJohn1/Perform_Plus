/// Achievement badges. Pure Dart — no Flutter, no Drift.
///
/// Every badge here has a trigger computable from data the app already
/// has (`AcademicStanding`/`SemesterComputation`, or the Study tab's
/// reading streak) — see `achievement_engine.dart`. Do not add a badge that
/// needs a metric this app doesn't track.
library;

enum BadgeId { consistentLearner, topPerformer, improvementKing, firstSteps }

class BadgeDefinition {
  final BadgeId id;
  final String name;

  /// Shown while locked — states what earns it.
  final String criteria;

  const BadgeDefinition({required this.id, required this.name, required this.criteria});
}

const allBadges = <BadgeDefinition>[
  BadgeDefinition(
    id: BadgeId.consistentLearner,
    name: 'Consistent Learner',
    criteria: '7-day reading streak',
  ),
  BadgeDefinition(
    id: BadgeId.topPerformer,
    name: 'Top Performer',
    criteria: 'Semester GPA above 4.0',
  ),
  BadgeDefinition(
    id: BadgeId.improvementKing,
    name: 'Improvement King',
    criteria: 'GPA up 0.5 in a semester',
  ),
  BadgeDefinition(
    id: BadgeId.firstSteps,
    name: 'First Steps',
    criteria: 'Add your first result',
  ),
];
