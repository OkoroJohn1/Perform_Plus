/// Study tab — rebuilt around e-notes, the only real daily hook in V1 (see
/// AGENTS.md: the core CGPA loop fires roughly twice a year). The mockup's
/// "Courses Enrolled / topics completed" implied a course catalogue and
/// syllabus taxonomy that doesn't exist in this app; everything here is
/// built on notes the student actually uploads, which is real data.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/note_provider.dart';
import '../../../data/repositories/notification_provider.dart';
import '../../../domain/engine/study_engine.dart';
import '../../../domain/models/note.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/glass_top_bar.dart';
import '../../home/screens/notifications_panel.dart';
import '../providers/study_plan_provider.dart';
import '../widgets/note_illustration.dart';
import '../widgets/study_calendar_card.dart';
import '../widgets/upload_note_sheet.dart';
import 'study_advice_reveal_screen.dart';

IconData _fileGlyph(NoteFileType type) =>
    type == NoteFileType.pdf ? Icons.picture_as_pdf : Icons.image_outlined;

int _pagesRead(NotesState state, Note note) => state.pagesReadFor(note.id);

bool _isCompleted(NotesState state, Note note) =>
    note.totalPages > 0 && _pagesRead(state, note) >= note.totalPages;

/// "42m" under an hour, "1h 05m" at or beyond -- matches the aggregate
/// "Study hours" tile's precision at a glance without needing a decimal.
String _formatStudyTime(int seconds) {
  final totalMinutes = seconds ~/ 60;
  if (totalMinutes < 60) return '${totalMinutes}m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

void _openReader(BuildContext context, String noteId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => StudyAdviceRevealScreen(noteId: noteId)),
  );
}

class StudyShell extends ConsumerWidget {
  const StudyShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final hasNotes = notesState.notes.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.palette.background,
        drawer: const AppDrawer(),
        appBar: const _StudyAppBar(),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            children: [
              const _HeroBanner(),
              const SizedBox(height: 16),
              const _HonestyNotice(),
              const SizedBox(height: 24),
              const StudyCalendarCard(),
              const SizedBox(height: 26),
              if (hasNotes) ...[
                const _SectionHeader(title: 'Study overview'),
                const SizedBox(height: 12),
                _StudyOverview(state: notesState),
                const SizedBox(height: 26),
                _MyNotesSection(state: notesState),
                const SizedBox(height: 16),
                _UploadButton(onPressed: () => showUploadNoteSheet(context)),
                const SizedBox(height: 24),
                const _TodaysPlanSection(),
              ] else ...[
                _EmptyNotesBlock(onUpload: () => showUploadNoteSheet(context)),
              ],
              const SizedBox(height: 26),
              const _SectionHeader(title: 'Study tools'),
              const SizedBox(height: 16),
              const _StudyToolsGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.palette.bodyText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _StudyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StudyAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarGlassBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Builder(
                  builder: (context) => Material(
                    color: context.palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.menu, size: 22, color: context.palette.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Study',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
                const _NotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider.select((n) => n.any((x) => !x.isRead)));

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF4B5563)),
              onPressed: () => showNotificationsPanel(context),
            ),
          ),
          if (unread)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: context.palette.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [context.palette.primary.withValues(alpha: 0.22), context.palette.surface]
              : const [Color(0xFFF1EFFE), Color(0xFFFAF9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'Stay consistent,\nachieve '),
                      TextSpan(
                        text: 'excellence.',
                        style: TextStyle(color: context.palette.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Small daily actions lead to big academic wins.',
                  style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
                ),
              ],
            ),
          ),
          const Expanded(flex: 2, child: Center(child: NoteIllustration())),
        ],
      ),
    );
  }
}

