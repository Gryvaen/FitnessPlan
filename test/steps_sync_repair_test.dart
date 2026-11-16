import 'dart:async';
import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/data_backup_repository.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/data/services/android_step_sensor.dart';
import 'package:diet/data/services/steps_sync_service.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Health extends Health {
  _Health(this.total, {this.available = true});
  final int total;
  final bool available;
  @override
  Future<void> configure() async {}
  @override
  Future<bool> isHealthConnectAvailable() async => available;
  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async => true;
  @override
  Future<bool> isHealthDataHistoryAuthorized() async => true;
  @override
  Future<int?> getTotalStepsInInterval(
    DateTime startTime,
    DateTime endTime, {
    bool includeManualEntry = true,
  }) async => total;
}

class _Sensor extends AndroidStepSensor {
  int? total = 0;
  @override
  Future<int?> readTodaySteps() async => total;
  @override
  Future<Map<DateTime, int>> readHistory({int days = 14}) async => {};
}

/// Health Connect access not granted yet; counts the permission dialogs.
class _UngrantedHealth extends _Health {
  _UngrantedHealth() : super(0);
  int prompts = 0;
  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async => false;
  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    prompts++;
    return false;
  }
}

/// Holds a sync at its sensor read until [release] is called.
class _BlockingSensor extends _Sensor {
  Completer<void>? gate;
  void release() => gate?.complete();
  @override
  Future<Map<DateTime, int>> readHistory({int days = 14}) async {
    await gate?.future;
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late StepRepository repo;
  const permission = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permission, (_) async => 1);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = StepRepository(db);
  });

  tearDown(() async {
    await db.close();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permission, null);
  });

  test(
    'repair replaces 110k with zero and later sync never restores it',
    () async {
      final today = CalendarDay.todayLocal();
      final yesterday = CalendarDay.addDays(today, -1);
      await repo.setStepsForDay(today, 110000);
      await repo.setStepsForDay(yesterday, 4200);
      final sensor = _Sensor();
      final service = StepsSyncService(
        repo,
        health: _Health(0, available: false),
        stepSensor: sensor,
      );
      expect(await service.syncRecent(limitDays: 2), StepsSyncStatus.empty);
      expect(await repo.stepsForDay(today), 0);
      final backup = (await db.select(db.appMeta).get())
          .singleWhere((row) => row.key == 'step_counter_backup_v2')
          .value;
      expect((jsonDecode(backup)['days'] as List).first['steps'], 110000);
      sensor.total = 7;
      // A new service represents a subsequent app session using the same database.
      final reopened = StepsSyncService(
        repo,
        health: _Health(0, available: false),
        stepSensor: sensor,
      );
      expect(
        await reopened.syncRecent(limitDays: 2),
        StepsSyncStatus.connected,
      );
      expect(await repo.stepsForDay(today), 7);
      expect(await repo.stepsForDay(yesterday), 4200);
      expect(
        (await db.select(db.appMeta).get())
            .singleWhere((row) => row.key == 'step_counter_backup_v2')
            .value,
        backup,
      );
    },
  );

  test(
    'available system daily total recovers steps after sensor reset',
    () async {
      final today = CalendarDay.todayLocal();
      await repo.setStepsForDay(today, 110000);
      final service = StepsSyncService(
        repo,
        health: _Health(3456),
        stepSensor: _Sensor(),
      );
      expect(await service.syncRecent(limitDays: 1), StepsSyncStatus.connected);
      expect(await repo.stepsForDay(today), 3456);
    },
  );

  test('sensor timeout keeps today instead of writing a Health 0', () async {
    final today = CalendarDay.todayLocal();
    final sensor = _Sensor();
    final service = StepsSyncService(
      repo,
      health: _Health(0),
      stepSensor: sensor,
    );
    await service.syncRecent(limitDays: 1);
    await repo.setStepsForDay(today, 4321);
    sensor.total = null;
    await service.syncRecent(limitDays: 1);
    expect(await repo.stepsForDay(today), 4321);
  });

  test('permanently denied activity permission opens app settings', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permission, (call) async {
          calls.add(call.method);
          if (call.method == 'checkPermissionStatus') return 4;
          if (call.method == 'openAppSettings') return true;
          return null;
        });
    final service = StepsSyncService(
      repo,
      health: _Health(0, available: false),
      stepSensor: _Sensor(),
    );
    expect(
      await service.syncRecent(limitDays: 1, forcePrompt: true),
      StepsSyncStatus.denied,
    );
    expect(calls, contains('openAppSettings'));
    expect(calls, isNot(contains('requestPermissions')));
  });

  test(
    'a user retry during a background sync still shows the dialog',
    () async {
      final health = _UngrantedHealth();
      final sensor = _BlockingSensor();
      final service = StepsSyncService(
        repo,
        health: health,
        stepSensor: sensor,
      );
      // The session's first sync prompts once.
      await service.syncRecent(limitDays: 1);
      expect(health.prompts, 1);

      // A resume sync (no prompt) is still running when the user taps retry.
      sensor.gate = Completer<void>();
      final background = service.syncRecent(limitDays: 1);
      await Future<void>.delayed(Duration.zero);
      final retry = service.syncRecent(limitDays: 1, forcePrompt: true);
      sensor.release();
      await background;
      sensor.gate = null;
      await retry;

      expect(health.prompts, 2);
    },
  );

  test(
    "on the import day the restored total is a floor for today's sync",
    () async {
      final today = CalendarDay.todayLocal();
      SharedPreferences.setMockInitialValues({
        DataBackupRepository.importedOnDayKey: today.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();
      // The one-time inflated-count repair already ran on this database.
      await db
          .into(db.appMeta)
          .insert(
            AppMetaCompanion.insert(
              key: 'step_counter_backup_v2',
              value: '{"days":[]}',
            ),
          );
      await repo.setStepsForDay(today, 5000);
      final sensor = _Sensor()..total = 120;
      final service = StepsSyncService(
        repo,
        health: _Health(0, available: false),
        stepSensor: sensor,
        prefs: prefs,
      );
      await service.syncRecent(limitDays: 1);
      expect(await repo.stepsForDay(today), 5000);

      // Any other day, a lower live reading wins as usual.
      await prefs.setString(
        DataBackupRepository.importedOnDayKey,
        today.subtract(const Duration(days: 1)).toIso8601String(),
      );
      await StepsSyncService(
        repo,
        health: _Health(0, available: false),
        stepSensor: sensor,
        prefs: prefs,
      ).syncRecent(limitDays: 1);
      expect(await repo.stepsForDay(today), 120);
    },
  );
}
