import 'package:diet/domain/maintain_balance.dart';
import 'package:diet/ui/profile/balance_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level beam hangs both pans at the same height, mirrored', () {
    final (l, r) = balanceHookPoints(0, 400);
    expect(l.dy, closeTo(r.dy, 400 * 0.01));
    expect(l.dx + r.dx, closeTo(400, 400 * 0.01));
    expect(l.dx, lessThan(200));
  });

  test('positive tilt sinks the right (surplus) pan', () {
    final (l0, r0) = balanceHookPoints(0, 400);
    final (l, r) = balanceHookPoints(kBalanceMaxTiltRadians, 400);
    expect(r.dy, greaterThan(r0.dy));
    expect(l.dy, lessThan(l0.dy));
    // Pans stay on screen at the max tilt.
    expect(l.dx, greaterThan(0));
    expect(r.dx, lessThan(400));
  });

  test('pan shares split the total weighed kcal', () {
    const b = MaintainBalance(leftKcal: 300, rightKcal: 900);
    expect(b.leftShare, closeTo(0.25, 1e-12));
    expect(b.rightShare, closeTo(0.75, 1e-12));
    expect(const MaintainBalance().leftShare, 0);
    expect(const MaintainBalance().rightShare, 0);
  });
}
