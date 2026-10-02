import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:perform_plus/core/router/routes.dart';
import 'package:perform_plus/data/local/app_database.dart';
import 'package:perform_plus/data/repositories/repository_providers.dart';
import 'package:perform_plus/shared/widgets/app_scaffold.dart';

Widget _appAt(String location) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      for (final path in Routes.tabOrder)
        GoRoute(path: path, builder: (_, __) => const AppScaffold(child: SizedBox())),
    ],
  );
  // AppScaffold reads `advisorFabPositionProvider` (for the freely
  // draggable chat button), which needs a real ProviderScope -- it didn't
  // before that feature existed, when AppScaffold was a plain
  // StatefulWidget. `appDatabaseProvider` is overridden the same way every
  // other widget test overrides it: the real implementation hits
  // path_provider platform channels, which throw/hang in a plain
  // `flutter test` run.
  //
  // GlassNavBar's gradient drifts on a perpetual repeat(reverse: true) --
  // pumpAndSettle never settles against a perpetual animation. Reusing the
  // ambient MediaQueryData (via copyWith) rather than a bare
  // `const MediaQueryData(...)` matters: the latter's `size` defaults to
  // `Size.zero`, which would break any layout that reads MediaQuery.size.
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
    ],
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const fabKey = ValueKey('advisorFabTap');

  testWidgets('the advisor FAB shows on Home, Academics and Study', (tester) async {
    for (final tab in [Routes.home, Routes.academics, Routes.study]) {
      await tester.pumpWidget(_appAt(tab));
      await tester.pumpAndSettle();
      expect(find.byKey(fabKey), findsOneWidget, reason: 'expected the FAB on $tab');
    }
  });

  testWidgets('the advisor FAB is hidden on the AI tab -- you are already there', (tester) async {
    await tester.pumpWidget(_appAt(Routes.ai));
    await tester.pumpAndSettle();

    expect(find.byKey(fabKey), findsNothing);
  });

  testWidgets('the advisor FAB is hidden on Me -- nothing there to advise on', (tester) async {
    await tester.pumpWidget(_appAt(Routes.me));
    await tester.pumpAndSettle();

    expect(find.byKey(fabKey), findsNothing);
  });
}
