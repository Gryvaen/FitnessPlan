import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'loading_config.dart';

class InkParticlePainter extends CustomPainter {
  InkParticlePainter({required this.progress, required this.strength});

  final double progress;
  final double strength;

  static final List<_InkParticle> _particles = _makeParticles();
  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  static List<_InkParticle> _makeParticles() {
    final random = math.Random(2741);
    return List.generate(SwordsmanLoadingConfig.particleCount, (index) {
      return _InkParticle(
        origin: Offset(
          .38 + random.nextDouble() * .34,
          .40 + random.nextDouble() * .24,
        ),
        velocity: Offset(
          .08 + random.nextDouble() * .22,
          (random.nextDouble() - .5) * .12,
        ),
        radius: 1.1 + random.nextDouble() * 2.4,
        delay: random.nextDouble() * .38,
      );
    }, growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    for (final particle in _particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0 || local >= 1) continue;
      final opacity = math.sin(local * math.pi) * strength * .42;
      _paint.color = SwordsmanLoadingConfig.ink.withValues(alpha: opacity);
      final point = Offset(
        (particle.origin.dx + particle.velocity.dx * local) * size.width,
        (particle.origin.dy + particle.velocity.dy * local) * size.height,
      );
      canvas.drawCircle(point, particle.radius * (1 - local * .35), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkParticlePainter oldDelegate) =>
      progress != oldDelegate.progress || strength != oldDelegate.strength;
}

@immutable
class _InkParticle {
  const _InkParticle({
    required this.origin,
    required this.velocity,
    required this.radius,
    required this.delay,
  });

  final Offset origin;
  final Offset velocity;
  final double radius;
  final double delay;
}
