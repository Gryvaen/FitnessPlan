import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/db.dart';
import 'package:diet/l10n/app_localizations_ext.dart';

void main() {
  const withEn = FoodItem(
    id: 1,
    name: '猪肉(瘦)',
    nameEn: 'Pork (Lean)',
    category: '畜肉',
    kcalPer100: 143,
    proteinPer100: 20.2,
    carbPer100: 1.5,
    fatPer100: 6.2,
    alcoholPer100: 0,
    fiberPer100: 0,
    sodiumMgPer100: 57,
    sugarPer100: 0,
    saturatedFatPer100: 2.2,
    calciumMgPer100: 6,
    isCustom: false,
  );

  const withoutEn = FoodItem(
    id: 2,
    name: '自制沙拉',
    category: '自定义',
    kcalPer100: 50,
    proteinPer100: 2,
    carbPer100: 5,
    fatPer100: 2,
    alcoholPer100: 0,
    fiberPer100: 1,
    sodiumMgPer100: 10,
    sugarPer100: 1,
    saturatedFatPer100: 0.5,
    calciumMgPer100: 20,
    isCustom: true,
  );

  Future<String> displayNameUnder(
    WidgetTester tester,
    Locale locale,
    FoodItem food,
  ) async {
    late String result;
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            result = food.displayName(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('English locale uses nameEn when present', (tester) async {
    final result = await displayNameUnder(
      tester,
      const Locale('en'),
      withEn,
    );
    expect(result, 'Pork (Lean)');
  });

  testWidgets('Chinese locale always uses the Chinese name', (tester) async {
    final result = await displayNameUnder(
      tester,
      const Locale('zh'),
      withEn,
    );
    expect(result, '猪肉(瘦)');
  });

  testWidgets(
    'English locale falls back to Chinese name when nameEn is absent '
    '(e.g. custom foods)',
    (tester) async {
      final result = await displayNameUnder(
        tester,
        const Locale('en'),
        withoutEn,
      );
      expect(result, '自制沙拉');
    },
  );
}
