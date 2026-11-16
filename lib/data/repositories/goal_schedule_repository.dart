import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';

/// A profile-goal switch booked for a later day (e.g. 均衡维持 applied
/// "from tomorrow"). Only one can be pending at a time.
class PendingGoalSwitch {
  const PendingGoalSwitch({
    required this.goal,
    required this.from,
    this.proteinPerKg,
    this.fatPerKg,
  });

  final FitnessGoal goal;

  /// First day on the new goal (day-only).
  final DateTime from;

  /// 维持 protein rate picked when booking (null keeps the profile's).
  final double? proteinPerKg;

  /// 维持 fat rate picked when booking (null keeps the profile's).
  final double? fatPerKg;

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'from': StrategyDates.encode(from),
    'proteinPerKg': ?proteinPerKg,
    'fatPerKg': ?fatPerKg,
  };

  static PendingGoalSwitch? fromJson(Map<String, dynamic> json) {
    final goal = FitnessGoal.values.asNameMap()[json['goal']];
    final from = StrategyDates.tryDecode(json['from'] as String?);
    if (goal == null || from == null) return null;
    return PendingGoalSwitch(
      goal: goal,
      from: from,
      proteinPerKg: (json['proteinPerKg'] as num?)?.toDouble(),
      fatPerKg: (json['fatPerKg'] as num?)?.toDouble(),
    );
  }
}

/// SharedPreferences-backed store for the [PendingGoalSwitch].
class GoalScheduleRepository {
  GoalScheduleRepository(this._prefs);

  static const key = 'pending_goal_switch';

  final SharedPreferences _prefs;

  PendingGoalSwitch? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return PendingGoalSwitch.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PendingGoalSwitch pending) =>
      _prefs.setString(key, jsonEncode(pending.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
