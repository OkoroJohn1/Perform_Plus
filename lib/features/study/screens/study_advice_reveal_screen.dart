/// A forced, un-skippable 6-second pause shown every time a document is
/// opened, before the reader itself — a short piece of honest advice about
/// actually studying rather than just leaving the document open. See
/// `study_engine.dart`'s `studyAdviceMessages`/`randomStudyAdvice` for the
/// (deliberately not invented per-session) list this draws from, and
/// `study_shell.dart`'s `_HonestyNotice` for the companion reminder that
/// this screen's own existence doesn't make it impossible to zone out.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/engine/study_engine.dart';
import '../../../shared/widgets/advisor_mark.dart';
import 'note_reader_screen.dart';

class StudyAdviceRevealScreen extends StatefulWidget {
  final String noteId;

  /// Injected in tests for a deterministic pick instead of `Random()`.
  final Random? debugRandom;

  const StudyAdviceRevealScreen({super.key, required this.noteId, this.debugRandom});

  @override
  State<StudyAdviceRevealScreen> createState() => _StudyAdviceRevealScreenState();
}

class _StudyAdviceRevealScreenState extends State<StudyAdviceRevealScreen> {
  late final String _advice = randomStudyAdvice(widget.debugRandom);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: studyAdviceRevealSeconds), _advance);
  }

  void _advance() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => NoteReaderScreen(noteId: widget.noteId)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // Deliberately not skippable -- see this file's doc comment.
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF0F0F14),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdvisorMark(size: 56, color: Colors.white),
                  const SizedBox(height: 28),
                  Text(
                    _advice,
                    key: const ValueKey('studyAdviceText'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
