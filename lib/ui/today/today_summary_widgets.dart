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
