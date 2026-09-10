import 'package:flutter/material.dart';

/// A small emoji "illustration" for a food-seed category. Falls back to a
/// generic plate for unknown / custom categories.
String foodCategoryEmoji(String category) {
  switch (category) {
    case '畜肉':
      return '🥩';
    case '禽肉':
      return '🍗';
    case '水产':
      return '🐟';
    case '乳类':
      return '🥛';
    case '蛋类':
      return '🥚';
    case '谷类':
      return '🌾';
    case '薯类':
      return '🥔';
    case '豆类':
      return '🫘';
    case '蔬菜':
      return '🥬';
    case '菌藻':
      return '🍄';
    case '水果':
      return '🍎';
    case '坚果':
      return '🥜';
    case '油脂':
      return '🫗';
    case '调味品':
      return '🧂';
    case '饮料':
      return '🥤';
    case '小吃':
      return '🍿';
    case '糖蜜饯':
      return '🍬';
    case '包装食品':
      return '🥫';
    case '自定义':
      return '✏️';
    default:
      return '🍽️';
  }
}

/// Circular tinted chip with the category emoji, used as a list `leading`.
class FoodCategoryAvatar extends StatelessWidget {
  const FoodCategoryAvatar({super.key, required this.category, this.size = 40});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        foodCategoryEmoji(category),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
