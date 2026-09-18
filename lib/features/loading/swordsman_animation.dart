import 'package:flutter/material.dart';

@immutable
class SwordsmanFrame {
  const SwordsmanFrame({
    required this.revealProgress,
    required this.swordY,
    required this.swordOpacity,
    required this.inkOpacity,
    required this.inkScale,
    required this.mistDx,
    required this.mistOpacity,
    required this.wakeOpacity,
    required this.wakePulse,
  });

  factory SwordsmanFrame.at(double value, {required bool reduceMotion}) {
    if (reduceMotion) {
      return const SwordsmanFrame(
        revealProgress: 1,
        swordY: -.18,
        swordOpacity: 0,
        inkOpacity: 0,
        inkScale: 1,
        mistDx: 0,
        mistOpacity: .18,
        wakeOpacity: 0,
        wakePulse: 1,
      );
    }

    final t = value.clamp(0.0, 1.0);
    final dissolve = _interval(t, .04, .72, Curves.easeInOutCubic);
    final settle = _interval(t, .68, .94, Curves.easeOutCubic);
    final wakeLife = _fadeWindow(t, .025, .11, .70, .88);

    return SwordsmanFrame(
      revealProgress: dissolve,
      swordY: _lerp(1.08, -.46, dissolve),
      swordOpacity: _fadeWindow(t, .01, .08, .98, 1),
      inkOpacity: _fadeWindow(t, .02, .10, .68, .92) * .72,
      inkScale: _lerp(.82, 1.08, dissolve),
      mistDx: settle * .018,
      mistOpacity: _lerp(0, .24, settle),
      wakeOpacity: wakeLife,
      wakePulse:
          .5 +
          .5 * Curves.easeInOutSine.transform(((t * 5.2) % 1).clamp(0.0, 1.0)),
    );
  }

  final double revealProgress;
  final double swordY;
  final double swordOpacity;
  final double inkOpacity;
  final double inkScale;
  final double mistDx;
  final double mistOpacity;
  final double wakeOpacity;
  final double wakePulse;

  static double _interval(double t, double begin, double end, Curve curve) {
    return curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));
  }

  static double _fadeWindow(
    double t,
    double fadeInStart,
    double fadeInEnd,
    double fadeOutStart,
    double fadeOutEnd,
  ) {
    if (t <= fadeInStart || t >= fadeOutEnd) return 0;
    if (t < fadeInEnd) {
      return (t - fadeInStart) / (fadeInEnd - fadeInStart);
    }
    if (t > fadeOutStart) {
      return 1 - (t - fadeOutStart) / (fadeOutEnd - fadeOutStart);
    }
    return 1;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
