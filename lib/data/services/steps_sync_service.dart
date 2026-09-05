import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/calendar_day.dart';
import '../repositories/step_repository.dart';
import 'android_step_sensor.dart';

/// Result of syncing steps from HealthKit / Health Connect / device sensor.
enum StepsSyncStatus {
  /// Desktop / web — no system health store.
  unsupported,

  /// Activity recognition or health read permission not granted, and sensor
  /// fallback was unavailable.
  denied,

  /// Authorized and daily totals were read successfully (may still be 0).
  connected,

  /// Unexpected failure while reading or writing step totals.
  failed,
}

/// Syncs daily step totals from HealthKit / Health Connect into [StepRepository].
///
/// On Android, when Health Connect is missing or returns 0 for today (common on
/// OPPO / ColorOS and other OEMs without a HC data source), falls back to the
/// hardware [Sensor.TYPE_STEP_COUNTER] for today's total.
class StepsSyncService {
  StepsSyncService(
    this._repo, {
    Health? health,
    this._stepSensor,
  }) : _health = health ?? Health();

  final StepRepository _repo;
  final Health _health;
  final AndroidStepSensor? _stepSensor;

  bool _configured = false;
  Future<StepsSyncStatus>? _inFlight;

  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> _ensureActivityRecognition() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Returns whether Health Connect / HealthKit read access was granted.
  /// Does not wipe existing DB rows when authorization fails.
  Future<bool> ensureAuthorized() async {
    if (!isPlatformSupported) return false;
    try {
      await _ensureConfigured();
      if (!await _ensureActivityRecognition()) return false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) return false;
      }
      final types = <HealthDataType>[HealthDataType.STEPS];
      final permissions = <HealthDataAccess>[HealthDataAccess.READ];
      final ok = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!ok) return false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final historyOk = await _health.isHealthDataHistoryAuthorized();
          if (!historyOk) {
            await _health.requestHealthDataHistoryAuthorization();
          }
        } catch (_) {
          // Optional on older Health Connect; ignore.
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pull today + previous [limitDays]-1 days and upsert. Missing → 0.
  ///
  /// Concurrent callers share the in-flight run instead of getting a
  /// short-circuit result, so every caller observes the real outcome.
  Future<StepsSyncStatus> syncRecent({int limitDays = 14}) {
    if (!isPlatformSupported) {
      return Future.value(StepsSyncStatus.unsupported);
    }
    return _inFlight ??= _run(limitDays).whenComplete(() => _inFlight = null);
  }

  Future<StepsSyncStatus> _run(int limitDays) async {
    try {
      if (!await _ensureActivityRecognition()) {
        // Still try sensor? ACTIVITY_RECOGNITION is required for step sensor
        // on Android 10+. Without it both paths fail.
        return StepsSyncStatus.denied;
      }

      final authorized = await ensureAuthorized();
      var readsOk = 0;
      var readsFailed = 0;
      var todayFromHealth = 0;

      if (authorized) {
        final today = CalendarDay.todayLocal();
        final now = DateTime.now();
        for (var i = 0; i < limitDays; i++) {
          final day = CalendarDay.dayOnly(today.subtract(Duration(days: i)));
          final start = day;
          final end = i == 0
              ? now
              : start
                  .add(const Duration(days: 1))
                  .subtract(const Duration(milliseconds: 1));
          try {
            final total = await _health.getTotalStepsInInterval(start, end);
            final value = total ?? 0;
            await _repo.setStepsForDay(day, value);
            if (i == 0) todayFromHealth = value;
            readsOk++;
          } catch (_) {
            // Keep any existing DB value for this day.
            readsFailed++;
          }
        }
      }

      final usedSensor = await _maybeApplySensorFallback(
        healthToday: authorized ? todayFromHealth : null,
        healthAuthorized: authorized,
      );

      if (authorized) {
        if (readsOk == 0 && readsFailed > 0 && !usedSensor) {
          return StepsSyncStatus.failed;
        }
        return StepsSyncStatus.connected;
      }

      if (usedSensor) return StepsSyncStatus.connected;
      return StepsSyncStatus.denied;
    } catch (_) {
      return StepsSyncStatus.failed;
    }
  }

  /// When Health Connect has no today's data (or is unavailable), use the
  /// OEM step counter. Returns true if a sensor value was written.
  Future<bool> _maybeApplySensorFallback({
    required int? healthToday,
    required bool healthAuthorized,
  }) async {
    final sensor = _stepSensor;
    if (sensor == null || !AndroidStepSensor.isSupported) return false;
    if (healthAuthorized && (healthToday ?? 0) > 0) return false;

    final sensorToday = await sensor.readTodaySteps();
    if (sensorToday == null) return false;

    if (!healthAuthorized || sensorToday > (healthToday ?? 0)) {
      await _repo.setStepsForDay(CalendarDay.todayLocal(), sensorToday);
      return true;
    }
    return false;
  }
}
