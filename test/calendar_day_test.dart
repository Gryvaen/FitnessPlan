import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

// The daylight-saving groups only bite in a zone that has DST; run with
// `TZ=America/New_York flutter test test/calendar_day_test.dart`.
// Elsewhere they still pass, they just can't catch a regression.

/// Days whose local length is 23 or 25 hours in the US or the EU.
final _dstDays = [
  DateTime(2026, 3, 8),
  DateTime(2026, 3, 29),
  DateTime(2026, 10, 25),
  DateTime(2026, 11, 1),
];

void main() {
  group('CalendarDay', () {
    test('dayOnly strips time', () {
      final d = DateTime(2026, 7, 16, 15, 30, 45);
      expect(CalendarDay.dayOnly(d), DateTime(2026, 7, 16));
    });

    test('isLocalToday respects optional now', () {
      final now = DateTime(2026, 7, 16, 8);
      expect(CalendarDay.isLocalToday(DateTime(2026, 7, 16), now), isTrue);
      expect(CalendarDay.isLocalToday(DateTime(2026, 7, 15), now), isFalse);
      expect(
        CalendarDay.isLocalToday(DateTime(2026, 7, 16, 23, 59), now),
        isTrue,
      );
    });

    test('ensureEditableDay throws for past days', () {
      final now = DateTime(2026, 7, 16);
      expect(
        () => CalendarDay.ensureEditableDay(DateTime(2026, 7, 15), now),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('只能编辑今天'),
          ),
        ),
      );
      expect(
        () => CalendarDay.ensureEditableDay(DateTime(2026, 7, 16), now),
        returnsNormally,
      );
    });
  });

  for (final dst in _dstDays) {
    final before = DateTime(dst.year, dst.month, dst.day - 1);
    final after = DateTime(dst.year, dst.month, dst.day + 1);

    group('around ${dst.month}/${dst.day}', () {
      test('addDays steps one calendar day at a time', () {
        expect(CalendarDay.addDays(before, 1), dst);
        expect(CalendarDay.addDays(dst, 1), after);
        expect(CalendarDay.addDays(after, -1), dst);
        expect(CalendarDay.addDays(after, -2), before);
      });

      test('daysBetween counts calendar days', () {
        expect(CalendarDay.daysBetween(before, after), 2);
        expect(CalendarDay.daysBetween(dst, after), 1);
        expect(CalendarDay.daysBetween(after, before), -2);
        expect(
          CalendarDay.daysBetween(
            DateTime(dst.year, dst.month, dst.day, 23),
            after,
          ),
          1,
        );
      });

      test('carb cycle index advances by one each day', () {
        final start = CalendarDay.addDays(dst, -5);
        for (var i = 0; i < 10; i++) {
          final day = CalendarDay.addDays(start, i);
          expect(StrategyDates.cycleIndexOf(day, start, 4), i % 4);
        }
      });
    });
  }
}
