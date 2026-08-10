/// Reusable stat tile — label over value, optionally with a leading icon.
/// Used anywhere the app shows a row of small computed facts (dashboard
/// quick stats, Results summary, Reports cards).
library;

import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const StatTile({super.key, required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
