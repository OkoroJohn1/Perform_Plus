/// Inline "coming later" row for a V2 feature living alongside V1 content
/// on the same screen (e.g. Strength Analysis next to Results/Roadmap/
/// Reports). For a feature that owns its whole screen, use [EmptyState]'s
/// `unlockCondition` instead — this widget is for one row among others.
library;

import 'package:flutter/material.dart';

class LockedFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;

  const LockedFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeLabel = 'V2',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Opacity(
      opacity: 0.6,
      child: ListTile(
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(badgeLabel),
          visualDensity: VisualDensity.compact,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
