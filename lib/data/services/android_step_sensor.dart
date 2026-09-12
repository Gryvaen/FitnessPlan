import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android step counter bridge: OEM providers / TYPE_STEP_COUNTER → today total.
class AndroidStepSensor {
  AndroidStepSensor({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('fitness_plan/step_counter');

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

  /// Today's steps from OEM provider or device step counter, or null if unavailable.
  Future<int?> readTodaySteps() async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('readTodaySteps');
      if (raw == null) return null;
      final value = (raw as num).toInt();
      return value < 0 ? 0 : value;
    } catch (_) {
      return null;
    }
  }

  /// Archived per-day totals the native day-boundary tracker already closed
  /// out (keyed by local calendar day). This is the only way to recover
  /// steps for days before today when Health Connect has no data for them.
  Future<Map<DateTime, int>> readHistory({int days = 14}) async {
    if (!isSupported) return const {};
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'readRecentSteps',
        {'days': days},
      );
      if (raw == null) return const {};
      final out = <DateTime, int>{};
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value == null) continue;
        final parts = key.split('-');
        if (parts.length != 3) continue;
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y == null || m == null || d == null) continue;
        out[DateTime(y, m, d)] = (value as num).toInt();
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Whether the always-on background step-counting foreground service is on.
  Future<bool> isServiceEnabled() async {
    if (!isSupported) return false;
    try {
      final on = await _channel.invokeMethod<bool>('isStepServiceEnabled');
      return on ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enables / disables the always-on background step-counting service.
  Future<void> setServiceEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setStepService', {'enabled': enabled});
    } catch (_) {}
  }

  /// Opens Health Connect / app settings so the user can grant step access.
  Future<bool> openHealthConnectSettings() async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openHealthConnectSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Raw native state for troubleshooting (sensor, baseline, boot time…).
  Future<Map<String, Object?>> diagnostics() async {
    if (!isSupported) return const {};
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'diagnostics',
      );
      if (raw == null) return const {};
      return {for (final e in raw.entries) e.key.toString(): e.value};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
