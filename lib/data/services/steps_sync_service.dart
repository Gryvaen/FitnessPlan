import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calendar_day.dart';
import '../repositories/data_backup_repository.dart';
import '../repositories/step_repository.dart';
import 'android_step_sensor.dart';
import 'permission_gate.dart';

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

/// No human walks this much in a day; only the legacy reboot bug produced it.
const kMaxPlausibleDailySteps = 100000;

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
    this._prefs,
  }) : _health = health ?? Health();

  final StepRepository _repo;
  final Health _health;
  final AndroidStepSensor? _stepSensor;
  final SharedPreferences? _prefs;

  static const _repairBackupKey = 'step_counter_backup_v2';

  bool _configured = false;
  bool _promptedThisSession = false;
  Future<StepsSyncStatus>? _inFlight;

  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> _ensureActivityRecognition({required bool prompt}) async {
    if (!_isAndroid) return true;
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;
    if (!prompt) return false;
    // Android shows no dialog once the user picked "don't allow" twice; send
    // them to app settings instead of a retry that silently does nothing.
    // The shell re-syncs on resume when they come back.
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return (await PermissionGate.request(
      Permission.activityRecognition,
    )).isGranted;
  }

  /// Returns whether Health Connect / HealthKit read access is granted.
  ///
  /// Only shows system permission UI when [prompt] is true, so background
  /// resyncs on app resume never spam the user with dialogs.
  Future<bool> ensureAuthorized({bool prompt = true}) async {
    if (!isPlatformSupported) return false;
    try {
      await _ensureConfigured();
      if (!await _ensureActivityRecognition(prompt: prompt)) return false;
      if (_isAndroid && !await _health.isHealthConnectAvailable()) return false;

      const types = <HealthDataType>[HealthDataType.STEPS];
      const permissions = <HealthDataAccess>[HealthDataAccess.READ];

      var granted = false;
      try {
        granted =
            await _health.hasPermissions(types, permissions: permissions) ??
            false;
      } catch (_) {}
      if (!granted) {
        if (!prompt) return false;
        granted = await _health.requestAuthorization(
          types,
          permissions: permissions,
        );
        if (!granted) return false;
      }

      if (_isAndroid && prompt) {
        try {
          if (!await _health.isHealthDataHistoryAuthorized()) {
            await _health.requestHealthDataHistoryAuthorization();
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
    if (sensor != null && await sensor.openHealthConnectSettings()) return true;
    try {
      await _ensureConfigured();
      if (_isAndroid && !await _health.isHealthConnectAvailable()) {
        await _health.installHealthConnect();
        return true;
      }
    } catch (_) {}
    return openAppSettings();
  }

  /// [forcePrompt] re-shows permission dialogs (user-initiated retry).
  Future<StepsSyncStatus> syncRecent({
    int limitDays = 14,
    bool forcePrompt = false,
  }) {
    if (!isPlatformSupported) {
      return Future.value(StepsSyncStatus.unsupported);
    }
    final prompt = forcePrompt || !_promptedThisSession;
    _promptedThisSession = true;
    return _inFlight ??= _run(
      limitDays,
      prompt: prompt,
    ).whenComplete(() => _inFlight = null);
  }

  Future<StepsSyncStatus> _run(int limitDays, {required bool prompt}) async {
    try {
      if (!await _ensureActivityRecognition(prompt: prompt)) {
        return StepsSyncStatus.denied;
      }

      if (_isAndroid) {
        await _repo.repairInflatedOnce(
          backupKey: _repairBackupKey,
          today: CalendarDay.todayLocal(),
          ceiling: kMaxPlausibleDailySteps,
        );
      }

      final authorized = await ensureAuthorized(prompt: prompt);
      var readsOk = 0;
      var readsFailed = 0;
      var todayFromHealth = 0;

      // Health Connect may have no data at all for a device (OEM never syncs
      // into it), so past days rely on the native sensor's own day-boundary
      // archive too. Merge both sources and never regress what's stored.
      final sensorHistory = await _readSensorHistory(limitDays);
      final today = CalendarDay.todayLocal();
      final now = DateTime.now();
      for (var i = 0; i < limitDays; i++) {
        final day = CalendarDay.dayOnly(today.subtract(Duration(days: i)));
        final end = i == 0
            ? now
            : day
                  .add(const Duration(days: 1))
                  .subtract(const Duration(milliseconds: 1));
        var healthValue = 0;
        if (authorized) {
          try {
            healthValue = await _readStepsForInterval(day, end);
            readsOk++;
          } catch (_) {
            readsFailed++;
          }
        }
        // Today is written once below, after reconciling every source.
        if (i == 0) {
          todayFromHealth = healthValue;
          continue;
        }
        var fromSensor = sensorHistory[day] ?? 0;
        if (fromSensor >= kMaxPlausibleDailySteps) fromSensor = 0;
        final existing = await _repo.stepsForDay(day);
        final merged = [
          healthValue,
          fromSensor,
          existing,
        ].reduce((a, b) => a > b ? a : b);
        if (merged > existing) {
          await _repo.setStepsForDay(day, merged);
        }
      }

      final sensorToday = await _readSensorToday();
      if (sensorToday == null && !authorized) {
        return StepsSyncStatus.denied;
      }

      var todayFinal = todayFromHealth;
      if (sensorToday != null && sensorToday > todayFinal) {
        todayFinal = sensorToday;
      }
      // No sensor answer (6 s timeout) is not a reading of 0: keep today's
      // stored total instead of letting a Health Connect 0 wipe it.
      if (sensorToday == null) {
        final stored = await _repo.stepsForDay(today);
        if (stored > todayFinal) todayFinal = stored;
      }
      // Trust live readings including 0. Keeping a previous DB total when
      // Health/sensor report 0 made "today" look like yesterday after a
      // midnight reset or a failed sync, while the phone already showed 0.
      // Exception: on the day a backup was imported, the restored total was
      // counted on another device, so it is a floor rather than stale data.
      if (_importedToday(today)) {
        final stored = await _repo.stepsForDay(today);
        if (stored > todayFinal) todayFinal = stored;
      }
      await _repo.setStepsForDay(today, todayFinal);

      if (authorized &&
          readsOk == 0 &&
          readsFailed > 0 &&
          sensorToday == null) {
        return StepsSyncStatus.failed;
      }
      return todayFinal > 0 ? StepsSyncStatus.connected : StepsSyncStatus.empty;
    } catch (_) {
      return StepsSyncStatus.failed;
    }
  }

  bool _importedToday(DateTime today) {
    final raw = _prefs?.getString(DataBackupRepository.importedOnDayKey);
    final day = raw == null ? null : DateTime.tryParse(raw);
    return day != null && CalendarDay.dayOnly(day) == today;
  }

  Future<int?> _readSensorToday() async {
    final sensor = _stepSensor;
    if (sensor == null || !AndroidStepSensor.isSupported) return null;
    return sensor.readTodaySteps();
  }

  Future<Map<DateTime, int>> _readSensorHistory(int limitDays) async {
    final sensor = _stepSensor;
    if (sensor == null || !AndroidStepSensor.isSupported) return const {};
    return sensor.readHistory(days: limitDays);
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
        if (v is NumericHealthValue) sum += v.numericValue.round();
      }
      if (sum > 0) return sum;
    } catch (_) {}

    return 0;
  }

  /// Human-readable troubleshooting snapshot (no permission prompts).
  Future<Map<String, Object?>> diagnostics() async {
    final out = <String, Object?>{'platform': defaultTargetPlatform.name};
    if (!isPlatformSupported) return out;
    try {
      if (_isAndroid) {
        out['activityRecognition'] =
            (await Permission.activityRecognition.status).name;
      }
      await _ensureConfigured();
      if (_isAndroid) {
        out['healthConnectSdkStatus'] =
            (await _health.getHealthConnectSdkStatus())?.name;
      }
      final hcAvailable =
          !_isAndroid || await _health.isHealthConnectAvailable();
      out['healthConnectAvailable'] = hcAvailable;
      if (hcAvailable) {
        try {
          out['healthStepsPermission'] = await _health.hasPermissions(
            const [HealthDataType.STEPS],
            permissions: const [HealthDataAccess.READ],
          );
        } catch (e) {
          out['healthStepsPermission'] = 'error: $e';
        }
        try {
          final today = CalendarDay.todayLocal();
          out['healthTodaySteps'] = await _readStepsForInterval(
            today,
            DateTime.now(),
          );
        } catch (e) {
          out['healthTodaySteps'] = 'error: $e';
        }
      }
    } catch (e) {
      out['healthError'] = e.toString();
    }
    final sensor = _stepSensor;
    if (sensor != null && AndroidStepSensor.isSupported) {
      out.addAll(await sensor.diagnostics());
    }
    out['dbToday'] = await _repo.stepsForDay(CalendarDay.todayLocal());
    return out;
  }
}
