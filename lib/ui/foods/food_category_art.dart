import 'package:flutter/material.dart';

import '../ink/ink_icon.dart';

InkGlyph foodCategoryGlyph(String category) => switch (category) {
  '畜肉' => InkGlyph.foodLivestock,
  '禽肉' => InkGlyph.foodPoultry,
  '水产' => InkGlyph.foodSeafood,
  '乳类' => InkGlyph.foodDairy,
  '蛋类' => InkGlyph.foodEggs,
  '豆类' => InkGlyph.foodLegumes,
  '谷类' => InkGlyph.foodGrains,
  '薯类' => InkGlyph.foodTubers,
  '水果' => InkGlyph.foodFruit,
  '糖蜜饯' => InkGlyph.foodConfectionery,
  '坚果' => InkGlyph.foodNuts,
  '油脂' => InkGlyph.foodOils,
  '饮料' => InkGlyph.foodBeverages,
  '包装食品' => InkGlyph.foodPackaged,
  '小吃' => InkGlyph.foodSnacks,
  '菌藻' => InkGlyph.foodFungi,
  '蔬菜' => InkGlyph.foodVegetables,
  '调味品' => InkGlyph.foodSeasonings,
  '自定义' => InkGlyph.foodCustom,
  _ => InkGlyph.food,
};

/// Low-saturation food colours: warmer for protein/grains, cooler for
/// hydration/fats. The dark palette is lifted enough to stay calm and clear
/// on graphite without becoming neon.
Color foodCategoryColor(BuildContext context, String category) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (category) {
    '畜肉' ||
    '禽肉' ||
    '水产' ||
    '乳类' ||
    '蛋类' ||
    '豆类' => dark ? const Color(0xFFD58F82) : const Color(0xFFA85F52),
    '谷类' ||
    '薯类' ||
    '水果' ||
    '糖蜜饯' => dark ? const Color(0xFFD5B46F) : const Color(0xFF9B752D),
    '坚果' || '油脂' => dark ? const Color(0xFF9EADD0) : const Color(0xFF66779F),
    '饮料' => dark ? const Color(0xFF79BFC0) : const Color(0xFF3E8584),
    '自定义' => dark ? const Color(0xFFA9A0C5) : const Color(0xFF776D98),
    _ => dark ? const Color(0xFF96B89F) : const Color(0xFF5F876A),
  };
}

Color foodUtilityIconColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .82);

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
      child: Center(
        child: InkIcon(
          foodCategoryGlyph(category),
          size: size,
          color: foodCategoryColor(context, category),
        ),
      ),
    );
  }
}
