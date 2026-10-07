/// Per-document time breakdown -- the "Study hours" tile (see
/// `study_shell.dart`'s `_StudyOverview`) is the aggregate across every
/// document; this card is the per-document half, listing EVERY uploaded
/// note (not just ones with logged time -- a freshly uploaded document
/// shows 0m, since it genuinely has none yet, rather than being silently
/// left out). Deliberately a different visual language from `_NoteRow`'s
/// "My Notes" list below it (icon + title + page-progress bar) -- this one
/// leads with the time figure itself, ranked by most time spent first, on
/// a soft frosted surface rather than a plain list row.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/note_provider.dart';
import '../../../domain/models/note.dart';

/// "42m" under an hour, "1h 05m" at or beyond -- same precision as the
/// aggregate "Study hours" tile and the inline per-note label on `_NoteRow`.
String formatStudyTime(int seconds) {
  final totalMinutes = seconds ~/ 60;
  if (totalMinutes < 60) return '${totalMinutes}m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

class StudyTimeBreakdownCard extends StatelessWidget {
  final NotesState state;

  const StudyTimeBreakdownCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.notes.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final ordered = [...state.notes]
      ..sort((a, b) {
        final cmp = state.activeSecondsFor(b.id).compareTo(state.activeSecondsFor(a.id));
        return cmp != 0 ? cmp : b.uploadedAt.compareTo(a.uploadedAt);
      });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.surfaceBorder, width: 1.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primary.withValues(alpha: 0.14), palette.surface.withValues(alpha: 0.78)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_bottom_outlined, size: 18, color: palette.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Time per document',
                    style: TextStyle(color: palette.bodyText, fontSize: 16.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Your reading time across every upload — new documents start at 0m.',
                style: TextStyle(color: palette.secondaryText, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < ordered.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _TimeBreakdownRow(note: ordered[i], seconds: state.activeSecondsFor(ordered[i].id)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBreakdownRow extends StatelessWidget {
  final Note note;
  final int seconds;

  const _TimeBreakdownRow({required this.note, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color(note.colour);
    final hasTime = seconds > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.bodyText, fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatStudyTime(seconds),
            style: TextStyle(
              color: hasTime ? palette.primary : palette.hintText,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
