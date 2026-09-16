import 'package:flutter_test/flutter_test.dart';

import 'package:diet/domain/cultivation.dart';

void main() {
  group('computeCultivationProgress from kcal-equivalent kg', () {
    test('7700 kcal ≈ 1 kg moves within qi refining layers', () {
      final p = computeCultivationProgress(1.0);
      expect(p.realm, CultivationRealm.qiRefining);
      expect(p.layer, greaterThanOrEqualTo(1));
      expect(p.kgLost, 1.0);
    });

    test('negative total kcal clamps to zero progress', () {
      final p = computeCultivationProgress(-2.0);
      expect(p.kgLost, 0);
      expect(p.realm, CultivationRealm.qiRefining);
      expect(p.layer, 1);
    });

    test('3 kg equivalent reaches foundation', () {
      final p = computeCultivationProgress(3.0);
      expect(p.realm, CultivationRealm.foundation);
    });
  });
}
