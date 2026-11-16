import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/goal_period.dart';

/// SharedPreferences-backed record of the profile's goal stretches, for the
/// deficit calendar's brackets. Display only: cultivation keeps its own cut
/// rounds.
class GoalHistoryRepository {
  GoalHistoryRepository(this._prefs);

  static const key = 'goal_periods';

  final SharedPreferences _prefs;

  /// The stored stretches; with none stored yet, [backfill]'s result, which
  /// is saved so it is only reconstructed once.
  List<GoalPeriod> load({required List<GoalPeriod> Function() backfill}) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      final periods = backfill();
      save(periods);
      return periods;
    }
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          ?GoalPeriod.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<GoalPeriod> periods) =>
      _prefs.setString(key, jsonEncode([for (final p in periods) p.toJson()]));

  Future<void> clear() => _prefs.remove(key);
}
