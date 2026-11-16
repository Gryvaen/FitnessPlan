import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/goal_history_repository.dart';
import '../domain/goal_period.dart';
import '../domain/models.dart';
import 'core_providers.dart';
import 'cultivation_providers.dart';
import 'profile_providers.dart';

final goalHistoryRepositoryProvider = Provider<GoalHistoryRepository>((ref) {
  return GoalHistoryRepository(ref.watch(sharedPreferencesProvider));
});

/// The profile's goal stretches (see [GoalPeriod]), oldest first.
final goalPeriodsProvider =
    NotifierProvider<GoalPeriodsNotifier, List<GoalPeriod>>(
      GoalPeriodsNotifier.new,
    );

class GoalPeriodsNotifier extends Notifier<List<GoalPeriod>> {
  @override
  List<GoalPeriod> build() => _load();

  List<GoalPeriod> _load() => ref
      .read(goalHistoryRepositoryProvider)
      .load(
        backfill: () => backfillGoalPeriods(
          ref.read(cutCultivationStateProvider).segments,
          ref.read(profileProvider),
        ),
      );

  /// Records a switch to [goal] starting on [day] (see [switchGoalPeriods]).
  Future<void> switchTo(FitnessGoal goal, DateTime day) async {
    final next = switchGoalPeriods(state, goal, day);
    if (identical(next, state)) return;
    await ref.read(goalHistoryRepositoryProvider).save(next);
    state = next;
  }

  void reload() => state = _load();
}
