/// Proves the fix for "results entered during onboarding vanish on
/// relaunch": a semester committed while nothing has ever watched
/// `academicRecordProvider` (the normal Act 1 -> Act 2 ordering — Add
/// Results commits it, then GPA reveal/Sign In/Profile Setup run without
/// ever reading `academicRecordProvider`; Backfill is the first screen
/// that does) must still reach disk, and must still be there after the
/// app "restarts" — a fresh `ProviderContainer` and a fresh `AppDatabase`
/// pointed at the same database file, nothing carried over in memory.
///
/// This is deliberately a real file-backed `NativeDatabase`, not
/// `NativeDatabase.memory()` — an in-memory database can't prove
/// persistence, since it dies with the connection that made it.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/academic_record_provider.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/features/onboarding/providers/onboarding_provider.dart';

void main() {
  test(
    'a semester committed during onboarding, read for the first time only '
    'after account setup, survives an app restart',
    () async {
      final dir = await Directory.systemTemp.createTemp('perform_plus_test');
      final dbFile = File(p.join(dir.path, 'restart_test.sqlite'));
      addTearDown(() => dir.delete(recursive: true));

      // --- "First launch": Act 1 commits a semester, then Backfill (Act 2)
      // is the first screen to ever watch academicRecordProvider. ---
      final firstDb = AppDatabase.forTesting(NativeDatabase(dbFile));
      final firstContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(firstDb)],
      );

      final draftNotifier = firstContainer.read(onboardingDraftProvider.notifier);
      draftNotifier.updateRow(
        0,
        const DraftResultRow(courseCode: 'CSC101', creditUnit: 3, grade: 'A'),
      );
      draftNotifier.commitDraft();

      // Nothing has read academicRecordProvider until right now — matching
      // the real navigation order, where Backfill is the first screen that
      // does. This used to be the exact moment the semester quietly stayed
      // in-memory-only instead of reaching the database.
      final controller = firstContainer.read(academicRecordProvider.notifier);
      await controller.ready;

      expect(firstContainer.read(academicRecordProvider).semesters, hasLength(1));

      firstContainer.dispose();
      await firstDb.close();

      // --- "Restart": brand-new container, brand-new AppDatabase, same
      // underlying file. ---
      final secondDb = AppDatabase.forTesting(NativeDatabase(dbFile));
      final secondContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(secondDb)],
      );
      addTearDown(() async {
        secondContainer.dispose();
        await secondDb.close();
      });

      await secondContainer.read(academicRecordProvider.notifier).ready;

      final record = secondContainer.read(academicRecordProvider);
      expect(record.semesters, hasLength(1));
      expect(record.semesters.single.results.single.courseCode, 'CSC101');
      expect(record.scheme.id, isNotEmpty);
    },
  );
}
