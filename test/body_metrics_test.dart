import 'package:flutter_test/flutter_test.dart';
import 'package:diet/domain/body_metrics.dart';
import 'package:diet/domain/models.dart';

void main() {
  group('BodyMetrics.bmi', () {
    test('70kg / 175cm ≈ 22.86 normal', () {
      final v = BodyMetrics.bmi(weightKg: 70, heightCm: 175);
      expect(v, closeTo(22.857, 0.01));
      expect(BodyMetrics.bmiCategory(v), BmiCategory.normal);
    });

    test('category cut-offs', () {
      expect(BodyMetrics.bmiCategory(18.4), BmiCategory.underweight);
      expect(BodyMetrics.bmiCategory(18.5), BmiCategory.normal);
      expect(BodyMetrics.bmiCategory(24.9), BmiCategory.normal);
      expect(BodyMetrics.bmiCategory(25), BmiCategory.overweight);
      expect(BodyMetrics.bmiCategory(30), BmiCategory.obese);
    });
  });

  group('BodyMetrics.waistToHeightRatio', () {
    test('80 / 160 = 0.5', () {
      expect(
        BodyMetrics.waistToHeightRatio(waistCm: 80, heightCm: 160),
        closeTo(0.5, 1e-9),
      );
    });
  });

  group('BodyMetrics.idealWeightDevine', () {
    test('male 183cm (~72 in)', () {
      // 183/2.54 ≈ 72.047 → over 5ft by ~12.047 → 50 + 2.3*12.047
      final w = BodyMetrics.idealWeightDevine(
        sex: Sex.male,
        heightCm: 183,
      );
      expect(w, closeTo(50 + 2.3 * (183 / 2.54 - 60), 0.01));
    });

    test('female 165cm', () {
      final w = BodyMetrics.idealWeightDevine(
        sex: Sex.female,
        heightCm: 165,
      );
      expect(w, closeTo(45.5 + 2.3 * (165 / 2.54 - 60), 0.01));
    });
  });

  group('BodyMetrics.bodyFatNavyPct', () {
    test('male sample', () {
      final pct = BodyMetrics.bodyFatNavyPct(
        sex: Sex.male,
        heightCm: 178,
        neckCm: 38,
        waistCm: 85,
      );
      expect(pct, isNotNull);
      // Sanity: athletic-ish male mid-teens body fat
      expect(pct!, greaterThan(8));
      expect(pct, lessThan(25));
    });

    test('female sample needs hip', () {
      expect(
        BodyMetrics.bodyFatNavyPct(
          sex: Sex.female,
          heightCm: 165,
          neckCm: 32,
          waistCm: 70,
        ),
        isNull,
      );
      final pct = BodyMetrics.bodyFatNavyPct(
        sex: Sex.female,
        heightCm: 165,
        neckCm: 32,
        waistCm: 70,
        hipCm: 95,
      );
      expect(pct, isNotNull);
      expect(pct!, greaterThan(10));
      expect(pct, lessThan(40));
    });

    test('invalid waist <= neck returns null', () {
      expect(
        BodyMetrics.bodyFatNavyPct(
          sex: Sex.male,
          heightCm: 178,
          neckCm: 40,
          waistCm: 40,
        ),
        isNull,
      );
    });
  });

  group('BodyMetrics.ffmi', () {
    test('80kg / 180cm / 15% → FFM 68, FFMI ≈ 21.0', () {
      final ffm = BodyMetrics.fatFreeMassKg(weightKg: 80, bodyFatPct: 15);
      expect(ffm, closeTo(68, 1e-9));

      final v = BodyMetrics.ffmi(
        weightKg: 80,
        heightCm: 180,
        bodyFatPct: 15,
      );
      expect(v, closeTo(68 / (1.8 * 1.8), 0.01));
      expect(v, closeTo(21.0, 0.05));

      // height == 1.8m → normalized equals raw
      final norm = BodyMetrics.normalizedFfmi(
        weightKg: 80,
        heightCm: 180,
        bodyFatPct: 15,
      );
      expect(norm, closeTo(v!, 1e-9));
      expect(BodyMetrics.ffmiBand(v), FfmiBand.trained);
    });

    test('normalized adjusts for height ≠ 1.8m', () {
      final raw = BodyMetrics.ffmi(
        weightKg: 80,
        heightCm: 170,
        bodyFatPct: 15,
      )!;
      final norm = BodyMetrics.normalizedFfmi(
        weightKg: 80,
        heightCm: 170,
        bodyFatPct: 15,
      )!;
      expect(norm, closeTo(raw + 6.1 * (1.8 - 1.7), 0.01));
    });

    test('invalid body fat returns null', () {
      expect(
        BodyMetrics.ffmi(weightKg: 80, heightCm: 180, bodyFatPct: 0),
        isNull,
      );
      expect(
        BodyMetrics.ffmi(weightKg: 80, heightCm: 180, bodyFatPct: 100),
        isNull,
      );
    });

    test('band cut-offs', () {
      expect(BodyMetrics.ffmiBand(18.9), FfmiBand.average);
      expect(BodyMetrics.ffmiBand(19), FfmiBand.trained);
      expect(BodyMetrics.ffmiBand(21.9), FfmiBand.trained);
      expect(BodyMetrics.ffmiBand(22), FfmiBand.advanced);
      expect(BodyMetrics.ffmiBand(23.9), FfmiBand.advanced);
      expect(BodyMetrics.ffmiBand(24), FfmiBand.elite);
    });
  });
}
