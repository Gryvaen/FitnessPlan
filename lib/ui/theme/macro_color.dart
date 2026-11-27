import 'package:flutter/material.dart';

import '../../data/db.dart';
import 'app_theme.dart';

/// 食材的主导营养素。声明顺序即列表里的排列顺序：红（蛋白质）→ 蓝（碳水）
/// → 黄（脂肪）。
enum DominantMacro { protein, carb, fat }

/// 按三大营养素克数占比判定主导营养素。三者皆为 0 时返回 null。并列时优先
/// 碳水，其次蛋白质。
DominantMacro? dominantMacro({
  required double carbG,
  required double proteinG,
  required double fatG,
}) {
  if (carbG <= 0 && proteinG <= 0 && fatG <= 0) return null;
  if (carbG >= proteinG && carbG >= fatG) return DominantMacro.carb;
  if (proteinG >= carbG && proteinG >= fatG) return DominantMacro.protein;
  return DominantMacro.fat;
}

/// 按三大营养素克数占比给食材名着色：碳水最高 → 蓝，蛋白质最高 → 红，
/// 脂肪最高 → 黄。三者皆为 0 时返回 null（沿用默认字色）。并列规则同
/// [dominantMacro]。
Color? dominantMacroColor({
  required double carbG,
  required double proteinG,
  required double fatG,
}) {
  return switch (dominantMacro(carbG: carbG, proteinG: proteinG, fatG: fatG)) {
    DominantMacro.carb => AppColors.carb,
    DominantMacro.protein => AppColors.protein,
    DominantMacro.fat => AppColors.fat,
    null => null,
  };
}

/// 按名字颜色排成 红 → 蓝 → 黄，三大营养素皆为 0 的排最后；同色内保持
/// [foods] 原有顺序（稳定排序）。
List<FoodItem> sortFoodsByDominantMacro(List<FoodItem> foods) {
  int rank(FoodItem f) =>
      dominantMacro(
        carbG: f.carbPer100,
        proteinG: f.proteinPer100,
        fatG: f.fatPer100,
      )?.index ??
      DominantMacro.values.length;

  final indexed = [
    for (var i = 0; i < foods.length; i++) (i: i, rank: rank(foods[i])),
  ];
  indexed.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    return byRank != 0 ? byRank : a.i.compareTo(b.i);
  });
  return [for (final e in indexed) foods[e.i]];
}
