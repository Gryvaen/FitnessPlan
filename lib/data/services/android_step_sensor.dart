import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calendar_day.dart';

/// Converts reboot-cumulative [Sensor.TYPE_STEP_COUNTER] readings into local
/// calendar-day totals. Pure logic is in [StepSensorAccumulator] for tests.
class AndroidStepSensor {
  AndroidStepSensor(
    this._prefs, {
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('fitness_plan/step_counter');

  static const _kDate = 'android_step_sensor_date';
  static const _kToday = 'android_step_sensor_today';
  static const _kLast = 'android_step_sensor_last_cumulative';

  final SharedPreferences _prefs;
  final MethodChannel _channel;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isHardwareAvailable() async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('isAvailable');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Today's steps from the device step counter, or null if unavailable.
  Future<int?> readTodaySteps({DateTime? now}) async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMethod<int>('readCumulativeSteps');
      if (raw == null) return null;
      final day = CalendarDay.todayLocal(now);
      final dateKey =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';

      final next = StepSensorAccumulator.apply(
        dateKey: dateKey,
        cumulative: raw,
        storedDateKey: _prefs.getString(_kDate),
        storedToday: _prefs.getInt(_kToday) ?? 0,
        storedLastCumulative: _prefs.getInt(_kLast),
      );
      await _prefs.setString(_kDate, next.dateKey);
      await _prefs.setInt(_kToday, next.todaySteps);
      await _prefs.setInt(_kLast, next.lastCumulative);
      return next.todaySteps;
    } catch (_) {
      return null;
    }
  }
}

@immutable
class StepSensorSnapshot {
  const StepSensorSnapshot({
    required this.dateKey,
    required this.todaySteps,
    required this.lastCumulative,
  });

  final String dateKey;
  final int todaySteps;
  final int lastCumulative;
}

/// Incremental daily total from a since-boot cumulative counter.
abstract final class StepSensorAccumulator {
  static StepSensorSnapshot apply({
    required String dateKey,
    required int cumulative,
    required String? storedDateKey,
    required int storedToday,
    required int? storedLastCumulative,
  }) {
    final safeCumulative = cumulative < 0 ? 0 : cumulative;

    if (storedDateKey != dateKey || storedLastCumulative == null) {
      // New day or first sample: anchor at current cumulative.
      // Steps from midnight until first open of the day are not recoverable
      // from the sensor alone (Health Connect covers that when available).
      return StepSensorSnapshot(
        dateKey: dateKey,
        todaySteps: 0,
        lastCumulative: safeCumulative,
      );
    }

    final last = storedLastCumulative < 0 ? 0 : storedLastCumulative;
    final int today;
    if (safeCumulative >= last) {
      today = storedToday + (safeCumulative - last);
    } else {
      // Device rebooted; counter restarted. Keep prior today total and add
      // steps counted since reboot.
      today = storedToday + safeCumulative;
    }
    return StepSensorSnapshot(
      dateKey: dateKey,
      todaySteps: today < 0 ? 0 : today,
      lastCumulative: safeCumulative,
    );
  }
}
