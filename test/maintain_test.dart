import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/data/repositories/profile_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/maintain.dart';
import 'package:diet/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DailyNutritionTarget _target({double kcal = 2000, String? reason}) =>
    DailyNutritionTarget(
      date: DateTime(2026, 11, 20),
      calories: kcal,
      proteinG: 136,
      carbG: 259,
      fatG: 54,
      source: TargetSource.profile,
      estimatedTdee: 2070,
      reason: reason,
    );

/// A profile JSON as written before `maintainProteinPerKg` existed.
Map<String, dynamic> _legacyJson() => {
  'sex': 'male',
  'age': 26,
  'heightCm': 172.0,
  'weightKg': 70.6,
  'activity': 'sedentary',
  'goal': 'maintain',
  'targets': {'calories': 2070, 'proteinG': 141.2, 'carbG': 259, 'fatG': 56},
  'calorieAdjustment': 0,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('band and verdict', () {
    test('band is ±10% of the target', () {
      final b = maintainBand(2070);
      expect(b.low, closeTo(1863, 1e-9));
      expect(b.high, closeTo(2277, 1e-9));
    });

    test('maintain days must land inside the band', () {
      final t = _target(reason: 'maintain');
      expect(t.isMaintainDay, isTrue);
      expect(intakeMet(t, 1500), isFalse); // far too little
      expect(intakeMet(t, 1800), isTrue); // lower edge
      expect(intakeMet(t, 2000), isTrue);
      expect(intakeMet(t, 2200), isTrue); // upper edge
      expect(intakeMet(t, 2201), isFalse);
    });

    test('other days keep the ceiling rule', () {
      final t = _target();
      expect(t.isMaintainDay, isFalse);
      expect(intakeMet(t, 1200), isTrue);
      expect(intakeMet(t, 2000), isTrue);
      expect(intakeMet(t, 2001), isFalse);
    });

    test('the maintain tag is one ;-separated part of the reason', () {
      expect(_target(reason: 'maintain;plateauAdj:100').isMaintainDay, isTrue);
      expect(_target(reason: 'plateauAdj:100').isMaintainDay, isFalse);
      expect(_target(reason: 'maintainX').isMaintainDay, isFalse);
    });
  });

  group('weight averages', () {
    final today = DateTime(2026, 11, 20);
    (DateTime, double) w(int daysAgo, double kg) =>
        (CalendarDay.addDays(today, -daysAgo), kg);

    test('7-day average covers today and the 6 days before', () {
      final logs = [w(0, 68.0), w(3, 69.0), w(6, 70.0), w(7, 90.0)];
      expect(recentWeightAverage(logs, today: today), closeTo(69.0, 1e-9));
      expect(recentWeightAverage(const [], today: today), isNull);
    });

    test('baseline uses the week up to the start day', () {
      final since = CalendarDay.addDays(today, -10);
      final logs = [w(10, 70.0), w(12, 71.0), w(17, 99.0), w(0, 68.0)];
      expect(maintainBaselineWeight(logs, since: since), closeTo(70.5, 1e-9));
    });

    test('baseline falls back to the first weigh-in after the start', () {
      final since = CalendarDay.addDays(today, -10);
      final logs = [w(2, 68.0), w(8, 69.5), w(5, 69.0)];
      expect(maintainBaselineWeight(logs, since: since), 69.5);
      expect(maintainBaselineWeight(const [], since: since), isNull);
    });
  });

  group('repositories', () {
    late ProfileRepository profiles;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      profiles = ProfileRepository(await SharedPreferences.getInstance());
    });

    Future<UserProfile> seed(FitnessGoal goal) => profiles.saveFromInputs(
      sex: Sex.male,
      age: 26,
      heightCm: 172,
      weightKg: 70.6,
      activity: ActivityLevel.sedentary,
      goal: goal,
    );

    test('weigh-ins leave the maintain target fixed but move TDEE', () async {
      final before = await seed(FitnessGoal.maintain);
      final after = await profiles.recalculateForWeight(before, 68);
      expect(after.weightKg, 68);
      expect(after.targets.calories, before.targets.calories);
      expect(after.targets.proteinG, before.targets.proteinG);
      expect(after.tdee, lessThan(before.tdee!));
      expect(profiles.load()!.targets.calories, before.targets.calories);
      // The basis the target was fixed from stays with the target.
      expect(before.maintainBasisWeightKg, 70.6);
      expect(before.maintainBasisTdee, before.tdee);
      expect(after.maintainBasisWeightKg, 70.6);
      expect(after.maintainBasisTdee, before.tdee);
      // An explicit recompute picks up the new weight.
      expect(
        profiles.buildPlan(after).targets.calories,
        lessThan(before.targets.calories),
      );
    });

    test('the maintain protein rate re-splits protein and carbs', () async {
      final at2 = await seed(FitnessGoal.maintain);
      expect(at2.maintainProteinPerKg, 2.0);
      expect(at2.targets.proteinG, closeTo(70.6 * 2.0, 0.05));

      final at16 = await profiles.saveFromInputs(
        sex: Sex.male,
        age: 26,
        heightCm: 172,
        weightKg: 70.6,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.maintain,
        maintainProteinPerKg: 1.6,
      );
      expect(at16.maintainProteinPerKg, 1.6);
      expect(at16.targets.proteinG, closeTo(70.6 * 1.6, 0.05));
      // Same kcal and fat; the protein difference goes to carbs (4 kcal/g).
      expect(at16.targets.calories, at2.targets.calories);
      expect(at16.targets.fatG, at2.targets.fatG);
      expect(
        at16.targets.carbG - at2.targets.carbG,
        closeTo(at2.targets.proteinG - at16.targets.proteinG, 0.15),
      );
      expect(profiles.load()!.maintainProteinPerKg, 1.6);
    });

    test('the maintain fat rate re-splits fat and carbs', () async {
      final at08 = await seed(FitnessGoal.maintain);
      expect(at08.maintainFatPerKg, 0.8);
      expect(at08.targets.fatG, closeTo(70.6 * 0.8, 0.05));

      final at1 = await profiles.saveFromInputs(
        sex: Sex.male,
        age: 26,
        heightCm: 172,
        weightKg: 70.6,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.maintain,
        maintainFatPerKg: 1.0,
      );
      expect(at1.maintainFatPerKg, 1.0);
      expect(at1.targets.fatG, closeTo(70.6, 0.05));
      // Same kcal and protein; the extra fat comes out of carbs (9 vs 4).
      expect(at1.targets.calories, at08.targets.calories);
      expect(at1.targets.proteinG, at08.targets.proteinG);
      expect(
        (at08.targets.carbG - at1.targets.carbG) * 4,
        closeTo((at1.targets.fatG - at08.targets.fatG) * 9, 0.6),
      );
      // Survives a weigh-in, and a cut profile keeps the fixed 0.8.
      final weighed = await profiles.recalculateForWeight(at1, 70);
      expect(weighed.maintainFatPerKg, 1.0);
      final cut = await profiles.saveFromInputs(
        sex: Sex.male,
        age: 26,
        heightCm: 172,
        weightKg: 70,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.cut,
      );
      expect(cut.maintainFatPerKg, 1.0);
      expect(cut.targets.fatG, closeTo(70 * 0.8, 0.05));
    });

    test('the rate survives weigh-ins and goal switches', () async {
      await profiles.saveFromInputs(
        sex: Sex.male,
        age: 26,
        heightCm: 172,
        weightKg: 70.6,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.cut,
        maintainProteinPerKg: 1.6,
      );
      // Cut keeps its own protein rule.
      final cut = profiles.load()!;
      expect(cut.targets.proteinG, closeTo(70.6 * 2.0, 0.05));
      // A cut weigh-in re-saves the profile; the 维持 rate is kept.
      await profiles.recalculateForWeight(cut, 70);
      final back = await profiles.saveFromInputs(
        sex: Sex.male,
        age: 26,
        heightCm: 172,
        weightKg: 70,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.maintain,
      );
      expect(back.maintainProteinPerKg, 1.6);
      expect(back.targets.proteinG, closeTo(70 * 1.6, 0.05));
      expect(profiles.buildPlan(back).targets.proteinG, back.targets.proteinG);
    });

    test('profiles saved before the rates existed use the defaults', () {
      final json = _legacyJson();
      expect(UserProfile.fromJson(json).maintainProteinPerKg, 2.0);
      expect(UserProfile.fromJson(json).maintainFatPerKg, 0.8);
    });

    test('weigh-ins still recompute the cut target', () async {
      final before = await seed(FitnessGoal.cut);
      final after = await profiles.recalculateForWeight(before, 68);
      expect(after.targets.calories, lessThan(before.targets.calories));
    });

    test('profile-sourced days are tagged while maintaining', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DietStrategyRepository(db);
      final today = CalendarDay.todayLocal();

      final maintain = await seed(FitnessGoal.maintain);
      final t = (await repo.targetForDay(today, maintain))!;
      expect(t.isMaintainDay, isTrue);
      expect((await repo.snapshotFor(today))!.isMaintainDay, isTrue);

      final cut = maintain.copyWith(goal: FitnessGoal.cut);
      expect((await repo.targetForDay(today, cut))!.isMaintainDay, isFalse);
    });
  });
}
