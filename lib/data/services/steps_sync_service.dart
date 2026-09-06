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

  /// Connected but today's total is 0 — often means OEM health data is not
  /// shared into Health Connect yet.
  empty,

  /// Unexpected failure while reading or writing step totals.
  failed,
}

/// Syncs daily step totals from HealthKit / Health Connect into [StepRepository].
///
/// On Android, when Health Connect is missing or returns 0 for today (common on
/// OPPO / ColorOS), also reads the OEM / hardware step counter and keeps the
/// larger of the two values for today.
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
        } catch (_) {}
        try {
          final bgOk = await _health.isHealthDataInBackgroundAuthorized();
          if (!bgOk) {
            await _health.requestHealthDataInBackgroundAuthorization();
          }
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openHealthConnectSettings() async {
    final sensor = _stepSensor;
    if (sensor != null) {
      final opened = await sensor.openHealthConnectSettings();
      if (opened) return true;
    }
    try {
      await _ensureConfigured();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          await _health.installHealthConnect();
          return true;
        }
      }
    } catch (_) {}
    return openAppSettings();
  }

  Future<StepsSyncStatus> syncRecent({int limitDays = 14}) {
    if (!isPlatformSupported) {
      return Future.value(StepsSyncStatus.unsupported);
    }
    return _inFlight ??= _run(limitDays).whenComplete(() => _inFlight = null);
  }

  Future<StepsSyncStatus> _run(int limitDays) async {
    try {
      if (!await _ensureActivityRecognition()) {
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
            final value = await _readStepsForInterval(start, end);
            await _repo.setStepsForDay(day, value);
            if (i == 0) todayFromHealth = value;
            readsOk++;
          } catch (_) {
            readsFailed++;
          }
        }
      }

      final sensorToday = await _readSensorToday();
      final today = CalendarDay.todayLocal();
      var todayFinal = todayFromHealth;
      if (sensorToday != null && sensorToday > todayFinal) {
        todayFinal = sensorToday;
      }
      if (sensorToday != null || authorized) {
        await _repo.setStepsForDay(today, todayFinal);
      } else {
        return StepsSyncStatus.denied;
      }

      if (authorized) {
        if (readsOk == 0 && readsFailed > 0 && sensorToday == null) {
          return StepsSyncStatus.failed;
        }
        if (todayFinal <= 0) return StepsSyncStatus.empty;
        return StepsSyncStatus.connected;
      }

      return todayFinal > 0
          ? StepsSyncStatus.connected
          : StepsSyncStatus.empty;
    } catch (_) {
      return StepsSyncStatus.failed;
    }
  }

  Future<int?> _readSensorToday() async {
    final sensor = _stepSensor;
    if (sensor == null || !AndroidStepSensor.isSupported) return null;
    return sensor.readTodaySteps();
  }

  /// Aggregate first; if 0, sum individual STEPS samples (some OEM HC builds).
  Future<int> _readStepsForInterval(DateTime start, DateTime end) async {
    try {
      final total = await _health.getTotalStepsInInterval(start, end);
      if (total != null && total > 0) return total;
    } catch (_) {}

    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );
      var sum = 0;
      for (final p in points) {
        final v = p.value;
        if (v is NumericHealthValue) {
          sum += v.numericValue.round();
        }
      }
      if (sum > 0) return sum;
    } catch (_) {}

    return 0;
  }
}
