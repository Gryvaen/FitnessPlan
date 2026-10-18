import 'dart:async';

import 'package:diet/data/services/permission_gate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'a colliding request waits for the open dialog instead of failing',
    () async {
      var granted = false;
      final dialog = Completer<void>();
      var requests = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermissionStatus') return granted ? 1 : 0;
        if (call.method == 'requestPermissions') {
          requests++;
          if (requests > 1) {
            throw PlatformException(
              code: 'ERROR_ALREADY_REQUESTING_PERMISSIONS',
              message: 'A request for permissions is already running',
            );
          }
          await dialog.future;
          return <int, int>{
            for (final id in call.arguments as List<dynamic>) id as int: 1,
          };
        }
        return null;
      });
      final ticks = PermissionGate.grantedTick.value;

      final first = PermissionGate.request(Permission.activityRecognition);
      final second = PermissionGate.request(Permission.activityRecognition);
      await pumpEventQueue();
      granted = true;
      dialog.complete();

      expect((await first).isGranted, isTrue);
      expect((await second).isGranted, isTrue);
      expect(PermissionGate.grantedTick.value, greaterThan(ticks));
    },
  );
}
