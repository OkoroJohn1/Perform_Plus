/// The e-notes reader — page by page, with an honest dwell timer.
///
/// ⚠ BE HONEST ABOUT WHAT THIS MEASURES (see the task brief): it records
/// that a page was open and the app was active. It cannot detect
/// comprehension, and a student can defeat it by waiting. Every label here
/// says "Pages read", never "mastered" or "completed" — this is a progress
/// marker, not a certification.
///
/// Must work fully offline: files are local (pdfx renders from disk),
/// timers are local, progress writes straight to Drift via
/// [NotesController].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../data/repositories/note_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/engine/study_engine.dart';
import '../../../domain/models/note.dart';

/// Injected in tests so the reader's timer/pause/session-logging behaviour
/// can be exercised without a real PDF file or platform plugins — mirrors
/// `add_first_results_screen.dart`'s `debugPickImage` pattern.
abstract class PageRenderer {
  Future<int> pageCount(String filePath);

  /// Null return means "no rendering available" (used by the in-memory
  /// test fake) — the reader shows a plain placeholder instead of an image
  /// for that page rather than crashing.
  Future<Uint8List?> renderPage(String filePath, int pageNumber);
}

class PdfxPageRenderer implements PageRenderer {
  final Map<String, pdfx.PdfDocument> _openDocuments = {};

  Future<pdfx.PdfDocument> _documentFor(String filePath) async {
    final existing = _openDocuments[filePath];
    if (existing != null) return existing;
    final doc = await pdfx.PdfDocument.openFile(filePath);
    _openDocuments[filePath] = doc;
    return doc;
  }

  @override
  Future<int> pageCount(String filePath) async {
    final doc = await _documentFor(filePath);
    return doc.pagesCount;
  }

  @override
  Future<Uint8List?> renderPage(String filePath, int pageNumber) async {
    final doc = await _documentFor(filePath);
    final page = await doc.getPage(pageNumber);
    try {
      final image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      return image?.bytes;
    } finally {
      await page.close();
    }
  }

  Future<void> dispose() async {
    for (final doc in _openDocuments.values) {
      await doc.close();
    }
    _openDocuments.clear();
  }
}

class NoteReaderScreen extends ConsumerStatefulWidget {
  final String noteId;
  final PageRenderer? debugRenderer;
  final bool debugDisableWakelock;

  const NoteReaderScreen({
    super.key,
    required this.noteId,
    this.debugRenderer,
    this.debugDisableWakelock = false,
  });

  @override
  ConsumerState<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends ConsumerState<NoteReaderScreen> with WidgetsBindingObserver {
  late final PageRenderer _renderer = widget.debugRenderer ?? PdfxPageRenderer();
  late final PageController _pageController;

  /// Captured once, synchronously, in [initState] — `dispose()` needs to
  /// log the session on the way out, but by the time that async call would
  /// resolve the widget may already be unmounted, and `ref` cannot be used
  /// after disposal. A plain captured [NotesController] reference has no
  /// such restriction; it's just a Dart object.
  late final NotesController _controller;

  Note? _note;
  List<NotePage> _pages = [];
  int _currentPage = 0;
  bool _loading = true;

  PageDwellState _dwell = const PageDwellState(requiredSeconds: 8);
  Timer? _ticker;
  Timer? _idleTimer;
  bool _wakelockOn = false;

  DateTime _sessionStart = DateTime.now();
  int _sessionActiveSeconds = 0;
  int _sessionPagesRead = 0;

  final Map<int, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(notesProvider.notifier);
    _pageController = PageController();
    _sessionStart = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    await _controller.ready;
    if (!mounted) return;
    final note = ref.read(notesProvider).notes.firstWhere((n) => n.id == widget.noteId);
    final pages = await ref.read(noteRepositoryProvider).loadPages(widget.noteId);
    unawaited(_controller.touchOpened(widget.noteId));

    setState(() {
      _note = note;
      _pages = pages;
      _loading = false;
    });
    _beginPage(0);
    _resetIdleTimer();
  }

  bool _pageIsRead(int index) =>
      index < _pages.length ? _pages[index].isRead : false;

  void _beginPage(int index) {
    _currentPage = index;
    _ticker?.cancel();

    final alreadyRead = _pageIsRead(index);
    final note = _note!;
    final requiredSeconds = alreadyRead
        ? 0
        : requiredDwellSeconds(wordCount: null, isImagePage: note.fileType == NoteFileType.image);

    setState(() {
      _dwell = PageDwellState(requiredSeconds: requiredSeconds, isRead: alreadyRead);
    });

    unawaited(_cacheAround(index));
    if (!alreadyRead) _startTicker();
    _updateWakelock();
  }

