import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/domain/goal_quotes.dart';
import 'package:diet/domain/models.dart';

void main() {
  final han = RegExp(r'[\u4e00-\u9fff]');

  test('every English quote list has exactly 100 entries', () {
    expect(kCutQuotesEn, hasLength(100));
    expect(kMaintainQuotesEn, hasLength(100));
    expect(kBulkQuotesEn, hasLength(100));
  });

  test('every English quote is non-empty and contains no Han characters', () {
    for (final list in [kCutQuotesEn, kMaintainQuotesEn, kBulkQuotesEn]) {
      for (final quote in list) {
        expect(quote, isNotEmpty);
        expect(han.hasMatch(quote), isFalse, reason: 'Han chars in: $quote');
      }
    }
  });

  test('goalQuoteForDay picks Chinese for zh and English for en', () {
    const zh = Locale('zh');
    const en = Locale('en');
    final day = DateTime(2026, 3, 1);

    for (final goal in FitnessGoal.values) {
      final zhQuote = goalQuoteForDay(goal, day, zh);
      final enQuote = goalQuoteForDay(goal, day, en);
      expect(han.hasMatch(zhQuote), isTrue, reason: 'expected Han for $goal');
      expect(han.hasMatch(enQuote), isFalse, reason: 'expected no Han for $goal');
    }
  });

  test('goalQuoteForDay is deterministic per day', () {
    const en = Locale('en');
    final day = DateTime(2026, 3, 1);
    final again = goalQuoteForDay(FitnessGoal.cut, day, en);
    final same = goalQuoteForDay(FitnessGoal.cut, day, en);
    expect(again, same);
  });

  test('zh and en quotes for the same day share the same list index', () {
    const zh = Locale('zh');
    const en = Locale('en');
    for (final day in [
      DateTime(2026, 1, 1),
      DateTime(2026, 3, 1),
      DateTime(2026, 12, 31),
    ]) {
      for (final goal in FitnessGoal.values) {
        final zhList = switch (goal) {
          FitnessGoal.cut => kCutQuotes,
          FitnessGoal.maintain => kMaintainQuotes,
          FitnessGoal.bulk => kBulkQuotes,
        };
        final enList = switch (goal) {
          FitnessGoal.cut => kCutQuotesEn,
          FitnessGoal.maintain => kMaintainQuotesEn,
          FitnessGoal.bulk => kBulkQuotesEn,
        };
        final zhQuote = goalQuoteForDay(goal, day, zh);
        final enQuote = goalQuoteForDay(goal, day, en);
        expect(enList[zhList.indexOf(zhQuote)], enQuote);
      }
    }
  });
}
