import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/seed/nigerian_institutions.dart';
import 'package:perform_plus/domain/models/app_notification.dart';
import 'package:perform_plus/domain/models/course_result.dart';

void main() {
  group('cgpaChangedContent', () {
    test('a rising CGPA reads as congratulatory', () {
      final content = cgpaChangedContent(
        scheme: defaultSchemes['futo']!,
        level: 200,
        term: SemesterTerm.first,
        delta: 0.32,
        cgpa: 4.12,
      );

      expect(content.rising, isTrue);
      expect(content.title, 'Your CGPA went up');
      expect(content.body, contains('Up 0.32'));
    });

    test('a falling CGPA reads as a neutral statement, never a congratulation', () {
      final content = cgpaChangedContent(
        scheme: defaultSchemes['futo']!,
        level: 200,
        term: SemesterTerm.first,
        delta: -0.18,
        cgpa: 3.94,
      );

      expect(content.rising, isFalse);
      expect(content.title, 'Your CGPA changed');
      expect(content.title, isNot(contains('up')));
      expect(content.title, isNot(contains('Congrat')));
      expect(content.body, contains('Down 0.18'));
      expect(content.body, isNot(contains('Congrat')));
    });
  });

  group('semesterPhrase / resultAddedContent -- term naming', () {
    test('reads the institution\'s own term labels, not a generic "1st Semester"', () {
      final futo = defaultSchemes['futo']!;
      expect(futo.termLabel(SemesterTerm.first), 'Harmattan Semester');

      final phrase = semesterPhrase(futo, 200, SemesterTerm.first);
      expect(phrase, '200L Harmattan Semester');

      final content = resultAddedContent(
        scheme: futo,
        level: 200,
        term: SemesterTerm.first,
        cgpa: 4.12,
      );
      expect(content.body, contains('200L Harmattan Semester'));
    });

    test('a different scheme with generic labels produces a different phrase', () {
      final custom = defaultSchemes['custom']!;
      expect(custom.termLabel(SemesterTerm.first), 'First Semester');

      final phrase = semesterPhrase(custom, 100, SemesterTerm.first);
      expect(phrase, '100L First Semester');
    });
  });

  group('pruneOlderThan -- 90-day retention', () {
    final now = DateTime(2026, 8, 24);

    AppNotification notificationAt(String id, DateTime createdAt) => AppNotification(
          id: id,
          type: AppNotificationType.resultAdded,
          title: 't',
          body: 'b',
          createdAt: createdAt,
        );

    test('drops notifications older than 90 days and keeps the rest', () {
      final notifications = [
        notificationAt('fresh', now.subtract(const Duration(days: 1))),
        notificationAt('boundary', now.subtract(const Duration(days: 89))),
        notificationAt('stale', now.subtract(const Duration(days: 91))),
      ];

      final pruned = pruneOlderThan(notifications, now);

      expect(pruned.map((n) => n.id), containsAll(['fresh', 'boundary']));
      expect(pruned.map((n) => n.id), isNot(contains('stale')));
    });
  });
}
