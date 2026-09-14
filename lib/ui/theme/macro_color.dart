import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The macro (碳水/蛋白质/脂肪) that contributes the most kcal — carb and
/// protein are ~4 kcal/g, fat ~9 kcal/g — used to tint a food/entry name so
/// its dominant macro is visible at a glance. Returns null when there's no
/// macro data to go on (e.g. all zero).
Color? dominantMacroColor({
  required double carbG,
  required double proteinG,
  required double fatG,
}) {
  final carbKcal = carbG * 4;
  final proteinKcal = proteinG * 4;
  final fatKcal = fatG * 9;
  if (carbKcal <= 0 && proteinKcal <= 0 && fatKcal <= 0) return null;
  if (carbKcal >= proteinKcal && carbKcal >= fatKcal) return AppColors.carb;
  if (proteinKcal >= carbKcal && proteinKcal >= fatKcal) {
    return AppColors.protein;
  }
  return AppColors.fat;
}
