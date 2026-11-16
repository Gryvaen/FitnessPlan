import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calendar_day.dart';
import '../../domain/cut_cultivation.dart';

class CultivationRepository {
  CultivationRepository(this._prefs);

  static const _key = 'cut_cultivation_state';

  final SharedPreferences _prefs;

  CutCultivationState load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const CutCultivationState();
    try {
      return CutCultivationState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const CutCultivationState();
    }
  }

  Future<void> save(CutCultivationState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  /// Bank open-segment kcal into [frozenKcal] and close that segment on [endDay].
  Future<CutCultivationState> freezeOpenSegment({
    required double openSegmentKcal,
    required DateTime endDay,
  }) async {
    final current = load();
    final open = current.openSegment;
    if (open == null) return current;

    // A stretch that hadn't started by [endDay] (e.g. a booked switch dated
    // before a same-day re-entry into cut) never ran: drop it rather than
    // store one that ends before it begins.
    final end = CalendarDay.dayOnly(endDay);
    final closed = [
      for (final s in current.segments)
        if (!s.isOpen)
          s
        else if (!end.isBefore(CalendarDay.dayOnly(s.start)))
          s.closeOn(end),
    ];
    final next = CutCultivationState(
      frozenKcal: current.frozenKcal + openSegmentKcal,
      segments: closed,
    );
    await save(next);
    return next;
  }

  /// Start a new open cut stretch. If the previous stretch ended today,
  /// the new one begins tomorrow to avoid double-counting.
  Future<CutCultivationState> openSegment({DateTime? preferredStart}) async {
    final current = load();
    if (current.openSegment != null) return current;

    final today = CalendarDay.todayLocal();
    final lastEnd = current.segments.isEmpty ? null : current.segments.last.end;
    var start = CalendarDay.dayOnly(preferredStart ?? today);
    if (lastEnd != null && !start.isAfter(CalendarDay.dayOnly(lastEnd))) {
      start = CalendarDay.addDays(lastEnd, 1);
    }
    final next = current.copyWith(
      segments: [
        ...current.segments,
        CutCultivationSegment(start: start),
      ],
    );
    await save(next);
    return next;
  }

  /// Ensure an open segment exists for a user already on cut (migration / first run).
  Future<CutCultivationState> ensureOpenSegment({DateTime? preferredStart}) async {
    final current = load();
    if (current.openSegment != null) return current;
    return openSegment(preferredStart: preferredStart);
  }
}
