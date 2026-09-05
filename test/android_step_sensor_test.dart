import 'package:diet/data/services/android_step_sensor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepSensorAccumulator', () {
    test('first sample anchors at zero for the day', () {
      final snap = StepSensorAccumulator.apply(
        dateKey: '2026-09-05',
        cumulative: 12000,
        storedDateKey: null,
        storedToday: 0,
        storedLastCumulative: null,
      );
      expect(snap.todaySteps, 0);
      expect(snap.lastCumulative, 12000);
      expect(snap.dateKey, '2026-09-05');
    });

    test('same-day delta accumulates', () {
      final first = StepSensorAccumulator.apply(
        dateKey: '2026-09-05',
        cumulative: 1000,
        storedDateKey: null,
        storedToday: 0,
        storedLastCumulative: null,
      );
      final second = StepSensorAccumulator.apply(
        dateKey: '2026-09-05',
        cumulative: 1600,
        storedDateKey: first.dateKey,
        storedToday: first.todaySteps,
        storedLastCumulative: first.lastCumulative,
      );
      expect(second.todaySteps, 600);
      expect(second.lastCumulative, 1600);
    });

    test('new day resets even if cumulative grew overnight', () {
      final snap = StepSensorAccumulator.apply(
        dateKey: '2026-09-06',
        cumulative: 5000,
        storedDateKey: '2026-09-05',
        storedToday: 2000,
        storedLastCumulative: 4000,
      );
      expect(snap.todaySteps, 0);
      expect(snap.lastCumulative, 5000);
    });

    test('reboot keeps prior today and adds post-reboot steps', () {
      final snap = StepSensorAccumulator.apply(
        dateKey: '2026-09-05',
        cumulative: 80,
        storedDateKey: '2026-09-05',
        storedToday: 1500,
        storedLastCumulative: 9000,
      );
      expect(snap.todaySteps, 1580);
      expect(snap.lastCumulative, 80);
    });
  });
}
