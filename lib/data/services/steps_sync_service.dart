import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/calendar_day.dart';
import '../repositories/step_repository.dart';

/// Result of syncing steps from HealthKit / Health Connect.
enum StepsSyncStatus {
  /// Desktop / web — no system health store.
  unsupported,

  /// Activity recognition or health read permission not granted.
  denied,

  /// Authorized and daily totals were read successfully (may still be 0).
  connected,

  /// Unexpected failure while reading or writing step totals.
  failed,
}

/// Syncs daily step totals from HealthKit / Health Connect into [StepRepository].
class StepsSyncService {
  StepsSyncService(this._repo, {Health? health}) : _health = health ?? Health();

  final StepRepository _repo;
  final Health _health;

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

  /// Returns whether read access was granted. Does not wipe existing DB rows
  /// when authorization fails.
  Future<bool> ensureAuthorized() async {
    if (!isPlatformSupported) return false;
    try {
      await _ensureConfigured();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) return false;
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
      final authorized = await ensureAuthorized();
      if (!authorized) return StepsSyncStatus.denied;

      final today = CalendarDay.todayLocal();
      final now = DateTime.now();
      var readsOk = 0;
      var readsFailed = 0;
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
          // null = successful read with no samples → store 0.
          await _repo.setStepsForDay(day, total ?? 0);
          readsOk++;
        } catch (_) {
          // Keep any existing DB value for this day.
          readsFailed++;
        }
      }
      if (readsOk == 0 && readsFailed > 0) return StepsSyncStatus.failed;
      return StepsSyncStatus.connected;
    } catch (_) {
      return StepsSyncStatus.failed;
    }
  }
}
