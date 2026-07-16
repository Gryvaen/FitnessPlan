import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calculator_engine.dart';

class CalculatorHistoryRepository {
  CalculatorHistoryRepository(this._prefs);

  static const _key = 'calculator_history_v1';
  static const maxEntries = 50;

  final SharedPreferences _prefs;

  List<CalcHistoryEntry> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          CalcHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<CalcHistoryEntry>> add(CalcHistoryEntry entry) async {
    final next = [entry, ...load()].take(maxEntries).toList();
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in next) e.toJson()]),
    );
    return next;
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
