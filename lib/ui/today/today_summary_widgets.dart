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

/// Cup outline with liquid fill, drawn as a short tapered cylinder.
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

  static const _pi = 3.14159265;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Tapered cylinder: wider rim, narrower base (same style as the lid).
    final topL = w * 0.14;
    final topR = w * 0.86;
    final botL = w * 0.26;
    final botR = w * 0.74;
    final topY = h * 0.08;
    final botY = h * 0.90;
    final topOvalH = h * 0.12;
    final botOvalH = h * 0.09;

    final topOval = Rect.fromLTRB(topL, topY, topR, topY + topOvalH);
    final botOval = Rect.fromLTRB(botL, botY - botOvalH, botR, botY);
    final midTop = topY + topOvalH / 2;
    final midBot = botY - botOvalH / 2;

    // Cup body silhouette for clipping liquid.
    final body = Path()
      ..moveTo(topL, midTop)
      ..lineTo(botL, midBot)
      ..arcTo(botOval, _pi, -_pi, false)
      ..lineTo(topR, midTop)
      ..arcTo(topOval, 0, _pi, false)
      ..close();

    if (progress > 0) {
      final liquidPaint = Paint()
        ..color = progress >= 1 ? fullColor : liquidColor
        ..style = PaintingStyle.fill;

      // Interpolate rim→base for the liquid surface ellipse.
      final t = 1.0 - progress;
      final surfL = topL + (botL - topL) * t;
      final surfR = topR + (botR - topR) * t;
      final surfMidY = midTop + (midBot - midTop) * t;
      final surfOvalH = topOvalH + (botOvalH - topOvalH) * t;
      final surfOval = Rect.fromCenter(
        center: Offset((surfL + surfR) / 2, surfMidY),
        width: surfR - surfL,
        height: surfOvalH,
      );

      canvas.save();
      canvas.clipPath(body);
      // Liquid column under the surface midline.
      final liquidBody = Path()
        ..moveTo(surfL, surfMidY)
        ..lineTo(botL, midBot)
        ..arcTo(botOval, _pi, -_pi, false)
        ..lineTo(surfR, surfMidY)
        ..close();
      canvas.drawPath(liquidBody, liquidPaint);
      canvas.drawOval(surfOval, liquidPaint);
      canvas.restore();

      // Liquid surface ellipse (visible on top of the fill).
      canvas.drawOval(
        surfOval,
        Paint()
          ..color = outlineColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Side walls.
    canvas.drawLine(Offset(topL, midTop), Offset(botL, midBot), outline);
    canvas.drawLine(Offset(topR, midTop), Offset(botR, midBot), outline);

    // Base front edge.
    canvas.drawArc(botOval, 0, _pi, false, outline);

    // Rim ellipse (opening).
    canvas.drawOval(topOval, outline);
  }

  @override
  bool shouldRepaint(covariant _WaterCupPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Cylindrical cup-lid silhouette, paired with [WaterCup] for −ml taps.
class WaterCupLid extends StatelessWidget {
  const WaterCupLid({
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
      width: 36,
      height: 72,
      child: CustomPaint(
        painter: _WaterCupLidPainter(
          outlineColor: outline,
          fillColor: scheme.primary.withValues(alpha: enabled ? 0.12 : 0.04),
        ),
      ),
    );
  }
}

class _WaterCupLidPainter extends CustomPainter {
  _WaterCupLidPainter({
    required this.outlineColor,
    required this.fillColor,
  });

  final Color outlineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Short cylinder aligned with the cup rim, flush to the right.
    final left = 3.0;
    final right = w - 1;
    final top = h * 0.06;
    final bottom = h * 0.28;
    final ovalH = (bottom - top) * 0.32;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final topOval = Rect.fromLTRB(left, top, right, top + ovalH);
    final bottomOval = Rect.fromLTRB(left, bottom - ovalH, right, bottom);
    final midTop = top + ovalH / 2;
    final midBottom = bottom - ovalH / 2;

    // Solid cylinder: side wall + bottom/top caps.
    canvas.drawRect(Rect.fromLTRB(left, midTop, right, midBottom), fill);
    canvas.drawOval(bottomOval, fill);
    canvas.drawOval(topOval, fill);

    // Side walls.
    canvas.drawLine(Offset(left, midTop), Offset(left, midBottom), outline);
    canvas.drawLine(Offset(right, midTop), Offset(right, midBottom), outline);

    // Bottom front edge (lower half of bottom ellipse).
    canvas.drawArc(bottomOval, 0, 3.14159265, false, outline);

    // Top face ellipse.
    canvas.drawOval(topOval, outline);
  }

  @override
  bool shouldRepaint(covariant _WaterCupLidPainter oldDelegate) =>
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.fillColor != fillColor;
}
