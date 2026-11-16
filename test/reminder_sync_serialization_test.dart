import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/reminders_repository.dart';
import 'package:diet/data/repositories/workout_repository.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/providers/locale_providers.dart';
import 'package:diet/providers/workout_reminder_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Makes each schedule computation slow enough that two syncs started back
/// to back would interleave if nothing serialized them.
class _SlowWorkoutRepository extends WorkoutRepository {
  _SlowWorkoutRepository(super.db);

  @override
  Future<bool> hasAnySetOn(DateTime day) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reminderChannel = MethodChannel('fitness_plan/workout_reminder');
  const localChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> nativeCalls;
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(localChannel, (call) async {
      if (call.method == 'initialize') return true;
      return null;
    });
    nativeCalls = [];
    messenger.setMockMethodCallHandler(reminderChannel, (call) async {
      nativeCalls.add(call);
      if (call.method == 'scheduleAll') {
        final items = (call.arguments as Map)['items'] as List;
        return {'scheduled': items.length, 'failed': 0};
      }
      return null;
    });
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workoutRepositoryProvider.overrideWithValue(_SlowWorkoutRepository(db)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    messenger.setMockMethodCallHandler(reminderChannel, null);
    messenger.setMockMethodCallHandler(localChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  List<Map<dynamic, dynamic>>? lastScheduledItems() {
    final relevant = nativeCalls
        .where((c) => c.method == 'scheduleAll' || c.method == 'cancelAll')
        .toList();
    if (relevant.isEmpty || relevant.last.method == 'cancelAll') return null;
    return ((relevant.last.arguments as Map)['items'] as List)
        .cast<Map<dynamic, dynamic>>();
  }

  test(
    'turning a reminder on then straight off leaves nothing scheduled',
    () async {
      final notifier = container.read(remindersProvider.notifier);

      await Future.wait([
        notifier.setEnabled(ReminderKind.workout, true),
        notifier.setEnabled(ReminderKind.workout, false),
      ]);

      expect(
        container.read(remindersProvider)[ReminderKind.workout]!.enabled,
        isFalse,
      );
      // The slower "on" sync must not land after the "off" one.
      expect(lastScheduledItems(), isNull);
    },
  );

  test('notification text follows the in-app language', () async {
    await container.read(localeProvider.notifier).set(const Locale('zh'));
    await container
        .read(remindersProvider.notifier)
        .setEnabled(ReminderKind.water, true);
    final zhTitle = lastScheduledItems()!.first['title'] as String;

    await container.read(localeProvider.notifier).set(const Locale('en'));
    await container.read(remindersProvider.notifier).syncSchedule();
    final enTitle = lastScheduledItems()!.first['title'] as String;

    expect(zhTitle, isNot(enTitle));
    expect(RegExp(r'[一-鿿]').hasMatch(zhTitle), isTrue);
    expect(RegExp(r'[一-鿿]').hasMatch(enTitle), isFalse);
  });
}
