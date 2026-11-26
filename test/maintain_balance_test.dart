import 'dart:math' as math;

import 'package:diet/data/repositories/cultivation_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/maintain_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 11, 20);

  group('threshold & tilt', () {
    test('balanced threshold is 10% of TDEE with a 150 kcal floor', () {
      expect(maintainBalanceThresholdKcal(2500), 250);
      expect(maintainBalanceThresholdKcal(1200), 150);
    });

    test('tilt is signed, monotonic and bounded', () {
      expect(balanceTiltRadians(0), 0);
      expect(balanceTiltRadians(500), greaterThan(0));
      expect(
        balanceTiltRadians(-500),
        closeTo(-balanceTiltRadians(500), 1e-12),
      );
      expect(balanceTiltRadians(2000), greaterThan(balanceTiltRadians(500)));
      expect(balanceTiltRadians(1e9), closeTo(kBalanceMaxTiltRadians, 1e-9));
      expect(balanceTiltRadians(-1e9), closeTo(-kBalanceMaxTiltRadians, 1e-9));
      expect(
        balanceTiltRadians(kBalanceTiltScaleKcal),
        closeTo(kBalanceMaxTiltRadians * 0.7615941559557649, 1e-9),
      );
      expect(kBalanceMaxTiltRadians, closeTo(18 * math.pi / 180, 1e-12));
    });
  });

  group('mind progress', () {
    test('realm boundaries', () {
      expect(computeMindProgress(0).realm, MindRealm.restless);
      expect(computeMindProgress(0).layer, 1);
      expect(computeMindProgress(6).realm, MindRealm.restless);
      expect(computeMindProgress(7).realm, MindRealm.settled);
      expect(computeMindProgress(7).layer, 1);
      expect(computeMindProgress(20).realm, MindRealm.settled);
      expect(computeMindProgress(21).realm, MindRealm.tranquil);
      expect(computeMindProgress(60).realm, MindRealm.stillWater);
      expect(computeMindProgress(119).realm, MindRealm.stillWater);
      expect(computeMindProgress(-3).balancedDays, 0);
    });

    test('layers split the realm evenly', () {
      // settled: 7..21 → 14 days / 9 layers.
      final p = computeMindProgress(14);
      expect(p.layer, 5); // 7 days in / 1.555… per layer → layer 5
      expect(p.layerProgress, inInclusiveRange(0.0, 1.0));
      expect(p.daysToNextRealm, 7);
      expect(computeMindProgress(20).layer, 9);
    });

    test('max realm is perfected', () {
      final p = computeMindProgress(150);
      expect(p.realm, MindRealm.clarity);
      expect(p.isMax, isTrue);
      expect(p.layer, 9);
      expect(p.layerProgress, 1);
      expect(p.daysToNextRealm, isNull);
    });
  });

  group('day entries', () {
    test('day without counted diet and no estimate stays off the scale', () {
      expect(
        MaintainDayEntry.fromContribution(
          date: day,
          totalKcal: 400, // steps only
          dietCounted: false,
          tdee: 2400,
          cheatSurplusKcal: 0,
        ),
        isNull,
      );
    });

    test('net flips the cut sign; balanced within threshold', () {
      // cut total +200 (deficit) → maintain net −200, within 240.
      final e = MaintainDayEntry.fromContribution(
        date: day,
        totalKcal: 200,
        dietCounted: true,
        tdee: 2400,
        cheatSurplusKcal: 0,
      )!;
      expect(e.netKcal, -200);
      expect(e.balanced, isTrue);
      expect(e.estimated, isFalse);

      final over = MaintainDayEntry.fromContribution(
        date: day,
        totalKcal: -300,
        dietCounted: true,
        tdee: 2400,
        cheatSurplusKcal: 0,
      )!;
      expect(over.netKcal, 300);
      expect(over.balanced, isFalse);
    });

    test('indulgence estimate goes to the right pan and is never balanced', () {
      final e = MaintainDayEntry.fromContribution(
        date: day,
        totalKcal: 400 - 1000, // steps 400, surplus 1000
        dietCounted: false,
        tdee: 2400,
        cheatSurplusKcal: 1000,
      )!;
      expect(e.netKcal, 600);
      expect(e.estimated, isTrue);
      expect(e.balanced, isFalse);

      final small = MaintainDayEntry.fromContribution(
        date: day,
        totalKcal: -100,
        dietCounted: false,
        tdee: 2400,
        cheatSurplusKcal: 100,
      )!;
      expect(small.balanced, isFalse);
    });
  });

  test('balance sums pans separately', () {
    MaintainDayEntry e(double net, {bool balanced = false}) => MaintainDayEntry(
      date: day,
      netKcal: net,
      balanced: balanced,
      estimated: false,
    );
    final b = MaintainBalance.fromEntries([
      e(-300),
      e(500),
      e(-100, balanced: true),
      e(50, balanced: true),
    ]);
    expect(b.leftKcal, 400);
    expect(b.rightKcal, 550);
    expect(b.netKcal, 150);
    expect(b.balancedDays, 2);
    expect(b.weighedDays, 4);
    expect(b.tiltRadians, greaterThan(0));
    expect(const MaintainBalance().tiltRadians, 0);
  });

  test('state json round-trips', () {
    final state = MaintainCultivationState(
      frozenBalancedDays: 12,
      segments: [
        CutCultivationSegment(
          start: day,
          end: day.add(const Duration(days: 3)),
        ),
        CutCultivationSegment(start: day.add(const Duration(days: 5))),
      ],
    );
    final back = MaintainCultivationState.fromJson(state.toJson());
    expect(back.frozenBalancedDays, 12);
    expect(back.segments, hasLength(2));
    expect(back.openSegment?.start, day.add(const Duration(days: 5)));
  });

  test('repository freezes and reopens without sharing a day', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MaintainCultivationRepository(
      await SharedPreferences.getInstance(),
    );
    final today = CalendarDay.todayLocal();

    var s = await repo.openSegment();
    expect(s.openSegment?.start, today);

    s = await repo.freezeOpenSegment(openBalancedDays: 4, endDay: today);
    expect(s.openSegment, isNull);
    expect(s.frozenBalancedDays, 4);

    s = await repo.openSegment(preferredStart: today);
    expect(s.openSegment?.start, today.add(const Duration(days: 1)));
    s = await repo.freezeOpenSegment(openBalancedDays: 3, endDay: today);
    expect(s.frozenBalancedDays, 7);
    expect(repo.load().frozenBalancedDays, 7);
  });
}
