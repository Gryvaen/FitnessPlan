import 'package:flutter/material.dart';

import '../ink/ink_icon.dart';

InkGlyph foodCategoryGlyph(String category) => switch (category) {
  '畜肉' || '禽肉' || '水产' || '乳类' || '蛋类' || '豆类' => InkGlyph.protein,
  '谷类' || '薯类' || '水果' || '糖蜜饯' => InkGlyph.carbs,
  '坚果' || '油脂' => InkGlyph.fat,
  '饮料' => InkGlyph.water,
  '自定义' => InkGlyph.autoFix,
  _ => InkGlyph.food,
};

/// Theme-aware ink PNG used as a food-category list marker.
class FoodCategoryAvatar extends StatelessWidget {
  const FoodCategoryAvatar({super.key, required this.category, this.size = 40});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: InkIcon(foodCategoryGlyph(category), size: size)),
    );
  }
}
