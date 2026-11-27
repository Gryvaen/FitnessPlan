import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/theme/macro_color.dart';

void main() {
  test('dominant macro by grams: carb blue, protein red, fat yellow', () {
    expect(
      dominantMacroColor(carbG: 20, proteinG: 5, fatG: 5),
      AppColors.carb,
    );
    expect(
      dominantMacroColor(carbG: 5, proteinG: 20, fatG: 5),
      AppColors.protein,
    );
    expect(
      dominantMacroColor(carbG: 5, proteinG: 5, fatG: 20),
      AppColors.fat,
    );
  });

  test('fat no longer wins on kcal when carb grams are higher', () {
    // 10g carb / 2g fat → carb grams win (was fat by kcal under ×9).
    expect(
      dominantMacroColor(carbG: 10, proteinG: 0, fatG: 2),
      AppColors.carb,
    );
  });

  test('all zero returns null', () {
    expect(dominantMacroColor(carbG: 0, proteinG: 0, fatG: 0), isNull);
  });

  test('recent foods sort red → blue → yellow → plain, stable', () {
    FoodItem food(int id, double p, double c, double f) => FoodItem(
      id: id,
      name: 'f$id',
      category: '自定义',
      kcalPer100: 100,
      proteinPer100: p,
      carbPer100: c,
      fatPer100: f,
      alcoholPer100: 0,
      fiberPer100: 0,
      sodiumMgPer100: 0,
      sugarPer100: 0,
      saturatedFatPer100: 0,
      calciumMgPer100: 0,
      isTemporary: false,
      isCustom: false,
    );

    final foods = [
      food(1, 0, 0, 0), // plain
      food(2, 2, 20, 1), // blue
      food(3, 0, 1, 30), // yellow
      food(4, 25, 0, 3), // red
      food(5, 10, 10, 1), // tie carb = protein → blue
      food(6, 20, 2, 5), // red
      food(7, 1, 1, 9), // yellow
    ];
    final sorted = sortFoodsByDominantMacro(foods);
    expect(sorted.map((f) => f.id), [4, 6, 2, 5, 3, 7, 1]);
    // The input keeps its recency order.
    expect(foods.map((f) => f.id), [1, 2, 3, 4, 5, 6, 7]);
  });
}
