import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet/data/repositories/profile_repository.dart';
import 'package:diet/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);
  });

  Future<UserProfile> seedCut({int calorieAdjustment = 0}) {
    return repo.saveFromInputs(
      sex: Sex.male,
      age: 30,
      heightCm: 175,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: FitnessGoal.cut,
      targetWeightKg: 70,
      calorieAdjustment: calorieAdjustment,
    );
  }

  test('first save does not set calorieStandardSince', () async {
    final profile = await seedCut();
    expect(profile.calorieStandardSince, isNull);
    expect(repo.load()?.calorieStandardSince, isNull);
  });

  test('changing calorie adjustment that alters target stamps today', () async {
    await seedCut();
    final before = repo.load()!;
    expect(before.calorieStandardSince, isNull);

    final updated = await seedCut(calorieAdjustment: 100);
    expect(updated.targets.calories, isNot(before.targets.calories));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(updated.calorieStandardSince, today);
    expect(repo.load()?.calorieStandardSince, today);
  });

  test('identical save does not refresh calorieStandardSince', () async {
    await seedCut();
    final stamped = await seedCut(calorieAdjustment: 100);
    final stampedDay = stamped.calorieStandardSince;
    expect(stampedDay, isNotNull);

    final again = await seedCut(calorieAdjustment: 100);
    expect(again.targets.calories, stamped.targets.calories);
    expect(again.calorieStandardSince, stampedDay);
  });
}
