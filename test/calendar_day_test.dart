import 'package:flutter_test/flutter_test.dart';

import 'package:diet/domain/calendar_day.dart';

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
}
