/// A month-grid calendar on the Study tab a student taps to mark study
/// days -- "realtime" in the sense that a tap updates the mark and the
/// Drift-backed provider immediately, not via any network round trip
/// (there is no remote calendar to sync against; this is a personal,
/// local-only planning aid like the rest of the Study tab).
///
/// Long-pressing a marked day opens a small note field -- e.g. "Chapter 4
/// exercises" -- so a mark can carry more than a bare yes/no.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/calendar_provider.dart';
import '../../../domain/models/calendar_mark.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class StudyCalendarCard extends ConsumerStatefulWidget {
  const StudyCalendarCard({super.key});

  @override
  ConsumerState<StudyCalendarCard> createState() => _StudyCalendarCardState();
}

class _StudyCalendarCardState extends ConsumerState<StudyCalendarCard> {
  late DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  Future<void> _handleTap(DateTime day) async {
    final controller = ref.read(calendarMarksProvider.notifier);
    final existing = controller.markFor(day);
    if (existing == null) {
      await controller.toggle(day);
      return;
    }
    // A second tap on an already-marked day removes it -- long-press is
    // the path to editing its note instead, so a quick double-tap doesn't
    // accidentally wipe a note the student already wrote.
    await controller.toggle(day);
  }

  Future<void> _handleLongPress(DateTime day) async {
    final controller = ref.read(calendarMarksProvider.notifier);
    final existing = controller.markFor(day);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NoteDialog(initialNote: existing?.note),
    );
    if (result == null) return;
    await controller.setNote(day, result.trim().isEmpty ? null : result.trim());
  }

  @override
  Widget build(BuildContext context) {
    final marks = ref.watch(calendarMarksProvider);
    final accent = context.palette.primary;
    final today = normalizeDate(DateTime.now());

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // DateTime.weekday: Monday=1 ... Sunday=7. Leading blanks before day 1.
    final leadingBlanks = firstOfMonth.weekday - 1;

    final markedDates = {for (final m in marks) m.date};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Study calendar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey('calendarPrevMonthTap'),
                icon: const Icon(Icons.chevron_left, size: 22),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _shiftMonth(-1),
              ),
              Flexible(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                key: const ValueKey('calendarNextMonthTap'),
                icon: const Icon(Icons.chevron_right, size: 22),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a day to mark it studied; long-press to add a note.',
            style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(label, style: TextStyle(color: context.palette.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final dayNumber = index - leadingBlanks + 1;
              final day = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final isToday = day == today;
              final mark = markedDates.contains(day)
                  ? marks.firstWhere((m) => m.date == day)
                  : null;

              return Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: mark != null ? accent : Colors.transparent,
                  shape: CircleBorder(
                    side: isToday && mark == null ? BorderSide(color: accent, width: 1.4) : BorderSide.none,
                  ),
                  child: InkWell(
                    key: ValueKey('calendarDay_${day.toIso8601String()}'),
                    customBorder: const CircleBorder(),
                    onTap: () => _handleTap(day),
                    onLongPress: () => _handleLongPress(day),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: mark != null ? Colors.white : context.palette.bodyText,
                              fontSize: 13.5,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (mark?.note != null)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String? initialNote;

  const _NoteDialog({this.initialNote});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _controller = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note for this day'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'e.g. Chapter 4 exercises'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
