import 'dart:math' as math;

import 'models.dart';

/// BMI classification (WHO adult cut-offs, simplified labels).
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese;
}

/// Pure body-composition helpers for the toolbox (no persistence).
abstract final class BodyMetrics {
  /// BMI = weight / height_m².
  static double bmi({required double weightKg, required double heightCm}) {
    final m = heightCm / 100;
    if (m <= 0 || weightKg <= 0) return 0;
    return weightKg / (m * m);
  }

  static BmiCategory bmiCategory(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Waist-to-height ratio. Reference line often cited: 0.5.
  static const whtrReference = 0.5;

  static double waistToHeightRatio({
    required double waistCm,
    required double heightCm,
  }) {
    if (heightCm <= 0 || waistCm <= 0) return 0;
    return waistCm / heightCm;
  }

  /// Devine ideal body weight (kg). Height must be above 5 ft for the
  /// linear term; below that we still return the base (50 / 45.5).
  static double idealWeightDevine({
    required Sex sex,
    required double heightCm,
  }) {
    final inches = heightCm / 2.54;
    final over = inches - 60;
    final base = sex == Sex.male ? 50.0 : 45.5;
    if (over <= 0) return base;
    return base + 2.3 * over;
  }

  /// US Navy circumference method (metric / cm form).
  /// Male: abdomen (waist), neck, height.
  /// Female: waist, hip, neck, height.
  /// Returns null when inputs are invalid for the logarithms.
  static double? bodyFatNavyPct({
    required Sex sex,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipCm,
  }) {
    if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) return null;

    late final double density;
    if (sex == Sex.male) {
      final diff = waistCm - neckCm;
      if (diff <= 0) return null;
      density = 1.0324 -
          0.19077 * _log10(diff) +
          0.15456 * _log10(heightCm);
    } else {
      final hip = hipCm;
      if (hip == null || hip <= 0) return null;
      final sum = waistCm + hip - neckCm;
      if (sum <= 0) return null;
      density = 1.29579 -
          0.35004 * _log10(sum) +
          0.22100 * _log10(heightCm);
    }
    if (density <= 0) return null;
    final pct = 495 / density - 450;
    return pct.clamp(2.0, 60.0);
  }

  /// Fat-free mass (kg). Returns null when [bodyFatPct] is not in (0, 100).
  static double? fatFreeMassKg({
    required double weightKg,
    required double bodyFatPct,
  }) {
    if (weightKg <= 0 || bodyFatPct <= 0 || bodyFatPct >= 100) return null;
    return weightKg * (1 - bodyFatPct / 100);
  }

  /// FFMI = FFM / height_m². Returns null when inputs are invalid.
  static double? ffmi({
    required double weightKg,
    required double heightCm,
    required double bodyFatPct,
  }) {
    final ffm = fatFreeMassKg(weightKg: weightKg, bodyFatPct: bodyFatPct);
    final m = heightCm / 100;
    if (ffm == null || m <= 0) return null;
    return ffm / (m * m);
  }

  /// Height-normalized FFMI: FFMI + 6.1 × (1.8 − height_m).
  static double? normalizedFfmi({
    required double weightKg,
    required double heightCm,
    required double bodyFatPct,
  }) {
    final raw = ffmi(
      weightKg: weightKg,
      heightCm: heightCm,
      bodyFatPct: bodyFatPct,
    );
    if (raw == null) return null;
    final m = heightCm / 100;
    return raw + 6.1 * (1.8 - m);
  }

  /// Rough adult-male bands; females are typically ~3–5 lower.
  static FfmiBand ffmiBand(double ffmi) {
    if (ffmi < 19) return FfmiBand.average;
    if (ffmi < 22) return FfmiBand.trained;
    if (ffmi < 24) return FfmiBand.advanced;
    return FfmiBand.elite;
  }

  static double _log10(double x) => math.log(x) / math.ln10;
}

/// Coarse FFMI reading bands (adult male reference).
enum FfmiBand {
  average,
  trained,
  advanced,
  elite;
}
