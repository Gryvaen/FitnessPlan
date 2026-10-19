import 'package:diet/data/repositories/reminders_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<RemindersRepository> repoWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return RemindersRepository(await SharedPreferences.getInstance());
  }

  test(
    'the first enabled reminder\'s ring choice becomes the shared one',
    () async {
      final repo = await repoWith({
        'reminder_workout_alertMode': 'ring',
        'reminder_water_enabled': true,
        'reminder_water_alertMode': 'vibrate',
        'reminder_water_soundUri': 'content://tone/2',
        'reminder_water_soundTitle': 'Chime',
      });
      for (final kind in ReminderKind.values) {
        final s = repo.get(kind);
        expect(s.alertMode, ReminderAlertMode.vibrate, reason: kind.name);
        expect(s.soundUri, 'content://tone/2');
        expect(s.soundTitle, 'Chime');
      }
    },
  );

  test('with nothing enabled the workout reminder wins', () async {
    final repo = await repoWith({
      'reminder_workout_alertMode': 'vibrate',
      'reminder_meal_soundUri': 'content://tone/9',
    });
    for (final kind in ReminderKind.values) {
      expect(repo.get(kind).alertMode, ReminderAlertMode.vibrate);
      expect(repo.get(kind).soundUri, isNull);
    }
  });

  test('unifies only once', () async {
    final prefs = await (() async {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance();
    })();
    RemindersRepository(prefs);
    await prefs.setString('reminder_meal_alertMode', 'vibrate');
    final again = RemindersRepository(prefs);
    expect(again.get(ReminderKind.meal).alertMode, ReminderAlertMode.vibrate);
    expect(
      again.get(ReminderKind.workout).alertMode,
      ReminderAlertMode.vibrate,
    );
  });

  test('setAlertModeAll and setSoundAll write every kind', () async {
    final repo = await repoWith({});
    await repo.setAlertModeAll(ReminderAlertMode.vibrate);
    await repo.setSoundAll(uri: 'content://tone/3', title: 'Bell');
    for (final kind in ReminderKind.values) {
      expect(repo.get(kind).alertMode, ReminderAlertMode.vibrate);
      expect(repo.get(kind).soundTitle, 'Bell');
    }
  });
}
