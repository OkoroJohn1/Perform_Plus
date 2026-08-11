/// The five-tab shell.
///
/// Your original board had 14 sibling destinations hanging off the
/// dashboard with a 5-item bottom bar — Roadmap, Reading, Exams, Reports,
/// Achievements, Settings and Notifications had no home. Grouping by what
/// the student is DOING rather than by feature fixes that, and tells you
/// where a future feature belongs without re-litigating it every sprint.
///
///   Academics -> "where do I stand"
///   Study     -> "what do I do about it"
///
/// Notifications live as a bell in the Home header, not a tab. Nobody
/// navigates to notifications; they respond to a badge.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'gradient_scaffold.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = Routes.tabIndexFor(location);

    return GradientScaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(Routes.tabOrder[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Academics',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
