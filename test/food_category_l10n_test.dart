import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/l10n/app_localizations_ext.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final zh = lookupAppLocalizations(const Locale('zh'));

  const categories = [
    '畜肉',
    '禽肉',
    '水产',
    '乳类',
    '蛋类',
    '谷类',
    '薯类',
    '豆类',
    '蔬菜',
    '菌藻',
    '水果',
    '坚果',
    '油脂',
    '调味品',
    '饮料',
    '小吃',
    '糖蜜饯',
    '包装食品',
    '自定义',
  ];

  test('every seed category (and the custom bucket) has a distinct '
      'English label', () {
    final labels = categories.map((c) => c.localizedCategory(en)).toSet();
    expect(labels.length, categories.length,
        reason: 'expected all English category labels to be unique');
    for (final c in categories) {
      final label = c.localizedCategory(en);
      expect(label, isNot(c), reason: '$c should translate under English');
      final hasHan = RegExp(r'[\u4e00-\u9fff]').hasMatch(label);
      expect(hasHan, isFalse, reason: 'non-Latin English label for $c: $label');
    }
  });

  test('Chinese locale always returns the original Chinese label', () {
    for (final c in categories) {
      expect(c.localizedCategory(zh), c);
    }
  });

  test('unknown category strings pass through unchanged', () {
    expect('未来分类'.localizedCategory(en), '未来分类');
    expect('未来分类'.localizedCategory(zh), '未来分类');
  });
}