/// A friendly, non-judgemental honesty check -- the reading timer only
/// knows the app was open and active, never whether the student actually
/// absorbed anything (see `note_reader_screen.dart`'s own doc comment on
/// this same limit). Leaving a document open without reading it produces a
/// real-looking "study hours" number that means nothing; this says so
/// plainly rather than letting that number quietly mislead the student
/// about their own progress.
class _HonestyNotice extends StatelessWidget {
  const _HonestyNotice();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.amberBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: palette.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You can leave a document open without really studying -- the timer "
              "can't tell. That choice is yours, but it's only ever yourself you'd be fooling.",
              style: TextStyle(color: palette.amber, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyOverview extends StatelessWidget {
  final NotesState state;

  const _StudyOverview({required this.state});

  @override
  Widget build(BuildContext context) {
    final completed = state.notes.where((n) => _isCompleted(state, n)).length;
    final hours = state.totalActiveSeconds / 3600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _OverviewTile(
                icon: Icons.description_outlined,
                value: '${state.notes.length}',
                label: 'E-notes uploaded',
              ),
            ),
            const _TileDivider(),
            Expanded(
              child: _OverviewTile(icon: Icons.task_alt, value: '$completed', label: 'Notes completed'),
            ),
            const _TileDivider(),
            Expanded(
              child: _OverviewTile(
                icon: Icons.schedule,
                value: hours.toStringAsFixed(1),
                label: 'Study hours',
              ),
            ),
            const _TileDivider(),
            Expanded(
              child: _OverviewTile(
                icon: Icons.local_fire_department,
                value: '${state.displayStreak}',
                label: 'Day streak',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const VerticalDivider(width: 1, color: Color(0xFFECECF1));
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _OverviewTile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.palette.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 22, color: context.palette.primary),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(color: context.palette.bodyText, fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(color: context.palette.secondaryText, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _MyNotesSection extends StatelessWidget {
  final NotesState state;

  const _MyNotesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final ordered = [...state.notes]
      ..sort((a, b) => (b.lastOpenedAt ?? b.uploadedAt).compareTo(a.lastOpenedAt ?? a.uploadedAt));
    final shown = ordered.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'My notes',
          action: TextButton(
            onPressed: () => _showAllNotes(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View all', style: TextStyle(color: context.palette.primary, fontSize: 15.5, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, size: 18, color: context.palette.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.palette.surface,
            border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 76, color: Color(0xFFECECF1)),
                _NoteRow(
                  note: shown[i],
                  pagesRead: _pagesRead(state, shown[i]),
                  activeSeconds: state.activeSecondsFor(shown[i].id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

void _showAllNotes(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _AllNotesSheet(),
  );
}

class _AllNotesSheet extends ConsumerWidget {
  const _AllNotesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final notes = [...state.notes]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('All notes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Color(0xFFECECF1)),
              itemBuilder: (context, i) => _NoteRow(
                note: notes[i],
                pagesRead: _pagesRead(state, notes[i]),
                activeSeconds: state.activeSecondsFor(notes[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends ConsumerWidget {
  final Note note;
  final int pagesRead;
  final int activeSeconds;

  const _NoteRow({required this.note, required this.pagesRead, required this.activeSeconds});

  void _showContextSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final controller = TextEditingController(text: note.title);
                final newTitle = await showDialog<String>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Rename note'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (newTitle != null && newTitle.isNotEmpty) {
                  await ref.read(notesProvider.notifier).renameNote(note.id, newTitle);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reset progress'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(notesProvider.notifier).resetProgress(note.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.palette.error),
              title: Text('Delete', style: TextStyle(color: context.palette.error)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(notesProvider.notifier).deleteNote(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(note.colour);
    final fraction = progressFraction(pagesRead: pagesRead, totalPages: note.totalPages);
    final percent = (fraction * 100).round();

    return InkWell(
      onTap: () => _openReader(context, note.id),
      onLongPress: () => _showContextSheet(context, ref),
      child: SizedBox(
        height: 92,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_fileGlyph(note.fileType), size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.bodyText, fontSize: 16.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeSeconds > 0
                          ? '$pagesRead of ${note.totalPages} pages read · ${_formatStudyTime(activeSeconds)}'
                          : '$pagesRead of ${note.totalPages} pages read',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            const ColoredBox(color: Color(0xFFF0F0F5)),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 300),
                              alignment: Alignment.centerLeft,
                              widthFactor: fraction,
                              child: ColoredBox(color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$percent%', style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _UploadButton({required this.onPressed});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        key: const ValueKey('uploadNoteButtonTap'),
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _pressed ? context.palette.primary : null,
              gradient: _pressed
                  ? null
                  : LinearGradient(colors: [context.palette.primaryGradientStart, context.palette.primary]),
              boxShadow: [
                BoxShadow(
                  color: context.palette.primary.withValues(alpha: 0.22),
                  blurRadius: _pressed ? 4 : 16,
                  offset: _pressed ? Offset.zero : const Offset(0, 6),
                ),
                if (!_pressed)
                  BoxShadow(color: context.palette.primary.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 20, color: Colors.white),
                SizedBox(width: 12),
                Text('Upload e-note', style: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodaysPlanSection extends ConsumerWidget {
  const _TodaysPlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(studyPlanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: "Today's plan",
          action: TextButton(
            onPressed: () => _editPlan(context, ref),
            child: Text('Edit plan', style: TextStyle(color: context.palette.primary, fontSize: 15.5, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.palette.surface,
            border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: context.palette.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.checklist_rtl, size: 22, color: context.palette.success),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'} for today',
                      style: TextStyle(color: context.palette.bodyText, fontSize: 16.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tasks.isEmpty ? 'Nothing scheduled yet' : tasks.first.noteTitle,
                      style: TextStyle(color: context.palette.secondaryText, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ],
    );
  }

  void _editPlan(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _EditPlanSheet(),
    );
  }
}

class _EditPlanSheet extends ConsumerWidget {
  const _EditPlanSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(studyPlanProvider);
    final notes = ref.watch(notesProvider).notes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (var i = 0; i < tasks.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tasks[i].noteTitle),
                subtitle: Text('${tasks[i].targetPages} pages'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(studyPlanProvider.notifier).removeAt(i),
                ),
              ),
            if (notes.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  ref.read(studyPlanProvider.notifier).add(
                        StudyPlanTask(noteId: notes.first.id, noteTitle: notes.first.title, targetPages: 5),
                      );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add a task'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotesBlock extends StatelessWidget {
  final VoidCallback onUpload;

  const _EmptyNotesBlock({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const NoteIllustration(opacity: 0.4),
        const SizedBox(height: 20),
        Text(
          'No notes yet',
          style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Upload a PDF of your lecture notes to start tracking your reading.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.secondaryText, fontSize: 15.5),
          ),
        ),
        const SizedBox(height: 24),
        _UploadButton(onPressed: onUpload),
      ],
    );
  }
}

class _StudyToolsGrid extends StatelessWidget {
  const _StudyToolsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StudyToolTile(
                icon: Icons.edit_note,
                label: 'Notes',
                color: context.palette.primary,
                width: (constraints.maxWidth - 12) / 2,
                onTap: () => _showAllNotes(context),
              ),
              _StudyToolTile(
                icon: Icons.style_outlined,
                label: 'Flashcards',
                color: context.palette.success,
                width: (constraints.maxWidth - 12) / 2,
                onTap: () => showUploadNoteSheet(context, category: NoteCategory.flashcards),
              ),
              _StudyToolTile(
                icon: Icons.quiz_outlined,
                label: 'Past questions',
                color: const Color(0xFF3B82F6),
                width: (constraints.maxWidth - 12) / 2,
                onTap: () => showUploadNoteSheet(context, category: NoteCategory.pastQuestion),
              ),
              _StudyToolTile(
                icon: Icons.insights_outlined,
                label: 'Performance',
                color: const Color(0xFFEA580C),
                width: (constraints.maxWidth - 12) / 2,
                locked: true,
                lockedMessage: "Performance needs the AI service, which isn't connected yet.",
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudyToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final bool locked;
  final String? lockedMessage;
  final VoidCallback? onTap;

  const _StudyToolTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    this.locked = false,
    this.lockedMessage,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (locked) {
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(lockedMessage ?? 'Not available yet.', style: const TextStyle(fontSize: 15.5)),
          ),
        ),
      );
      return;
    }
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border.all(color: context.palette.surfaceBorder, width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(label, style: TextStyle(color: context.palette.bodyText, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.lock_outline, size: 14, color: context.palette.secondaryText),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
