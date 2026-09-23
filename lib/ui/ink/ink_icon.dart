import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Product-owned "ink bone" glyphs.
///
/// Every glyph is drawn on the same 24x24 grid, uses a restrained broken
/// stroke, and can be tinted/animated without maintaining bitmap assets.
enum InkGlyph {
  calendar,
  chevronLeft,
  chevronRight,
  walk,
  protein,
  carbs,
  fat,
  water,
  addRing,
  training,
  food,
  mealEmpty,
  more,
  arrowForward,
  delete,
  check,
  info,
  disconnect,
  sync,
  settings,
  battery,
  copy,
  play,
  expand,
  collapse,
  loading,
  profile,
}

class InkIcon extends StatelessWidget {
  const InkIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 1.7,
  });

  final InkGlyph glyph;
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _InkIconPainter(
          glyph: glyph,
          color: resolved,
          secondaryColor: secondaryColor ?? resolved,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class InkIconButton extends StatelessWidget {
  const InkIconButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconSize = 24,
  });

  final InkGlyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: InkIcon(
        glyph,
        size: iconSize,
        color: onPressed == null ? resolved.withValues(alpha: .35) : resolved,
      ),
    );
  }
}

class InkStrokeUnderline extends StatelessWidget {
  const InkStrokeUnderline({
    super.key,
    required this.selected,
    required this.color,
    this.width = 24,
  });

  final bool selected;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox(
        width: width,
        height: 7,
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                'assets/ink/brush-sweep-v1.png',
                width: width,
                height: 7,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InkSeal extends StatelessWidget {
  const InkSeal(this.character, {super.key, this.size = 20});

  final String character;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFA8493F),
      borderRadius: BorderRadius.circular(size * .16),
    ),
    child: Text(
      character,
      style: TextStyle(
        color: const Color(0xFFF4F1E9),
        fontFamily: 'LXGWWenKai',
        fontWeight: FontWeight.w500,
        fontSize: size * .62,
        height: 1,
      ),
    ),
  );
}

