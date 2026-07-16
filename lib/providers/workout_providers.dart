import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/repositories/workout_repository.dart';
import 'core_providers.dart';
import 'meal_providers.dart';

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchExercises();
});

final workoutPlansProvider =
    StreamProvider.autoDispose<List<WorkoutPlanSummary>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchPlans().asyncMap((_) => repo.listPlanSummaries());
});

final todayWorkoutProvider = StreamProvider<DayWorkoutSnapshot>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(workoutRepositoryProvider).watchDayWorkout(day);
});

final workoutHistoryProvider =
    FutureProvider.autoDispose<List<WorkoutHistoryDay>>((ref) {
  return ref.watch(workoutRepositoryProvider).recentHistory();
});
