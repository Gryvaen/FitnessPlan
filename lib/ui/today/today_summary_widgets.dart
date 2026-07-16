import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Calorie intake ring with center remain/over label.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.eaten,
    required this.target,
    required this.over,
    required this.remainAbs,
  });

  final double eaten;
  final double target;
  final bool over;
  final double remainAbs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final progress = target <= 0 ? 0.0 : (eaten / target).clamp(0.0, 1.0);
    final ringColor = over ? scheme.error : scheme.primary;
    final centerLabel = over
        ? '超 ${remainAbs.round()}'
        : '剩 ${remainAbs.round()}';

    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: ringColor,
          trackColor: ringColor.withValues(alpha: 0.15),
          strokeWidth: 10,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: over ? scheme.error : scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${eaten.round()} / ${target.round()}',
                style: theme.textTheme.meta,
              ),
              Text('kcal', style: theme.textTheme.meta),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// Compact horizontal macro progress row.
class MacroMini extends StatelessWidget {
  const MacroMini({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.remainLabel,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final String remainLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.5);
    final over = progress > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: over ? scheme.error : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                '${current.round()} / ${target.round()} g',
                style: theme.textTheme.meta,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 6,
              color: over ? scheme.error : color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 4),
          Text(remainLabel, style: theme.textTheme.meta),
        ],
      ),
    );
  }
}

/// Simple cup outline with liquid fill from bottom.
class WaterCup extends StatelessWidget {
  const WaterCup({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 56,
      height: 72,
      child: CustomPaint(
        painter: _WaterCupPainter(
          progress: progress.clamp(0.0, 1.0),
          outlineColor: scheme.outline,
          liquidColor: scheme.primary.withValues(alpha: 0.55),
          fullColor: scheme.primaryContainer.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _WaterCupPainter extends CustomPainter {
  _WaterCupPainter({
    required this.progress,
    required this.outlineColor,
    required this.liquidColor,
    required this.fullColor,
  });

  final double progress;
  final Color outlineColor;
  final Color liquidColor;
  final Color fullColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(w * 0.22, h * 0.08)
      ..lineTo(w * 0.78, h * 0.08)
      ..lineTo(w * 0.68, h * 0.92)
      ..lineTo(w * 0.32, h * 0.92)
      ..close();

    final innerTop = h * 0.14;
    final innerBottom = h * 0.86;
    final innerHeight = innerBottom - innerTop;
    final fillTop = innerBottom - innerHeight * progress;

    canvas.save();
    canvas.clipPath(body);
    if (progress > 0) {
      final fill = Paint()
        ..color = progress >= 1 ? fullColor : liquidColor;
      canvas.drawRect(
        Rect.fromLTRB(0, fillTop, w, innerBottom),
        fill,
      );
    }
    canvas.restore();

    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, outline);

    // Rim
    canvas.drawLine(
      Offset(w * 0.2, h * 0.08),
      Offset(w * 0.8, h * 0.08),
      outline..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterCupPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Compact screw-cap silhouette, paired with [WaterCup] for −ml taps.
class WaterBottleCap extends StatelessWidget {
  const WaterBottleCap({
    super.key,
    this.enabled = true,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = enabled
        ? scheme.outline
        : scheme.outline.withValues(alpha: 0.35);
    return SizedBox(
      width: 28,
      height: 72,
      child: CustomPaint(
        painter: _WaterBottleCapPainter(
          outlineColor: outline,
          fillColor: scheme.primary.withValues(alpha: enabled ? 0.12 : 0.04),
        ),
      ),
    );
  }
}

class _WaterBottleCapPainter extends CustomPainter {
  _WaterBottleCapPainter({
    required this.outlineColor,
    required this.fillColor,
  });

  final Color outlineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Sit against the cup: draw near the right edge, level with the cup rim.
    final top = h * 0.08;
    final bottom = h * 0.34;
    final right = w - 1;
    final left = right - 18;
    final midX = (left + right) / 2;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Flat top lip (slightly wider than body).
    final lipH = (bottom - top) * 0.28;
    final lip = RRect.fromRectAndRadius(
      Rect.fromLTRB(left - 1.5, top, right + 0.5, top + lipH),
      const Radius.circular(3),
    );
    canvas.drawRRect(lip, fill);
    canvas.drawRRect(lip, outline);

    // Short cylindrical body under the lip.
    final bodyTop = top + (bottom - top) * 0.22;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, bodyTop, right, bottom),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, outline);

    // Fine knurl ridges.
    final ridge = Paint()
      ..color = outlineColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final ridgeTop = bodyTop + 3;
    final ridgeBottom = bottom - 3;
    for (var i = 0; i < 4; i++) {
      final t = (i + 1) / 5;
      final x = left + (right - left) * t;
      canvas.drawLine(Offset(x, ridgeTop), Offset(x, ridgeBottom), ridge);
    }

    // Crown dash on the lip.
    final crown = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(midX - 4, top + 2.5),
      Offset(midX + 4, top + 2.5),
      crown,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterBottleCapPainter oldDelegate) =>
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.fillColor != fillColor;
}
