import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_plan/data/repositories/profile_repository.dart';
import 'package:fitness_plan/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);
  });

  Future<UserProfile> seedCut({required double weeklyLossKg}) {
    return repo.saveFromInputs(
      sex: Sex.male,
      age: 30,
      heightCm: 175,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: FitnessGoal.cut,
      targetWeightKg: 70,
      weeklyLossKg: weeklyLossKg,
    );
  }

  test('first save does not set calorieStandardSince', () async {
    final profile = await seedCut(weeklyLossKg: 0.5);
    expect(profile.calorieStandardSince, isNull);
    expect(repo.load()?.calorieStandardSince, isNull);
  });

  test('changing weekly loss that alters deficit stamps today', () async {
    await seedCut(weeklyLossKg: 0.3);
    final before = repo.load()!;
    expect(before.calorieStandardSince, isNull);

    final updated = await seedCut(weeklyLossKg: 0.8);
    expect(updated.targets.calories, isNot(before.targets.calories));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(updated.calorieStandardSince, today);
    expect(repo.load()?.calorieStandardSince, today);
  });

  test('identical save does not refresh calorieStandardSince', () async {
    await seedCut(weeklyLossKg: 0.5);
    final stamped = await seedCut(weeklyLossKg: 0.8);
    final stampedDay = stamped.calorieStandardSince;
    expect(stampedDay, isNotNull);

    final again = await seedCut(weeklyLossKg: 0.8);
    expect(again.targets.calories, stamped.targets.calories);
    expect(again.calorieStandardSince, stampedDay);
  });
}
