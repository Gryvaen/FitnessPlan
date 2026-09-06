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
}
