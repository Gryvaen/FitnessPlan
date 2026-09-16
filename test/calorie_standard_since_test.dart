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

  test(
    'changing calorie adjustment alone does not stamp calorieStandardSince',
    () async {
      // Only a goal switch or a diet-strategy change re-stamps the
      // standard; a target-calorie shift with the goal unchanged (e.g. a
      // plateau adjustment, or a weigh-in recalculation) must not.
      await seedCut();
      final before = repo.load()!;
      expect(before.calorieStandardSince, isNull);

      final updated = await seedCut(calorieAdjustment: 100);
      expect(updated.targets.calories, isNot(before.targets.calories));
      expect(updated.calorieStandardSince, isNull);
      expect(repo.load()?.calorieStandardSince, isNull);
    },
  );

  test('weight-driven recalculation does not stamp calorieStandardSince', () async {
    final seeded = await seedCut();
    final updated = await repo.recalculateForWeight(seeded, 78);
    expect(updated.weightKg, 78);
    expect(updated.calorieStandardSince, isNull);
  });

  test('switching goal stamps calorieStandardSince today', () async {
    await seedCut();
    expect(repo.load()?.calorieStandardSince, isNull);

    final updated = await repo.saveFromInputs(
      sex: Sex.male,
      age: 30,
      heightCm: 175,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: FitnessGoal.maintain,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(updated.goal, FitnessGoal.maintain);
    expect(updated.calorieStandardSince, today);
  });

  group('markStandardChanged', () {
    test('stamps the given day when it differs from the current one', () async {
      await seedCut();
      final day = DateTime(2026, 1, 5);
      final updated = await repo.markStandardChanged(day);
      expect(updated?.calorieStandardSince, day);
      expect(repo.load()?.calorieStandardSince, day);
    });

    test('no-ops when the day is already stamped', () async {
      await seedCut();
      final day = DateTime(2026, 1, 5);
      await repo.markStandardChanged(day);
      final result = await repo.markStandardChanged(day);
      expect(result, isNull);
    });

    test('no-ops when there is no profile yet', () async {
      final result = await repo.markStandardChanged(DateTime(2026, 1, 5));
      expect(result, isNull);
    });
  });
}
