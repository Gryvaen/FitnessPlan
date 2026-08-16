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

/// Last completed sync outcome. Null only before the first attempt finishes.
final stepsSyncStatusProvider =
    NotifierProvider<StepsSyncStatusNotifier, StepsSyncStatus?>(
  StepsSyncStatusNotifier.new,
);

class StepsSyncStatusNotifier extends Notifier<StepsSyncStatus?> {
  @override
  StepsSyncStatus? build() => null;

  void setStatus(StepsSyncStatus status) => state = status;
}

/// Kick off a background sync; concurrent calls share one in-flight run.
final stepsSyncProvider = FutureProvider.autoDispose<StepsSyncStatus>((ref) async {
  final status =
      await ref.read(stepsSyncServiceProvider).syncRecent(limitDays: 14);
  if (ref.mounted) {
    ref.read(stepsSyncStatusProvider.notifier).setStatus(status);
  }
  return status;
});
