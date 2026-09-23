import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../ink/ink_icon.dart';

/// Intake progress ring with a percentage in the centre.
///
/// The arc paints a multi-hue [SweepGradient] so earlier and later stages
/// show together as intake grows (azure → iris → orchid → mint). When
/// [over], the tip turns coral warning.
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

  /// Optional solid override — skips the spectrum gradient when set.
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
    final tipColor =
        color ??
        intakeProgressColor(
          over: over,
          fraction: f,
          fallback: scheme.onSurface,
        );
    final centerColor = labelColor ?? tipColor;
    final percent = (f * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          over: over,
          solidColor: color,
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
    required this.over,
    required this.solidColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final bool over;
  final Color? solidColor;
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

    // One deliberate dry-ink break keeps the ring from reading as stock UI.
    canvas.drawArc(rect, -math.pi / 2 + .12, 2 * math.pi - .24, false, track);
    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (solidColor != null) {
      arc.color = solidColor!;
    } else {
      final colors = over
          ? <Color>[
              ...calorieRingSpectrum.sublist(0, calorieRingSpectrum.length - 1),
              AppColors.warning,
            ]
          : calorieRingSpectrum;
      arc.shader = SweepGradient(
        colors: colors,
        stops: calorieRingStops,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    }

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.over != over ||
      oldDelegate.solidColor != solidColor ||
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
    this.icon,
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
  final InkGlyph? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = AppThemeVisuals.of(context);
    final safeCurrent = current.isFinite ? current : 0.0;
    final safeTarget = target.isFinite ? target : 0.0;
    final ratio = safeTarget <= 0 ? 0.0 : safeCurrent / safeTarget;
    final over = ratio > 1.0 + 1e-9;
    final barColor = over && capProgress ? AppColors.warning : color;
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
              if (icon != null) ...[
                InkIcon(
                  icon!,
                  size: 16,
                  color: labelColor ?? scheme.onSurfaceVariant,
                  secondaryColor: color,
                  strokeWidth: 1.55,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
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
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
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
          const SizedBox(height: 7),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: valueText,
                  style: TextStyle(
                    color: over
                        ? AppColors.warning
                        : (labelColor ?? scheme.onSurface),
                  ),
                ),
                TextSpan(
                  text: ' /$targetText $unit',
                  style: TextStyle(color: metaColor ?? scheme.onSurfaceVariant),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
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
                          builder: (context, level, _) =>
                              TweenAnimationBuilder<double>(
                                key: ValueKey(clamped),
                                tween: Tween(begin: 0, end: 1),
                                duration: disableAnimations
                                    ? Duration.zero
                                    : const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                builder: (context, pulse, _) => CustomPaint(
                                  painter: _WaterCupBodyPainter(
                                    level: level,
                                    bloom: math.sin(math.pi * pulse),
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
    required this.bloom,
    required this.stroke,
    required this.glass,
    required this.water,
    required this.waterDeep,
  });

  final double level;
  final double bloom;
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
      ..cubicTo(botL, bottom - 1, w * .36, bottom, w * .5, bottom)
      ..cubicTo(
        w * .64,
        bottom,
        botR,
        bottom - 1,
        rightAt(bottom - r),
        bottom - r,
      )
      ..lineTo(topR, top);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = _bodyPath(size);
    final closed = Path.from(outline)..close();

    if (bloom > 0 && level > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * .5, h * .57),
          width: w * (1 + bloom * .34),
          height: h * (.72 + bloom * .15),
        ),
        Paint()..color = waterDeep.withValues(alpha: bloom * .08),
      );
    }

    // Empty state is outline-only; tint arrives with the first water serving.
    if (level > 0) {
      canvas.drawPath(closed, Paint()..color = glass.withValues(alpha: .42));
    }

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
      // Flat translucent fill plus one calm ink-water surface line.
      canvas.drawPath(
        wave(0, surfaceY),
        Paint()..color = water.withValues(alpha: .22),
      );
      final surface = Path()..moveTo(-2, surfaceY);
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final x = -2 + (w + 4) * i / steps;
        final y = surfaceY + math.sin(i / steps * math.pi * 2) * amp;
        surface.lineTo(x, y);
      }
      canvas.drawPath(
        surface,
        Paint()
          ..color = waterDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    canvas.drawPath(
      outline,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Signature droplet at the upper-right edge.
    final drop = Path()
      ..moveTo(w * .88, h * .04)
      ..cubicTo(w * .81, h * .13, w * .83, h * .20, w * .88, h * .20)
      ..cubicTo(w * .94, h * .20, w * .95, h * .13, w * .88, h * .04);
    canvas.drawPath(
      drop,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterCupBodyPainter old) =>
      old.level != level ||
      old.bloom != bloom ||
      old.stroke != stroke ||
      old.glass != glass ||
      old.water != water ||
      old.waterDeep != waterDeep;
}

/// Open brush rim, drawn separately so it remains an independent undo target.
class _WaterCupLidPainter extends CustomPainter {
  _WaterCupLidPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // The missing segment is the icon family's deliberate ink break.
    final rect = Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6);
    canvas.drawOval(rect, Paint()..color = fill.withValues(alpha: .28));
    canvas.drawArc(
      rect,
      .18,
      math.pi * 1.78,
      false,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterCupLidPainter old) =>
      old.stroke != stroke || old.fill != fill;
}
