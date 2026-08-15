import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/step_repository.dart';
import '../data/services/steps_sync_service.dart';
import 'core_providers.dart';
import 'meal_providers.dart';

final stepRepositoryProvider = Provider<StepRepository>((ref) {
  return StepRepository(ref.watch(databaseProvider));
});

final stepsSyncServiceProvider = Provider<StepsSyncService>((ref) {
  return StepsSyncService(ref.watch(stepRepositoryProvider));
});

final stepsForSelectedDayProvider = StreamProvider<int>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(stepRepositoryProvider).watchStepsForDay(day);
});

final recentStepsProvider = StreamProvider.autoDispose<List<StepDay>>((ref) {
  return ref.watch(stepRepositoryProvider).watchRecentDays(limitDays: 14);
});

/// Kick off a background sync; safe to call often (service debounces).
final stepsSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(stepsSyncServiceProvider).syncRecent(limitDays: 14);
});
