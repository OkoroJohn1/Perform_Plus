/// Student's goal target. Pure Dart — no Flutter imports.
library;

import 'grading_scheme.dart';

class GoalTarget {
  final ClassificationBand band;
  final int semestersRemaining;

  const GoalTarget({required this.band, required this.semestersRemaining});
}