class _InkIconPainter extends CustomPainter {
  const _InkIconPainter({
    required this.glyph,
    required this.color,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  final InkGlyph glyph;
  final Color color;
  final Color secondaryColor;
  final double strokeWidth;

  Paint _stroke(Color value, {double width = 1}) => Paint()
    ..color = value
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth * width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final p = _stroke(color);
    switch (glyph) {
      case InkGlyph.calendar:
        _calendar(canvas, p);
      case InkGlyph.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(14.4, 18.4),
          p,
        );
        canvas.drawCircle(
          const Offset(14.8, 18.8),
          .45,
          Paint()..color = color.withValues(alpha: .45),
        );
      case InkGlyph.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9.6, 18.4),
          p,
        );
        canvas.drawCircle(
          const Offset(9.2, 18.8),
          .45,
          Paint()..color = color.withValues(alpha: .45),
        );
      case InkGlyph.walk:
        _walk(canvas, p);
      case InkGlyph.protein:
        _protein(canvas, p);
      case InkGlyph.carbs:
        _carbs(canvas, p);
      case InkGlyph.fat:
        _fat(canvas, p);
      case InkGlyph.water:
        _water(canvas, p);
      case InkGlyph.addRing:
        _addRing(canvas, p);
      case InkGlyph.training:
        _training(canvas, p);
      case InkGlyph.food:
        _food(canvas, p);
      case InkGlyph.mealEmpty:
        _mealEmpty(canvas, p);
      case InkGlyph.more:
        _more(canvas);
      case InkGlyph.arrowForward:
        _arrowForward(canvas, p);
      case InkGlyph.delete:
        _delete(canvas, p);
      case InkGlyph.check:
        _check(canvas, p);
      case InkGlyph.info:
        _info(canvas, p);
      case InkGlyph.disconnect:
        _disconnect(canvas, p);
      case InkGlyph.sync:
        _sync(canvas, p);
      case InkGlyph.settings:
        _settings(canvas, p);
      case InkGlyph.battery:
        _battery(canvas, p);
      case InkGlyph.copy:
        _copy(canvas, p);
      case InkGlyph.play:
        _play(canvas, p);
      case InkGlyph.expand:
        _fold(canvas, p, expand: true);
      case InkGlyph.collapse:
        _fold(canvas, p, expand: false);
      case InkGlyph.loading:
        _loading(canvas, p);
      case InkGlyph.profile:
        _profile(canvas, p);
    }
    canvas.restore();
  }

  void _calendar(Canvas c, Paint p) {
    // One continuous paper stroke, deliberately open at the upper-left.
    final paper = Path()
      ..moveTo(8.2, 5.5)
      ..lineTo(18.2, 5.5)
      ..quadraticBezierTo(20, 5.5, 20, 7.3)
      ..lineTo(20, 17.5)
      ..lineTo(16.6, 21)
      ..lineTo(7, 21)
      ..quadraticBezierTo(4.5, 21, 4.5, 18.5)
      ..lineTo(4.5, 8.2);
    c.drawPath(paper, p);

    // Binding strokes are heavier at the paper edge and taper upward.
    final binding = _stroke(color, width: 1.18);
    c.drawPath(
      Path()
        ..moveTo(8.4, 7.4)
        ..lineTo(8.4, 2.8),
      binding,
    );
    c.drawPath(
      Path()
        ..moveTo(15.8, 7.4)
        ..lineTo(15.8, 2.8),
      binding,
    );

    // A broken divider leaves a quiet field for an optional weekday mark.
    c.drawLine(const Offset(4.8, 9.2), const Offset(11.2, 9.2), p);
    c.drawLine(const Offset(13.2, 9.2), const Offset(19.7, 9.2), p);

    // Folded lower-right paper corner.
    c.drawPath(
      Path()
        ..moveTo(16.6, 21)
        ..lineTo(16.6, 17.5)
        ..lineTo(20, 17.5),
      _stroke(color, width: .78),
    );
  }

  void _walk(Canvas c, Paint p) {
    c.drawCircle(const Offset(13.5, 4.2), 1.6, Paint()..color = color);
    c.drawPath(
      Path()
        ..moveTo(11.7, 7)
        ..lineTo(9.8, 12.3)
        ..lineTo(7.5, 16.2),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(11.7, 7)
        ..lineTo(15, 9.5)
        ..lineTo(18.5, 10.2),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(10.4, 11)
        ..lineTo(14.1, 13.5)
        ..lineTo(16.2, 19.5),
      p,
    );
    c.drawLine(const Offset(10.4, 11), const Offset(9.2, 18.8), p);
  }

  void _protein(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 14)
        ..cubicTo(6, 7, 12, 4, 18.8, 6.2)
        ..cubicTo(20.2, 12.2, 15.2, 19.2, 8.5, 19)
        ..cubicTo(5.8, 18.9, 4.5, 17, 5, 14),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(8.2, 15.7)
        ..cubicTo(11, 14.8, 14, 11.7, 17.1, 8.2),
      _stroke(color, width: .8),
    );
  }

  void _carbs(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 13.5)
        ..quadraticBezierTo(6.2, 20, 12, 20)
        ..quadraticBezierTo(17.8, 20, 19, 13.5),
      p,
    );
    c.drawLine(const Offset(4.5, 13.5), const Offset(19.5, 13.5), p);
    for (final o in const [
      Offset(9, 10),
      Offset(13, 9),
      Offset(16.2, 11.2),
      Offset(11.2, 6.3),
    ]) {
      c.drawOval(Rect.fromCenter(center: o, width: 2.2, height: 3), p);
    }
  }

  void _fat(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(12, 3.8)
        ..cubicTo(9.5, 8, 6.3, 11.8, 6.3, 15.5)
        ..cubicTo(6.3, 19, 8.8, 21, 12, 21)
        ..cubicTo(15.5, 21, 18, 18.8, 18, 15.4)
        ..cubicTo(18, 12, 14.6, 7.7, 12, 3.8),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(11, 17.5)
        ..quadraticBezierTo(14.4, 17, 15.2, 13.5),
      _stroke(secondaryColor, width: .8),
    );
  }

  void _water(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(6, 8)
        ..lineTo(7.6, 19)
        ..quadraticBezierTo(8, 21, 10, 21)
        ..lineTo(15, 21)
        ..quadraticBezierTo(17, 21, 17.4, 19)
        ..lineTo(19, 8),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(5.2, 7.7)
        ..quadraticBezierTo(12, 5.7, 18.8, 7.7),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(8.1, 14.5)
        ..quadraticBezierTo(12.5, 13, 16.9, 14.5),
      _stroke(secondaryColor),
    );
    c.drawPath(
      Path()
        ..moveTo(20.2, 6)
        ..cubicTo(18.6, 8.1, 18.8, 10, 20.2, 10.2)
        ..cubicTo(21.6, 10, 21.8, 8.1, 20.2, 6),
      _stroke(secondaryColor, width: .8),
    );
  }

  void _addRing(Canvas c, Paint p) {
    c.drawArc(
      const Rect.fromLTWH(3, 3, 18, 18),
      -.25,
      math.pi * 1.73,
      false,
      p,
    );
    c.drawLine(const Offset(12, 7.5), const Offset(12, 16.5), p);
    c.drawLine(const Offset(7.5, 12), const Offset(16.5, 12), p);
  }

  void _training(Canvas c, Paint p) {
    final heavy = _stroke(color, width: 1.35);
    c.drawLine(const Offset(6, 5.5), const Offset(18, 18.5), p);
    c.drawLine(const Offset(18, 5.5), const Offset(6, 18.5), p);
    c.drawRect(const Rect.fromLTWH(10.4, 10.4, 3.2, 3.2), p);
    for (final pair in const [
      [Offset(4.5, 4), Offset(7.2, 6.8)],
      [Offset(19.5, 4), Offset(16.8, 6.8)],
      [Offset(4.5, 20), Offset(7.2, 17.2)],
      [Offset(19.5, 20), Offset(16.8, 17.2)],
    ]) {
      c.drawLine(pair[0], pair[1], heavy);
    }
  }

  void _food(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 12)
        ..quadraticBezierTo(6.5, 19, 12, 19)
        ..quadraticBezierTo(17.5, 19, 19, 12),
      p,
    );
    c.drawLine(const Offset(4.5, 12), const Offset(19.5, 12), p);
    c.drawLine(const Offset(13.8, 4), const Offset(11.7, 11.5), p);
    c.drawLine(const Offset(17.2, 4.8), const Offset(14.6, 11.5), p);
    c.drawPath(
      Path()
        ..moveTo(7.5, 9.5)
        ..quadraticBezierTo(8.5, 7.5, 10, 8.8),
      _stroke(color, width: .8),
    );
  }

  void _mealEmpty(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(4, 12)
        ..quadraticBezierTo(5.8, 20, 12, 20)
        ..quadraticBezierTo(18.2, 20, 20, 12),
      p,
    );
    c.drawLine(const Offset(3.5, 12), const Offset(20.5, 12), p);
    c.drawPath(
      Path()
        ..moveTo(8, 8.7)
        ..quadraticBezierTo(9.4, 6.3, 11, 8.2),
      _stroke(color, width: .8),
    );
    c.drawOval(
      const Rect.fromLTWH(13.5, 6.2, 2.4, 3.5),
      _stroke(color, width: .8),
    );
  }

  void _more(Canvas c) {
    final ink = Paint()..color = color;
    c.drawOval(const Rect.fromLTWH(4, 11, 3.4, 2.4), ink);
    c.drawOval(const Rect.fromLTWH(10.3, 10.7, 3.4, 2.7), ink);
    c.drawOval(const Rect.fromLTWH(16.6, 11, 3.4, 2.4), ink);
  }

  void _arrowForward(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(4, 12)
        ..lineTo(18.5, 12)
        ..moveTo(13, 6.5)
        ..lineTo(18.5, 12)
        ..lineTo(13.4, 17.1),
      p,
    );
  }

  void _delete(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(7, 8)
        ..lineTo(8, 20)
        ..lineTo(16, 20)
        ..lineTo(17, 8),
      p,
    );
    c.drawLine(const Offset(5.5, 7), const Offset(18.5, 7), p);
    c.drawPath(
      Path()
        ..moveTo(9, 5)
        ..lineTo(10, 3.5)
        ..lineTo(14, 3.5)
        ..lineTo(15, 5),
      p,
    );
    c.drawLine(
      const Offset(10.5, 10.5),
      const Offset(10.8, 17),
      _stroke(color, width: .75),
    );
    c.drawLine(
      const Offset(13.5, 10.5),
      const Offset(13.2, 17),
      _stroke(color, width: .75),
    );
  }

  void _check(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(4.5, 12.5)
        ..lineTo(9.5, 17)
        ..lineTo(19.5, 6.5),
      p,
    );
  }

  void _info(Canvas c, Paint p) {
    c.drawArc(const Rect.fromLTWH(3, 3, 18, 18), .18, math.pi * 1.82, false, p);
    c.drawCircle(const Offset(12, 7.3), 1, Paint()..color = color);
    c.drawLine(const Offset(12, 11), const Offset(12, 17), p);
  }

  void _disconnect(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 14)
        ..lineTo(3.5, 15.5)
        ..quadraticBezierTo(1.5, 17.5, 3.5, 19.5)
        ..quadraticBezierTo(5.5, 21.5, 7.5, 19.5)
        ..lineTo(10, 17),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(14, 7)
        ..lineTo(16.5, 4.5)
        ..quadraticBezierTo(18.5, 2.5, 20.5, 4.5)
        ..quadraticBezierTo(22.5, 6.5, 20.5, 8.5)
        ..lineTo(19, 10),
      p,
    );
    c.drawLine(const Offset(4, 4), const Offset(20, 20), p);
  }

  void _sync(Canvas c, Paint p) {
    c.drawArc(const Rect.fromLTWH(4, 4, 16, 16), -2.8, 2.35, false, p);
    c.drawPath(
      Path()
        ..moveTo(17, 3.7)
        ..lineTo(20.2, 4.5)
        ..lineTo(19.2, 7.7),
      p,
    );
    c.drawArc(const Rect.fromLTWH(4, 4, 16, 16), .35, 2.35, false, p);
    c.drawPath(
      Path()
        ..moveTo(7, 20.3)
        ..lineTo(3.8, 19.5)
        ..lineTo(4.8, 16.3),
      p,
    );
  }

  void _settings(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 3.1, p);
    c.drawArc(
      const Rect.fromLTWH(4.5, 4.5, 15, 15),
      .25,
      math.pi * 1.65,
      false,
      p,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(
        Offset(12 + math.cos(a) * 7.5, 12 + math.sin(a) * 7.5),
        Offset(12 + math.cos(a) * 9, 12 + math.sin(a) * 9),
        p,
      );
    }
  }

  void _battery(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(6, 5)
        ..lineTo(18, 5)
        ..lineTo(18, 20)
        ..lineTo(6, 20)
        ..close(),
      p,
    );
    c.drawLine(const Offset(10, 3), const Offset(14, 3), p);
    c.drawPath(
      Path()
        ..moveTo(13, 8)
        ..lineTo(9.5, 13)
        ..lineTo(12.2, 13)
        ..lineTo(11, 17),
      p,
    );
  }

  void _copy(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(8, 7)
        ..lineTo(19, 7)
        ..lineTo(19, 19)
        ..lineTo(8, 19)
        ..close(),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(5, 16)
        ..lineTo(5, 4)
        ..lineTo(16, 4),
      p,
    );
  }

  void _play(Canvas c, Paint p) {
    c.drawArc(const Rect.fromLTWH(3, 3, 18, 18), .2, math.pi * 1.72, false, p);
    c.drawPath(
      Path()
        ..moveTo(10, 8)
        ..lineTo(17, 12)
        ..lineTo(10, 16)
        ..close(),
      p,
    );
  }

  void _fold(Canvas c, Paint p, {required bool expand}) {
    final y1 = expand ? 9.5 : 14.5;
    final y2 = expand ? 14.5 : 9.5;
    c.drawPath(
      Path()
        ..moveTo(6, y1)
        ..lineTo(12, y2)
        ..lineTo(18, y1),
      p,
    );
  }

  void _loading(Canvas c, Paint p) {
    c.drawArc(const Rect.fromLTWH(4, 4, 16, 16), -.7, math.pi * 1.35, false, p);
    c.drawArc(
      const Rect.fromLTWH(7, 7, 10, 10),
      2.5,
      math.pi * .75,
      false,
      _stroke(color.withValues(alpha: .48), width: .8),
    );
  }

  void _profile(Canvas c, Paint p) {
    c.drawArc(const Rect.fromLTWH(8, 3, 8, 8), .3, math.pi * 1.65, false, p);
    c.drawPath(
      Path()
        ..moveTo(5, 21)
        ..cubicTo(5.5, 15.5, 8, 13, 12, 13)
        ..cubicTo(15.8, 13, 18.3, 15.2, 19, 19),
      p,
    );
    c.drawLine(const Offset(19, 19), const Offset(19, 20.5), p);
  }

  @override
  bool shouldRepaint(covariant _InkIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.secondaryColor != secondaryColor ||
      old.strokeWidth != strokeWidth;
}
