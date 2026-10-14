import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/domain/models/app_feedback.dart';
import 'package:perform_plus/domain/repositories/feedback_repository.dart';
import 'package:perform_plus/features/feedback/screens/feedback_screen.dart';

final _now = DateTime(2026, 1, 1, 12);

class _FakeFeedbackRepository implements FeedbackRepository {
  List<AppFeedback> feed;
  bool rateLimited = false;

  int? capturedRating;
  String? capturedComment;
  String? capturedDisplayName;

  _FakeFeedbackRepository({this.feed = const []});

  @override
  Future<List<AppFeedback>> loadFeed() async => feed;

  @override
  Future<void> submit({
    required int rating,
    required String comment,
    required String? displayName,
  }) async {
    if (rateLimited) throw const FeedbackRateLimitedException();
    capturedRating = rating;
    capturedComment = comment;
    capturedDisplayName = displayName;
  }
}

Future<AppDatabase> _memoryDb() async => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('tapping a star shows that star\'s own meaning', (tester) async {
    final repo = _FakeFeedbackRepository();
    final db = await _memoryDb();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          feedbackRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: FeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Excellent — I would recommend it'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feedbackStarTap5')));
    await tester.pumpAndSettle();

    expect(find.text('Excellent — I would recommend it'), findsOneWidget);
  });

  testWidgets('submit sends the selected rating and trimmed comment, anonymous by default',
      (tester) async {
    final repo = _FakeFeedbackRepository();
    final db = await _memoryDb();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          feedbackRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: FeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('feedbackStarTap4')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('feedbackCommentField')), '  Great app!  ');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('feedbackSubmitTap')));
    await tester.pumpAndSettle();

    expect(repo.capturedRating, 4);
    expect(repo.capturedComment, 'Great app!');
    expect(repo.capturedDisplayName, isNull);
  });

  testWidgets('after a successful submission, the cooldown notice replaces the form',
      (tester) async {
    final repo = _FakeFeedbackRepository();
    final db = await _memoryDb();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          feedbackRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: FeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('feedbackStarTap3')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('feedbackCommentField')), 'Decent');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feedbackSubmitTap')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('feedbackCommentField')), findsNothing);
    expect(find.textContaining('Thanks for your feedback'), findsOneWidget);
  });

  testWidgets('the shared feed renders every entry from the repository', (tester) async {
    final repo = _FakeFeedbackRepository(
      feed: [
        AppFeedback(id: '1', displayName: 'Chidi', rating: 5, comment: 'Love it', createdAt: _now),
        AppFeedback(id: '2', displayName: null, rating: 2, comment: 'Needs work', createdAt: _now),
      ],
    );
    final db = await _memoryDb();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          feedbackRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: FeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Love it'), findsOneWidget);
    expect(find.text('Chidi'), findsOneWidget);
    expect(find.text('Needs work'), findsOneWidget);
    expect(find.text('Anonymous student'), findsOneWidget);
  });
}
