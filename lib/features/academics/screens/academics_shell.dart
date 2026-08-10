import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reports_view.dart';
import 'results_view.dart';
import 'roadmap_view.dart';

enum _AcademicsTab { results, roadmap, reports }

/// Academics tab. Segmented control across Results (default), Roadmap and
/// Reports. Strength Analysis lands as a locked row within Reports — it's
/// V2, see [ReportsView].
class AcademicsShell extends ConsumerStatefulWidget {
  const AcademicsShell({super.key});

  @override
  ConsumerState<AcademicsShell> createState() => _AcademicsShellState();
}

class _AcademicsShellState extends ConsumerState<AcademicsShell> {
  _AcademicsTab _tab = _AcademicsTab.results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<_AcademicsTab>(
              segments: const [
                ButtonSegment(value: _AcademicsTab.results, label: Text('Results')),
                ButtonSegment(value: _AcademicsTab.roadmap, label: Text('Roadmap')),
                ButtonSegment(value: _AcademicsTab.reports, label: Text('Reports')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _AcademicsTab.results => const ResultsView(),
              _AcademicsTab.roadmap => const RoadmapView(),
              _AcademicsTab.reports => const ReportsView(),
            },
          ),
        ],
      ),
    );
  }
}
