import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Coordinates runtime permission requests.
///
/// `permission_handler` throws "A request for permissions is already running"
/// when a second request starts while a system dialog is up — e.g. the steps
/// sync and the step service both asking for activity recognition on first
/// launch. A request that collides waits for the dialog already showing and
/// then reports the resulting status instead of failing. Requests are not
/// queued behind each other, so one dialog that never returns cannot block
/// every later request. [grantedTick] lets listeners refresh as soon as
/// anything becomes granted.
class PermissionGate {
  PermissionGate._();

  static Future<PermissionStatus>? _inFlight;

  /// Bumped whenever a request ends with the permission granted.
  static final grantedTick = ValueNotifier<int>(0);

  static Future<PermissionStatus> request(Permission permission) async {
    final before = await permission.status;
    if (before.isGranted) return before;
    final other = _inFlight;
    final mine = permission.request();
    _inFlight = mine;
    PermissionStatus after;
    try {
      after = await mine;
    } on PlatformException {
      _inFlight = other;
      if (other != null) {
        try {
          await other;
        } catch (_) {}
      }
      after = await permission.status;
    } finally {
      if (identical(_inFlight, mine)) _inFlight = null;
    }
    if (after.isGranted || after.isLimited) grantedTick.value++;
    return after;
  }
}
