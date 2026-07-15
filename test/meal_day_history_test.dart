import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_plan/data/db.dart';
import 'package:fitness_plan/data/repositories/meal_repository.dart';
import 'package:fitness_plan/domain/models.dart';
import 'package:fitness_plan/domain/deficit.dart';

void main() {
  test('actualDailyDeficit = planned + remaining', () {
    // planned 500, target 1800, ate 1600 → remain 200 → actual 700
    expect(
      actualDailyDeficit(
        plannedDeficit: 500,
        targetCalories: 1800,
        intakeCalories: 1600,
      ),
      700,
    );
    // overeat → actual < planned
    expect(
      actualDailyDeficit(
        plannedDeficit: 500,
        targetCalories: 1800,
        intakeCalories: 2000,
      ),
      300,
    );
  });

  test('actualDailyDeficit >= planned marks past days green', () {
    const planned = 500.0;
    const target = 1800.0;

    // 欠摄入 → 实际 ≥ 计划 → 绿
    expect(
      actualDailyDeficit(
        plannedDeficit: planned,
        targetCalories: target,
        intakeCalories: 1600,
      ) >=
          planned,
      isTrue,
    );
    // 恰好达标（摄入=目标）→ 实际==计划 → 绿
    expect(
      actualDailyDeficit(
        plannedDeficit: planned,
        targetCalories: target,
        intakeCalories: 1800,
      ) >=
          planned,
      isTrue,
    );
    // 超目标 → 实际 < 计划 → 红
    expect(
      actualDailyDeficit(
        plannedDeficit: planned,
        targetCalories: target,
        intakeCalories: 2000,
      ) >=
          planned,
      isFalse,
    );
  });

  late AppDatabase db;
  late MealRepository repo;
  late FoodItem rice;
  late FoodItem chicken;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MealRepository(db);

    final riceId = await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: '测试米饭',
            category: '测试',
            kcalPer100: 100,
            proteinPer100: 2,
            carbPer100: 22,
            fatPer100: 0.5,
          ),
        );
    final chickenId = await db.into(db.foodItems).insert(
          FoodItemsCompanion.insert(
            name: '测试鸡胸',
            category: '测试',
            kcalPer100: 120,
            proteinPer100: 25,
            carbPer100: 0,
            fatPer100: 2,
          ),
        );
    rice = await (db.select(db.foodItems)..where((t) => t.id.equals(riceId)))
        .getSingle();
    chicken =
        await (db.select(db.foodItems)..where((t) => t.id.equals(chickenId)))
            .getSingle();
  });

  tearDown(() async {
    await db.close();
  });

  test('forDay and intakeForDay isolate calendar days', () async {
    final day1 = DateTime(2026, 7, 13);
    final day2 = DateTime(2026, 7, 14);
    final day3 = DateTime(2026, 7, 15);

    // Day1: 200g rice → 200 kcal, 4p, 44c, 1f
    await repo.add(
      date: day1,
      mealType: MealType.lunch,
      food: rice,
      grams: 200,
    );
    // Day2: 100g chicken → 120 kcal, 25p, 0c, 2f
    await repo.add(
      date: day2,
      mealType: MealType.dinner,
      food: chicken,
      grams: 100,
    );
    // Day3: 150g rice + 150g chicken
    await repo.add(
      date: day3,
      mealType: MealType.breakfast,
      food: rice,
      grams: 150,
    );
    await repo.add(
      date: day3,
      mealType: MealType.lunch,
      food: chicken,
      grams: 150,
    );

    final day1Meals = await repo.forDay(day1);
    expect(day1Meals, hasLength(1));
    expect(day1Meals.single.foodName, '测试米饭');

    final day2Meals = await repo.forDay(day2);
    expect(day2Meals, hasLength(1));
    expect(day2Meals.single.foodName, '测试鸡胸');

    final day3Meals = await repo.forDay(day3);
    expect(day3Meals, hasLength(2));

    final intake1 = await repo.intakeForDay(day1);
    expect(intake1.calories, closeTo(200, 0.01));
    expect(intake1.proteinG, closeTo(4, 0.01));
    expect(intake1.carbG, closeTo(44, 0.01));
    expect(intake1.fatG, closeTo(1, 0.01));

    final intake2 = await repo.intakeForDay(day2);
    expect(intake2.calories, closeTo(120, 0.01));
    expect(intake2.proteinG, closeTo(25, 0.01));
    expect(intake2.carbG, closeTo(0, 0.01));
    expect(intake2.fatG, closeTo(2, 0.01));

    final intake3 = await repo.intakeForDay(day3);
    // 150g rice: 150/100 kcal + 150g chicken: 180 kcal = 330
    expect(intake3.calories, closeTo(330, 0.01));
    // protein: 3 + 37.5 = 40.5
    expect(intake3.proteinG, closeTo(40.5, 0.01));
    // carb: 33 + 0 = 33
    expect(intake3.carbG, closeTo(33, 0.01));
    // fat: 0.75 + 3 = 3.75
    expect(intake3.fatG, closeTo(3.75, 0.01));

    final empty = await repo.intakeForDay(DateTime(2026, 7, 12));
    expect(empty.calories, 0);
    expect(empty.proteinG, 0);
  });

  test('day boundaries do not bleed across midnight', () async {
    final dayA = DateTime(2026, 7, 10);
    final dayB = DateTime(2026, 7, 11);

    await repo.add(
      date: DateTime(2026, 7, 10, 23, 59, 59),
      mealType: MealType.snack,
      food: rice,
      grams: 100,
    );
    await repo.add(
      date: DateTime(2026, 7, 11, 0, 0, 1),
      mealType: MealType.breakfast,
      food: chicken,
      grams: 100,
    );

    expect(await repo.forDay(dayA), hasLength(1));
    expect((await repo.forDay(dayA)).single.foodName, '测试米饭');
    expect(await repo.forDay(dayB), hasLength(1));
    expect((await repo.forDay(dayB)).single.foodName, '测试鸡胸');
  });

  test('calorieTotalsBetween groups by local day', () async {
    final day1 = DateTime(2026, 7, 13);
    final day2 = DateTime(2026, 7, 14);
    await repo.add(
      date: day1,
      mealType: MealType.lunch,
      food: rice,
      grams: 100,
    );
    await repo.add(
      date: day1,
      mealType: MealType.dinner,
      food: chicken,
      grams: 100,
    );
    await repo.add(
      date: day2,
      mealType: MealType.lunch,
      food: rice,
      grams: 200,
    );

    final map = await repo.calorieTotalsBetween(day1, day2);
    expect(map[day1], closeTo(220, 0.01)); // 100 + 120
    expect(map[day2], closeTo(200, 0.01));
  });
}
