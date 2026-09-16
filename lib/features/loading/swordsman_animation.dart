import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'loading_config.dart';

@immutable
class SwordsmanFrame {
  const SwordsmanFrame({
    required this.characterDy,
    required this.characterScale,
    required this.characterRotation,
    required this.swordPosition,
    required this.swordRotation,
    required this.swordOpacity,
    required this.slashOpacity,
    required this.slashScaleX,
    required this.slashDx,
    required this.particleProgress,
    required this.particleStrength,
  });

  factory SwordsmanFrame.at(double value, {required bool reduceMotion}) {
    final t = value.clamp(0.0, 1.0);
    final wave = math.sin(t * math.pi * 4);
    if (reduceMotion) {
      return SwordsmanFrame(
        characterDy: wave * .5,
        characterScale: 1,
        characterRotation: 0,
        swordPosition: const Offset(1.2, .39),
        swordRotation: 0,
        swordOpacity: 0,
        slashOpacity: 0,
        slashScaleX: 1,
        slashDx: 0,
        particleProgress: 0,
        particleStrength: 0,
      );
    }

    final strike = _pulse(t, .55, .76, Curves.easeOutCubic);
    final breath = (wave + 1) * .5;
    final pathT = ((t - .20) / .56).clamp(0.0, 1.0);
    final position = _flightPoint(pathT);
    final ahead = _flightPoint(math.min(1, pathT + .002));
    final direction = ahead - position;
    final swordVisible = t < .20 || t > .78 ? 0.0 : _edgeFade(pathT, edge: .08);

    final slashT = ((t - .68) / .08).clamp(0.0, 1.0);
    final slashOpacity = t < .68 || t > .76 ? 0.0 : math.sin(slashT * math.pi);

    final particleT = ((t - .60) / .36).clamp(0.0, 1.0);
    final particleStrength = t < .60 || t > .96
        ? 0.0
        : math.sin(particleT * math.pi);

    return SwordsmanFrame(
      characterDy: wave * SwordsmanLoadingConfig.characterFloat,
      characterScale: _lerp(
        SwordsmanLoadingConfig.characterScaleMin,
        SwordsmanLoadingConfig.characterScaleMax,
        breath,
      ),
      characterRotation:
          wave * SwordsmanLoadingConfig.idleRotation * .35 +
          strike * SwordsmanLoadingConfig.strikeRotation,
      swordPosition: position,
      swordRotation: math.atan2(direction.dy, direction.dx),
      swordOpacity: swordVisible,
      slashOpacity: slashOpacity,
      slashScaleX: _lerp(.2, 1.15, Curves.easeOutCubic.transform(slashT)),
      slashDx: _lerp(-.05, .05, slashT),
      particleProgress: particleT,
      particleStrength: particleStrength,
    );
  }

  final double characterDy;
  final double characterScale;
  final double characterRotation;
  final Offset swordPosition;
  final double swordRotation;
  final double swordOpacity;
  final double slashOpacity;
  final double slashScaleX;
  final double slashDx;
  final double particleProgress;
  final double particleStrength;

  static Offset _flightPoint(double t) {
    if (t < .34) {
      return _bezier(
        t / .34,
        const Offset(-.24, .42),
        const Offset(.02, .20),
        const Offset(.62, .18),
        const Offset(.73, .38),
      );
    }
    if (t < .72) {
      return _bezier(
        (t - .34) / .38,
        const Offset(.73, .38),
        const Offset(.88, .62),
        const Offset(.35, .70),
        const Offset(.27, .50),
      );
    }
    return _bezier(
      (t - .72) / .28,
      const Offset(.27, .50),
      const Offset(.48, .38),
      const Offset(.88, .43),
      const Offset(1.28, .34),
    );
  }

  static Offset _bezier(double t, Offset a, Offset b, Offset c, Offset d) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  static double _pulse(double t, double begin, double end, Curve curve) {
    if (t <= begin || t >= end) return 0;
    final local = (t - begin) / (end - begin);
    return math.sin(curve.transform(local) * math.pi);
  }

  static double _edgeFade(double t, {required double edge}) {
    if (t < edge) return t / edge;
    if (t > 1 - edge) return (1 - t) / edge;
    return 1;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
