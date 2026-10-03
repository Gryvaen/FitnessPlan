import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/ui/foods/food_history_tab.dart';
import 'package:flutter_test/flutter_test.dart';

DailyNutritionTarget target(
  CarbDayType? dayType, {
  DietStrategyKind strategy = DietStrategyKind.carbCycle,
}) => DailyNutritionTarget(
  date: DateTime(2026, 10, 1),
  calories: 2000,
  proteinG: 150,
  carbG: 200,
  fatG: 60,
  source: TargetSource.strategy,
  estimatedTdee: 2400,
  strategy: strategy,
  dayType: dayType,
);

void main() {
  test('cut goal with carb cycle highlights exactly the selected day type', () {
    for (final selectedType in CarbDayType.values) {
      for (final dayType in CarbDayType.values) {
        expect(
          mealHistoryHighlightsDay(
            goal: FitnessGoal.cut,
            selectedStrategy: DietStrategyKind.carbCycle,
            selectedTarget: target(selectedType),
            dayTarget: target(dayType),
          ),
          dayType == selectedType,
          reason: '$selectedType selected, $dayType candidate',
        );
      }
    }
  });

  test('other goals, strategies, and missing day types do not highlight', () {
    final low = target(CarbDayType.low);
    final cases = [
      (FitnessGoal.maintain, DietStrategyKind.carbCycle, low, low),
      (FitnessGoal.bulk, DietStrategyKind.carbCycle, low, low),
      (FitnessGoal.cut, DietStrategyKind.balanced, low, low),
      (FitnessGoal.cut, DietStrategyKind.carbCycle, null, low),
      (FitnessGoal.cut, DietStrategyKind.carbCycle, low, null),
      (FitnessGoal.cut, DietStrategyKind.carbCycle, target(null), low),
      (FitnessGoal.cut, DietStrategyKind.carbCycle, low, target(null)),
      (
        FitnessGoal.cut,
        DietStrategyKind.carbCycle,
        low,
        target(CarbDayType.low, strategy: DietStrategyKind.balanced),
      ),
    ];
    for (final (goal, strategy, selected, day) in cases) {
      expect(
        mealHistoryHighlightsDay(
          goal: goal,
          selectedStrategy: strategy,
          selectedTarget: selected,
          dayTarget: day,
        ),
        isFalse,
      );
    }
  });
}
