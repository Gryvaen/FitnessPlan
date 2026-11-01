import '../data/db.dart';
import 'models.dart';

enum TemporaryFoodInput { per100g, caloriesOnly }

/// Unsaved nutrition; [nutrition] represents either 100g or the entire portion.
class TemporaryFoodDraft {
  const TemporaryFoodDraft({
    required this.name,
    required this.nutrition,
    this.totalGrams,
    this.input = TemporaryFoodInput.per100g,
  });

  final TemporaryFoodInput input;
  bool get caloriesOnly => input == TemporaryFoodInput.caloriesOnly;
  final String name;
  final MacroIntake nutrition;
  final double? totalGrams;

  FoodItem per100g() {
    final factor = caloriesOnly
        ? 0.0
        : (totalGrams == null ? 1.0 : 100 / totalGrams!);
    return FoodItem(
      id: 0,
      name: name.trim(),
      category: '自定义',
      isCustom: true,
      isTemporary: true,
      kcalPer100: nutrition.calories * factor,
      proteinPer100: nutrition.proteinG * factor,
      carbPer100: nutrition.carbG * factor,
      fatPer100: nutrition.fatG * factor,
      alcoholPer100: nutrition.alcoholG * factor,
      fiberPer100: nutrition.fiberG * factor,
      sodiumMgPer100: nutrition.sodiumMg * factor,
      sugarPer100: nutrition.sugarG * factor,
      saturatedFatPer100: nutrition.saturatedFatG * factor,
      calciumMgPer100: nutrition.calciumMg * factor,
    );
  }

  MacroIntake intake(double grams) {
    if (caloriesOnly) return MacroIntake(calories: nutrition.calories);
    if (totalGrams != null) return nutrition;
    final f = per100g();
    return MacroIntake.fromGrams(
      grams: grams,
      kcalPer100: f.kcalPer100,
      proteinPer100: f.proteinPer100,
      carbPer100: f.carbPer100,
      fatPer100: f.fatPer100,
      alcoholPer100: f.alcoholPer100,
      fiberPer100: f.fiberPer100,
      sodiumMgPer100: f.sodiumMgPer100,
      sugarPer100: f.sugarPer100,
      saturatedFatPer100: f.saturatedFatPer100,
      calciumMgPer100: f.calciumMgPer100,
    );
  }
}
