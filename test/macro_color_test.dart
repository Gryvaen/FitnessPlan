import 'package:flutter_test/flutter_test.dart';

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
}
