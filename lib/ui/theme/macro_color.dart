import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 按三大营养素克数占比给食材名着色：碳水最高 → 蓝，蛋白质最高 → 红，
/// 脂肪最高 → 黄。三者皆为 0 时返回 null（沿用默认字色）。并列时优先碳水，
/// 其次蛋白质。
Color? dominantMacroColor({
  required double carbG,
  required double proteinG,
  required double fatG,
}) {
  if (carbG <= 0 && proteinG <= 0 && fatG <= 0) return null;
  if (carbG >= proteinG && carbG >= fatG) return AppColors.carb;
  if (proteinG >= carbG && proteinG >= fatG) return AppColors.protein;
  return AppColors.fat;
}
