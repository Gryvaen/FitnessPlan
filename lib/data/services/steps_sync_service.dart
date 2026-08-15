import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/calendar_day.dart';
import '../repositories/step_repository.dart';

/// Syncs daily step totals from HealthKit / Health Connect into [StepRepository].
class StepsSyncService {
  StepsSyncService(this._repo, {Health? health}) : _health = health ?? Health();

  final StepRepository _repo;
  final Health _health;

  bool _configured = false;
  bool _syncing = false;

  static bool get isPlatformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
      if (Platform.isAndroid) {
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
      if (Platform.isAndroid) {
        try {
          final historyOk = await _health.isHealthDataHistoryAuthorized();
          if (historyOk != true) {
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
  Future<void> syncRecent({int limitDays = 14}) async {
    if (!isPlatformSupported || _syncing) return;
    _syncing = true;
    try {
      final authorized = await ensureAuthorized();
      if (!authorized) return;

      final today = CalendarDay.todayLocal();
      final now = DateTime.now();
      for (var i = 0; i < limitDays; i++) {
        final day = today.subtract(Duration(days: i));
        final start = CalendarDay.dayOnly(day);
        final end = i == 0
            ? now
            : start.add(const Duration(days: 1)).subtract(
                  const Duration(milliseconds: 1),
                );
        int steps = 0;
        try {
          final total = await _health.getTotalStepsInInterval(start, end);
          steps = total ?? 0;
        } catch (_) {
          steps = 0;
        }
        await _repo.setStepsForDay(day, steps);
      }
    } finally {
      _syncing = false;
    }
  }
}
