import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Intake progress ring with a percentage in the centre.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.eaten,
    required this.target,
    required this.over,
    this.size = 108,
    this.strokeWidth = 10,
    this.color,
    this.trackColor,
    this.centerLabel,
    this.labelColor,
    this.metaColor,
  });

  final double eaten;
  final double target;
  final bool over;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;

  /// Small caption under the percentage.
  final String? centerLabel;
  final Color? labelColor;
  final Color? metaColor;

  /// Unclamped fraction (may exceed 1 when over target).
  double get fraction =>
      target <= 0 || !target.isFinite || !eaten.isFinite ? 0 : eaten / target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final f = fraction;
    final progress = f.clamp(0.0, 1.0);
    final ringColor = over ? scheme.error : (color ?? visuals.accent);
    final centerColor = over ? scheme.error : (labelColor ?? scheme.onSurface);
    final percent = (f * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: ringColor,
          trackColor: trackColor ?? visuals.track,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: centerColor,
                  height: 1.0,
                ),
              ),
              if (centerLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  centerLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: metaColor ?? scheme.onSurfaceVariant,
                  ),
                ),
              ],
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
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// One of the four metric columns under the Today ring
/// (protein / carbs / fat / water).
///
/// Value and unit are laid out with [Wrap] so that on narrow widths the
/// "/ target unit" part moves to its own line instead of overflowing.
class MacroColumn extends StatelessWidget {
  const MacroColumn({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    this.decimals = 0,
    this.labelColor,
    this.metaColor,
    this.capProgress = true,
    this.semanticsLabel,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;
  final int decimals;
  final Color? labelColor;
  final Color? metaColor;
  final bool capProgress;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final safeCurrent = current.isFinite ? current : 0.0;
    final safeTarget = target.isFinite ? target : 0.0;
    final ratio = safeTarget <= 0 ? 0.0 : safeCurrent / safeTarget;
    final over = ratio > 1.0 + 1e-9;
    final barColor = over && capProgress ? scheme.error : color;
    final valueText = safeCurrent.toStringAsFixed(decimals);
    final targetText = safeTarget.toStringAsFixed(decimals);

    return Semantics(
      label: semanticsLabel ?? '$label $valueText / $targetText $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: labelColor ?? scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 2,
            children: [
              Text(
                valueText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: over ? scheme.error : (labelColor ?? scheme.onSurface),
                ),
              ),
              Text(
                '/$targetText $unit',
                style: theme.textTheme.labelSmall?.copyWith(
                  height: 1.2,
                  color: metaColor ?? scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: visuals.track),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: ColoredBox(color: barColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Water cup: thin lid on top (tap = undo one serving) and a glass body
/// below (tap = add one serving). Total height matches the calorie ring.
class WaterCupControl extends StatelessWidget {
  const WaterCupControl({
    super.key,
    required this.progress,
    required this.onAdd,
    required this.onUndo,
    required this.addLabel,
    required this.undoLabel,
    this.height = 108,
    this.width = 60,
  });

  /// Fill fraction; values above 1 are drawn as full.
  final double progress;
  final VoidCallback? onAdd;
  final VoidCallback? onUndo;
  final String addLabel;
  final String undoLabel;
  final double height;
  final double width;

  static const double lidZoneHeight = 22;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final cupWidth = width - 10;
    final bodyHeight = height - lidZoneHeight;
    final clamped = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    void haptic() {
      HapticFeedback.selectionClick();
    }

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lid + gap. The tap zone is taller than the drawn lid.
          Semantics(
            button: true,
            enabled: onUndo != null,
            label: undoLabel,
            child: Tooltip(
              message: undoLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onUndo == null
                      ? null
                      : () {
                          haptic();
                          onUndo!();
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: width,
                    height: lidZoneHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: SizedBox(
                          width: math.min(width, cupWidth + 6),
                          height: 9,
                          child: CustomPaint(
                            painter: _WaterCupLidPainter(
                              stroke: onUndo == null
                                  ? visuals.waterStroke.withValues(alpha: 0.45)
                                  : visuals.waterStroke,
                              fill: visuals.cupGlass,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: onAdd != null,
            label: addLabel,
            child: Tooltip(
              message: addLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAdd == null
                      ? null
                      : () {
                          haptic();
                          onAdd!();
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: width,
                    height: bodyHeight,
                    child: Center(
                      child: SizedBox(
                        width: cupWidth,
                        height: bodyHeight,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: clamped),
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, level, _) => CustomPaint(
                            painter: _WaterCupBodyPainter(
                              level: level,
                              stroke: visuals.waterStroke,
                              glass: visuals.cupGlass,
                              water: visuals.waterFill,
                              waterDeep: visuals.waterFillDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slightly tapered glass with a rounded bottom, translucent water and a
/// soft wave surface.
class _WaterCupBodyPainter extends CustomPainter {
  _WaterCupBodyPainter({
    required this.level,
    required this.stroke,
    required this.glass,
    required this.water,
    required this.waterDeep,
  });

  final double level;
  final Color stroke;
  final Color glass;
  final Color water;
  final Color waterDeep;

  static const _strokeWidth = 1.6;

  Path _bodyPath(Size size) {
    final w = size.width;
    final h = size.height;
    const inset = _strokeWidth;
    final topL = w * 0.06 + inset;
    final topR = w * 0.94 - inset;
    final botL = w * 0.20 + inset;
    final botR = w * 0.80 - inset;
    final top = inset;
    final bottom = h - inset;
    final r = math.min(w * 0.18, (botR - botL) / 2);

    // Side wall x at a given y (linear taper).
    double leftAt(double y) =>
        topL + (botL - topL) * ((y - top) / (bottom - top));
    double rightAt(double y) =>
        topR + (botR - topR) * ((y - top) / (bottom - top));

    final path = Path()
      ..moveTo(topL, top)
      ..lineTo(leftAt(bottom - r), bottom - r)
      ..quadraticBezierTo(botL, bottom, botL + r, bottom)
      ..lineTo(botR - r, bottom)
      ..quadraticBezierTo(botR, bottom, rightAt(bottom - r), bottom - r)
      ..lineTo(topR, top);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = _bodyPath(size);
    final closed = Path.from(outline)..close();

    // Glass tint.
    canvas.drawPath(closed, Paint()..color = glass);

    if (level > 0) {
      const inset = _strokeWidth;
      final top = inset;
      final bottom = h - inset;
      final surfaceY = bottom - (bottom - top) * level;
      // Keep a little head-room so the wave never pokes above the rim.
      final amp = math.min(1.6, (surfaceY - top).clamp(0.0, 1.6));

      Path wave(double phase, double y) {
        final p = Path()..moveTo(-2, y);
        const steps = 24;
        for (var i = 0; i <= steps; i++) {
          final x = -2 + (w + 4) * i / steps;
          final yy = y + math.sin(phase + i / steps * 2 * math.pi * 1.5) * amp;
          p.lineTo(x, yy);
        }
        p
          ..lineTo(w + 2, h + 2)
          ..lineTo(-2, h + 2)
          ..close();
        return p;
      }

      canvas.save();
      canvas.clipPath(closed);
      final gradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [water, waterDeep],
        ).createShader(Rect.fromLTWH(0, surfaceY, w, h - surfaceY));
      canvas.drawPath(wave(0, surfaceY), gradient);
      // Second, fainter ripple slightly offset for softness.
      canvas.drawPath(
        wave(math.pi * 0.8, surfaceY + amp * 0.9),
        Paint()..color = water.withValues(alpha: water.a * 0.55),
      );
      canvas.restore();
    }

    // Subtle glass highlight on the left wall.
    final hl = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.16, h * 0.18), Offset(w * 0.22, h * 0.72), hl);

    canvas.drawPath(
      outline,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterCupBodyPainter old) =>
      old.level != level ||
      old.stroke != stroke ||
      old.glass != glass ||
      old.water != water ||
      old.waterDeep != waterDeep;
}

/// Thin flat lid with a tiny centre nub; drawn separately from the body.
class _WaterCupLidPainter extends CustomPainter {
  _WaterCupLidPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // A thin, slightly wider disc floating above the rim — drawn as a
    // shallow ellipse so it reads as a lid seen from a low angle.
    final rect = Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6);
    canvas.drawOval(rect, Paint()..color = fill);
    canvas.drawOval(
      rect,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    // Soft highlight along the upper edge.
    final hi = Rect.fromLTWH(
      rect.left + rect.width * 0.18,
      rect.top + rect.height * 0.22,
      rect.width * 0.64,
      rect.height * 0.28,
    );
    canvas.drawOval(hi, Paint()..color = Colors.white.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _WaterCupLidPainter old) =>
      old.stroke != stroke || old.fill != fill;
}
