/// Calendar-marks state for the Study tab. Local-only, like every other
/// per-device StateNotifier here (notes, achievements, etc.) -- loaded once
/// from Drift, then kept in memory and written straight back on every
/// change so the UI never waits on a round trip to reflect a tap.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/calendar_mark.dart';
import '../../domain/repositories/calendar_repository.dart';
import 'repository_providers.dart';

const _uuid = Uuid();

class CalendarMarksController extends StateNotifier<List<CalendarMark>> {
  final CalendarRepository? _repository;

  CalendarMarksController(this._repository) : super(const []) {
    unawaited(_load());
  }

  CalendarMarksController.seeded(List<CalendarMark> marks)
      : _repository = null,
        super(marks);

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) return;
    state = await repo.loadMarks();
  }

  CalendarMark? markFor(DateTime date) {
    final normalized = normalizeDate(date);
    for (final mark in state) {
      if (mark.date == normalized) return mark;
    }
    return null;
  }

  /// Toggles the mark for [date]: creates one if none exists, removes it if
  /// one already does (a bare tap, no note). Use [setNote] to attach text
  /// to an already-marked date without toggling it off.
  Future<void> toggle(DateTime date) async {
    final existing = markFor(date);
    if (existing != null) {
      await _remove(existing);
    } else {
      await _add(date, note: null);
    }
  }

  Future<void> setNote(DateTime date, String? note) async {
    final existing = markFor(date);
    if (existing == null) {
      await _add(date, note: note);
      return;
    }
    final repo = _repository;
    if (repo != null) await repo.setMark(id: existing.id, date: date, note: note);
    final now = DateTime.now();
    state = [
      for (final m in state)
        if (m.id == existing.id)
          CalendarMark(id: m.id, profileId: m.profileId, date: m.date, note: note, createdAt: m.createdAt, updatedAt: now)
        else
          m,
    ];
  }

  Future<void> _add(DateTime date, {String? note}) async {
    final normalized = normalizeDate(date);
    final id = _uuid.v4();
    final repo = _repository;
    if (repo != null) await repo.setMark(id: id, date: normalized, note: note);
    final now = DateTime.now();
    state = [
      ...state,
      CalendarMark(id: id, profileId: '', date: normalized, note: note, createdAt: now, updatedAt: now),
    ];
  }

  Future<void> _remove(CalendarMark mark) async {
    await _repository?.removeMark(mark.id);
    state = state.where((m) => m.id != mark.id).toList();
  }
}

final calendarMarksProvider = StateNotifierProvider<CalendarMarksController, List<CalendarMark>>(
  (ref) => CalendarMarksController(ref.watch(calendarRepositoryProvider)),
);
