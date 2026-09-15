import 'package:flutter_test/flutter_test.dart';

import 'package:diet/domain/cultivation.dart';

void main() {
  ({DateTime date, double weightKg}) log(int y, int m, int d, double kg) =>
      (date: DateTime(y, m, d), weightKg: kg);

  group('cultivationKgLostFromLogs', () {
    test('full history when since is null', () {
      final logs = [
        log(2026, 1, 1, 80),
        log(2026, 2, 1, 78),
        log(2026, 3, 1, 75),
      ];
      expect(cultivationKgLostFromLogs(logs: logs, since: null), 5);
    });

    test('ignores weight loss before new standard', () {
      final logs = [
        log(2026, 1, 1, 80),
        log(2026, 2, 1, 70), // 10 kg lost before switch
        log(2026, 3, 1, 70), // baseline at switch
        log(2026, 4, 1, 68), // 2 kg after switch
      ];
      expect(
        cultivationKgLostFromLogs(logs: logs, since: DateTime(2026, 3, 1)),
        2,
      );
    });

    test('uses last log on or before since as baseline', () {
      final logs = [
        log(2026, 1, 1, 80),
        log(2026, 2, 28, 79),
        log(2026, 4, 1, 76),
      ];
      // since = Mar 1, baseline = Feb 28 @ 79
      expect(
        cultivationKgLostFromLogs(logs: logs, since: DateTime(2026, 3, 1)),
        3,
      );
    });

    test('returns 0 when only one point after since', () {
      final logs = [
        log(2026, 1, 1, 80),
        log(2026, 3, 1, 70),
      ];
      expect(
        cultivationKgLostFromLogs(logs: logs, since: DateTime(2026, 3, 1)),
        0,
      );
    });
  });
}
