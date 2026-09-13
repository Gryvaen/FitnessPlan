import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/repositories/step_repository.dart';
import '../data/services/android_step_sensor.dart';
import '../data/services/steps_sync_service.dart';
import 'core_providers.dart';
import 'meal_providers.dart';

final stepRepositoryProvider = Provider<StepRepository>((ref) {
  return StepRepository(ref.watch(databaseProvider));
});

final androidStepSensorProvider = Provider<AndroidStepSensor>((ref) {
  return AndroidStepSensor();
});

final stepsSyncServiceProvider = Provider<StepsSyncService>((ref) {
  return StepsSyncService(
    ref.watch(stepRepositoryProvider),
    stepSensor: ref.watch(androidStepSensorProvider),
  );
});

final stepsForSelectedDayProvider = StreamProvider<int>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(stepRepositoryProvider).watchStepsForDay(day);
});

final recentStepsProvider = StreamProvider.autoDispose<List<StepDay>>((ref) {
  return ref.watch(stepRepositoryProvider).watchRecentDays(limitDays: 14);
});

/// Every logged step day (may span well beyond the recent sync window).
final allStepsProvider = StreamProvider.autoDispose<List<StepDay>>((ref) {
  return ref.watch(stepRepositoryProvider).watchAllLoggedDays();
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

  /// User-initiated retry: re-shows permission prompts if needed.
  Future<StepsSyncStatus> resync() async {
    final status = await ref
        .read(stepsSyncServiceProvider)
        .syncRecent(limitDays: 14, forcePrompt: true);
    state = status;
    return status;
  }
}

/// Whether the always-on background step-counting service is enabled
/// (Android only). Turning it on requests activity-recognition + notification
/// permission and kicks a resync.
final stepServiceProvider = NotifierProvider<StepServiceNotifier, bool>(
  StepServiceNotifier.new,
);

class StepServiceNotifier extends Notifier<bool> {
  /// Set once the user's choice (on or off) has been persisted, so a fresh
  /// install only gets auto-enabled once and a later manual "off" sticks.
  static const _choiceSetKey = 'step_service_user_choice_set';

  @override
  bool build() {
    _load();
    return false;
  }

  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _load() async {
    final sensor = ref.read(androidStepSensorProvider);
    final on = await sensor.isServiceEnabled();
    if (!ref.mounted) return;
    if (on) {
      state = true;
      return;
    }
    if (!isAvailable) return;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_choiceSetKey) ?? false) return;
    // Nobody has explicitly chosen a state yet (fresh install, or an
    // existing install predating this flag) — default to on, like Huawei
    // Health, instead of leaving background tracking off until a user finds
    // this sheet's switch.
    await setEnabled(true);
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_choiceSetKey, true);
    if (enabled) {
      final activity = await Permission.activityRecognition.request();
      if (!activity.isGranted) return;
      await Permission.notification.request();
    }
    if (ref.mounted) state = enabled;
    await ref.read(androidStepSensorProvider).setServiceEnabled(enabled);
    if (enabled) {
      ref.invalidate(stepsSyncProvider);
    }
  }
}

/// Kick off a background sync; concurrent calls share one in-flight run.
final stepsSyncProvider = FutureProvider.autoDispose<StepsSyncStatus>((
  ref,
) async {
  final status = await ref
      .read(stepsSyncServiceProvider)
      .syncRecent(limitDays: 14);
  if (ref.mounted) {
    ref.read(stepsSyncStatusProvider.notifier).setStatus(status);
  }
  return status;
});