  Future<void> _cacheAround(int index) async {
    if (_note == null) return;
    final window = {index - 1, index, index + 1};
    // A long document previously kept every visited page's decoded bitmap
    // resident for the whole reading session -- an unbounded, ever-growing
    // cache. Only the current page and its immediate neighbours are worth
    // keeping decoded at once; evicting the rest keeps memory bounded
    // regardless of how many pages the student has paged through.
    _imageCache.removeWhere((cached, _) => !window.contains(cached));
    for (final i in window) {
      if (i < 0 || i >= _note!.totalPages || _imageCache.containsKey(i)) continue;
      final bytes = await _renderer.renderPage(_note!.filePath, i + 1);
      if (mounted) setState(() => _imageCache[i] = bytes);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dwell.isPaused || _dwell.isRead) return;
      setState(() {
        _dwell = tickDwell(_dwell, 1);
        _sessionActiveSeconds += 1;
      });
      if (_dwell.isRead) _onPageMarkedRead();
    });
  }

  void _onPageMarkedRead() {
    _ticker?.cancel();
    HapticFeedback.lightImpact();
    _sessionPagesRead += 1;
    _controller.markPageRead(widget.noteId, _currentPage, _dwell.elapsedSeconds);
  }

  void _pause() {
    if (_dwell.isPaused) return;
    setState(() => _dwell = pauseDwell(_dwell));
    _updateWakelock();
  }

  void _resume() {
    if (!_dwell.isPaused) return;
    setState(() => _dwell = resumeDwell(_dwell));
    if (!_dwell.isRead) _startTicker();
    _updateWakelock();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 45), _pause);
    if (_dwell.isPaused) _resume();
  }

  void _updateWakelock() {
    if (widget.debugDisableWakelock) return;
    final shouldBeOn = !_dwell.isPaused && !_dwell.isRead;
    if (shouldBeOn == _wakelockOn) return;
    _wakelockOn = shouldBeOn;
    unawaited(shouldBeOn ? WakelockPlus.enable() : WakelockPlus.disable());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetIdleTimer();
    } else {
      _pause();
    }
  }

  Future<void> _endSession() async {
    if (_note == null) return;
    await _controller.logSession(
          noteId: widget.noteId,
          startedAt: _sessionStart,
          endedAt: DateTime.now(),
          pagesRead: _sessionPagesRead,
          activeSeconds: _sessionActiveSeconds,
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _idleTimer?.cancel();
    if (_wakelockOn && !widget.debugDisableWakelock) unawaited(WakelockPlus.disable());
    unawaited(_endSession());
    if (_renderer case final PdfxPageRenderer r) unawaited(r.dispose());
    super.dispose();
  }

  void _handleInteraction() => _resetIdleTimer();

  @override
  Widget build(BuildContext context) {
    if (_loading || _note == null) {
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Color(0xFF0F0F14),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final note = _note!;

    // Pushed via `Navigator.push` outside the go_router tab shell, so it
    // never inherits a per-tab `AnnotatedRegion` -- without its own, it
    // silently kept whichever status-bar style the screen underneath (Study,
    // dark icons on a light background) had left active, which read as
    // barely-visible dark icons on this screen's own near-black background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Listener(
        onPointerDown: (_) => _handleInteraction(),
        onPointerMove: (_) => _handleInteraction(),
        child: Column(
          children: [
            _TopBar(
              title: note.title,
              page: _currentPage + 1,
              totalPages: note.totalPages,
              activeSeconds: _sessionActiveSeconds,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                pageSnapping: true,
                itemCount: note.totalPages,
                onPageChanged: _beginPage,
                itemBuilder: (context, index) {
                  final bytes = _imageCache[index];
                  return Center(
                    child: bytes == null
                        ? const Icon(Icons.description_outlined, size: 64, color: Colors.white24)
                        : Image.memory(bytes, fit: BoxFit.contain),
                  );
                },
              ),
            ),
            _BottomBar(
              pagesRead: _pages.where((p) => p.isRead).length +
                  (_dwell.isRead && !_pageIsRead(_currentPage) ? 1 : 0),
              totalPages: note.totalPages,
              dwell: _dwell,
              onPrevious: _currentPage > 0
                  ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      )
                  : null,
              onNext: _currentPage < note.totalPages - 1
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      )
                  : null,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

String _formatElapsed(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _TopBar extends StatelessWidget {
  final String title;
  final int page;
  final int totalPages;
  final int activeSeconds;

  const _TopBar({
    required this.title,
    required this.page,
    required this.totalPages,
    required this.activeSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF0F0F14).withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 24, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 13, color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(width: 3),
              Text(
                _formatElapsed(activeSeconds),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              ),
              const SizedBox(width: 10),
              Text(
                '$page / $totalPages',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int pagesRead;
  final int totalPages;
  final PageDwellState dwell;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _BottomBar({
    required this.pagesRead,
    required this.totalPages,
    required this.dwell,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalPages <= 0 ? 0.0 : (pagesRead / totalPages).clamp(0.0, 1.0);

    return Container(
      height: 68,
      color: const Color(0xFF0F0F14).withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
            onPressed: onPrevious,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    ColoredBox(color: Colors.white.withValues(alpha: 0.20)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: const ColoredBox(color: Color(0xFF5B4BD4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PageTimerRing(dwell: dwell),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28, color: Colors.white),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageTimerRing extends StatelessWidget {
  final PageDwellState dwell;

  const _PageTimerRing({required this.dwell});

  @override
  Widget build(BuildContext context) {
    if (dwell.isRead) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.check_circle, size: 24, color: Color(0xFF16A34A)),
      );
    }
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(painter: _RingPainter(progress: dwell.progress)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      6.2832,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * progress,
      false,
      Paint()
        ..color = const Color(0xFF5B4BD4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
