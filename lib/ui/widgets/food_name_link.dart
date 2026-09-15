import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../theme/macro_color.dart';

/// Path to the food detail page that won't remount [StatefulShellRoute]
/// when the caller already sits on a root route (e.g. `/log-meal`, `/meal/:id`).
String foodDetailLocation(
  BuildContext context,
  int foodId, {
  MealType? mealType,
}) {
  final path = GoRouterState.of(context).uri.path;
  final base = (path == '/foods' || path.startsWith('/foods/'))
      ? '/foods/$foodId'
      : '/food-detail/$foodId';
  if (mealType == null) return base;
  return Uri(path: base, queryParameters: {'mealType': mealType.name})
      .toString();
}

Future<T?> openFoodDetail<T extends Object?>(
  BuildContext context,
  int foodId, {
  MealType? mealType,
}) {
  return context.push<T>(foodDetailLocation(context, foodId, mealType: mealType));
}

/// Colored, tappable food name that opens the food detail page.
class FoodNameLink extends StatelessWidget {
  const FoodNameLink({
    super.key,
    required this.name,
    required this.foodId,
    this.carbG = 0,
    this.proteinG = 0,
    this.fatG = 0,
    this.style,
    this.maxLines,
    this.overflow,
    this.onTap,
  });

  final String name;
  final int foodId;
  final double carbG;
  final double proteinG;
  final double fatG;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Override when the caller needs to refresh after returning from detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = dominantMacroColor(
      carbG: carbG,
      proteinG: proteinG,
      fatG: fatG,
    );
    return GestureDetector(
      onTap: onTap ?? () => openFoodDetail(context, foodId),
      behavior: HitTestBehavior.translucent,
      child: Text(
        name,
        maxLines: maxLines,
        overflow: overflow,
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          color: color,
        ),
      ),
    );
  }
}
