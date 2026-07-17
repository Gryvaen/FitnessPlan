import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';

/// A lightweight startup page that runs [onInitialize] alongside its entrance
/// animation. [onFinished] is called only after both have completed.
class DisciplineFreedomLoadingPage extends StatefulWidget {
  const DisciplineFreedomLoadingPage({
    super.key,
    this.onInitialize,
    required this.onFinished,
    this.onError,
    this.onEnterAnyway,
    this.titleLeft,
    this.titleRight,
    this.subtitle,
    this.statusText,
  });

  final Future<void> Function()? onInitialize;
  final VoidCallback onFinished;
  final ValueChanged<Object>? onError;
  final VoidCallback? onEnterAnyway;
  final String? titleLeft;
  final String? titleRight;
  final String? subtitle;
  final String? statusText;

  @override
  State<DisciplineFreedomLoadingPage> createState() =>
      _DisciplineFreedomLoadingPageState();
}

class _DisciplineFreedomLoadingPageState
    extends State<DisciplineFreedomLoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final AnimationController _runnerController;
  late final AnimationController _exit;
  Object? _error;
  bool _finishing = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
    _runnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    final attempt = ++_attempt;
    if (mounted) setState(() => _error = null);
    try {
      final task = widget.onInitialize?.call() ?? Future<void>.value();
      await Future.wait<void>([task, _entrance.forward().then((_) {})]);
      if (!mounted || attempt != _attempt) return;
      await _finish();
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      widget.onError?.call(error);
      setState(() => _error = error);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _exit.forward();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _runnerController.dispose();
    _exit.dispose();
    super.dispose();
  }

  Animation<double> _interval(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colors = _LoadingColors.from(theme.colorScheme);

    return Scaffold(
      backgroundColor: colors.background,
      body: FadeTransition(
        opacity: ReverseAnimation(
          CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 620;
              final contentWidth = math.min(constraints.maxWidth - 40, 440.0);
              return FadeTransition(
                opacity: _interval(0, .12, Curves.easeIn),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AnimatedRunner(
                              progress: _interval(.05, .34),
                              gait: _runnerController,
                              color: colors.accent,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 12 : 20),
                            _AnimatedMainTitle(
                              left: widget.titleLeft ?? l10n.loadingTitleLeft,
                              right:
                                  widget.titleRight ?? l10n.loadingTitleRight,
                              movement: _interval(.14, .47, Curves.easeOutBack),
                              dot: _interval(.39, .50, Curves.easeOutBack),
                              primaryColor: colors.primaryText,
                              accentColor: colors.accent,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            _AnimatedSubtitle(
                              text: widget.subtitle ?? l10n.loadingSubtitle,
                              animation: _interval(.53, .76),
                              color: colors.secondaryText,
                            ),
                            SizedBox(height: compact ? 20 : 30),
                            RepaintBoundary(
                              child: SizedBox(
                                width: math.min(contentWidth * .65, 250),
                                height: compact ? 48 : 58,
                                child: AnimatedBuilder(
                                  animation: _entrance,
                                  builder: (context, _) => CustomPaint(
                                    painter: _ProgressLinePainter(
                                      progress: _interval(.70, .94).value,
                                      lineColor: colors.decoration,
                                      accentColor: colors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: compact ? 16 : 30,
                      child: _BottomStatus(
                        visible: _interval(.83, .94),
                        pulse: _ambient,
                        color: colors.accent,
                        textColor: colors.secondaryText,
                        statusText:
                            widget.statusText ?? l10n.loadingPreparingPlan,
                        error: _error,
                        onRetry: _initialize,
                        onEnterAnyway: widget.onEnterAnyway == null
                            ? null
                            : () async {
                                widget.onEnterAnyway!();
                              },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingColors {
  const _LoadingColors({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.decoration,
  });

  factory _LoadingColors.from(ColorScheme scheme) => _LoadingColors(
    background: scheme.surface,
    primaryText: scheme.onSurface,
    secondaryText: scheme.onSurfaceVariant,
    accent: scheme.primary,
    decoration: scheme.outlineVariant,
  );

  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color decoration;
}

class _AnimatedMainTitle extends StatelessWidget {
  const _AnimatedMainTitle({
    required this.left,
    required this.right,
    required this.movement,
    required this.dot,
    required this.primaryColor,
    required this.accentColor,
    required this.compact,
  });

  final String left;
  final String right;
  final Animation<double> movement;
  final Animation<double> dot;
  final Color primaryColor;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: compact ? 29 : 34,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      height: 1.15,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([movement, dot]),
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(
              -MediaQuery.sizeOf(context).width * .55 * (1 - movement.value),
              0,
            ),
            child: Text(left, style: style?.copyWith(color: primaryColor)),
          ),
          SizedBox(
            width: compact ? 28 : 34,
            child: Opacity(
              opacity: dot.value.clamp(0, 1),
              child: Transform.scale(
                scale: dot.value,
                child: Text(
                  '·',
                  textAlign: TextAlign.center,
                  style: style?.copyWith(color: accentColor),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(
              MediaQuery.sizeOf(context).width * .55 * (1 - movement.value),
              0,
            ),
            child: Text(right, style: style?.copyWith(color: accentColor)),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSubtitle extends StatelessWidget {
  const _AnimatedSubtitle({
    required this.text,
    required this.animation,
    required this.color,
  });

  final String text;
  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-.35, 0),
        end: Offset.zero,
      ).animate(animation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: color, letterSpacing: 1.2),
        ),
      ),
    ),
  );
}

class _AnimatedRunner extends StatelessWidget {
  const _AnimatedRunner({
    required this.progress,
    required this.gait,
    required this.color,
    required this.compact,
  });

  final Animation<double> progress;
  final Animation<double> gait;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      width: compact ? 70 : 82,
      height: compact ? 60 : 70,
      child: AnimatedBuilder(
        animation: Listenable.merge([progress, gait]),
        builder: (context, _) => CustomPaint(
          painter: _MinimalRunnerPainter(
            progress: progress.value,
            phase: gait.value,
            color: color,
          ),
        ),
      ),
    ),
  );
}

class _MinimalRunnerPainter extends CustomPainter {
  const _MinimalRunnerPainter({
    required this.progress,
    required this.phase,
    required this.color,
  });

  final double progress;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = _wrapCycle(phase);
    final rightCycle = cycle;
    final leftCycle = _wrapCycle(cycle + .5);
    final flight = _flightAmount(cycle);
    final bodyOffset = -math.min(.8, size.height * .012) * flight;

    Offset bodyPoint(double x, double y) =>
        Offset(size.width * x, size.height * y + bodyOffset);

    Paint stroke(Color strokeColor, double width) => Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mainPaint = stroke(color, 2.2);
    final shoulder = bodyPoint(.565, .335);
    final hip = bodyPoint(.53, .545);
    final neckTop = bodyPoint(.598, .24);
    final headCenter = bodyPoint(.632, .18);
    final headRadius = size.shortestSide * .062;

    Offset scaled(Offset point) => bodyPoint(point.dx, point.dy);

    final rightLeg = _sampleLegPose(rightCycle);
    final leftLeg = _sampleLegPose(leftCycle);
    final rightArm = _sampleArmPose(leftCycle);
    final leftArm = _sampleArmPose(rightCycle);

    final rightDepth = (math.cos(cycle * math.pi * 2) + 1) / 2;
    final leftDepth = 1 - rightDepth;
    final rightPaint = stroke(
      color.withValues(alpha: .42 + rightDepth * .58),
      1.8 + rightDepth * .4,
    );
    final leftPaint = stroke(
      color.withValues(alpha: .42 + leftDepth * .58),
      1.8 + leftDepth * .4,
    );
    final bendUnit = size.shortestSide;

    final rightLegPath = _legPath(
      hip,
      scaled(rightLeg.knee),
      scaled(rightLeg.ankle),
      scaled(rightLeg.toe),
      bendUnit,
    );
    final leftLegPath = _legPath(
      hip,
      scaled(leftLeg.knee),
      scaled(leftLeg.ankle),
      scaled(leftLeg.toe),
      bendUnit,
    );
    final rightArmPath = _armPath(
      shoulder,
      scaled(rightArm.elbow),
      scaled(rightArm.hand),
      bendUnit,
    );
    final leftArmPath = _armPath(
      Offset(shoulder.dx - size.width * .008, shoulder.dy),
      scaled(leftArm.elbow),
      scaled(leftArm.hand),
      bendUnit,
    );

    final rightIsNearer = rightDepth >= leftDepth;
    _drawPartialPath(
      canvas,
      rightIsNearer ? leftLegPath : rightLegPath,
      rightIsNearer ? leftPaint : rightPaint,
      progress,
    );
    _drawPartialPath(
      canvas,
      rightIsNearer ? leftArmPath : rightArmPath,
      rightIsNearer ? leftPaint : rightPaint,
      progress,
    );

    final torsoPath = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..cubicTo(
        size.width * .59,
        size.height * .40 + bodyOffset,
        size.width * .54,
        size.height * .475 + bodyOffset,
        hip.dx,
        hip.dy,
      );
    _drawPartialPath(canvas, torsoPath, mainPaint, progress);

    _drawPartialPath(
      canvas,
      rightIsNearer ? rightLegPath : leftLegPath,
      rightIsNearer ? rightPaint : leftPaint,
      progress,
    );
    _drawPartialPath(
      canvas,
      rightIsNearer ? rightArmPath : leftArmPath,
      rightIsNearer ? rightPaint : leftPaint,
      progress,
    );

    final neckPath = Path()
      ..moveTo(neckTop.dx, neckTop.dy)
      ..lineTo(shoulder.dx, shoulder.dy);
    _drawPartialPath(canvas, neckPath, mainPaint, progress);

    final headPath = Path()
      ..addOval(Rect.fromCircle(center: headCenter, radius: headRadius));
    _drawPartialPath(canvas, headPath, mainPaint, progress);
  }

  @override
  bool shouldRepaint(_MinimalRunnerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color;
}

double _wrapCycle(double value) {
  final wrapped = value % 1;
  return wrapped < 0 ? wrapped + 1 : wrapped;
}

double _smoothStep(double value) => value * value * (3 - 2 * value);

double _flightAmount(double cycle) =>
    math.max(_pulse(cycle, .34, .44), _pulse(cycle, .84, .94));

double _pulse(double value, double begin, double end) {
  if (value <= begin || value >= end) return 0;
  final midpoint = (begin + end) / 2;
  final raw = value <= midpoint
      ? (value - begin) / (midpoint - begin)
      : (end - value) / (end - midpoint);
  return _smoothStep(raw.clamp(0.0, 1.0));
}

Offset _curvedControl(Offset start, Offset end, double position, double bend) {
  final base = Offset.lerp(start, end, position)!;
  final delta = end - start;
  final length = delta.distance;
  if (length == 0) return base;
  final normal = Offset(-delta.dy / length, delta.dx / length);
  return base + normal * bend;
}

Path _legPath(
  Offset root,
  Offset knee,
  Offset ankle,
  Offset toe,
  double bendUnit,
) {
  final poseBias = ((knee.dx - root.dx) / (bendUnit * .18)).clamp(-1.0, 1.0);
  final thighControl = _curvedControl(
    root,
    knee,
    .52,
    -poseBias * bendUnit * .009,
  );
  final shinControl = _curvedControl(
    knee,
    ankle,
    .42,
    poseBias * bendUnit * .012,
  );
  final path = Path()
    ..moveTo(root.dx, root.dy)
    ..quadraticBezierTo(thighControl.dx, thighControl.dy, knee.dx, knee.dy)
    ..quadraticBezierTo(shinControl.dx, shinControl.dy, ankle.dx, ankle.dy)
    ..quadraticBezierTo(
      (ankle.dx + toe.dx) / 2,
      (ankle.dy + toe.dy) / 2,
      toe.dx,
      toe.dy,
    );
  return path;
}

Path _armPath(Offset root, Offset elbow, Offset hand, double bendUnit) {
  final poseBias = ((elbow.dx - root.dx) / (bendUnit * .16)).clamp(-1.0, 1.0);
  final upperControl = _curvedControl(
    root,
    elbow,
    .58,
    -poseBias * bendUnit * .012,
  );
  final forearmControl = _curvedControl(
    elbow,
    hand,
    .45,
    poseBias * bendUnit * .014,
  );
  return Path()
    ..moveTo(root.dx, root.dy)
    ..quadraticBezierTo(upperControl.dx, upperControl.dy, elbow.dx, elbow.dy)
    ..quadraticBezierTo(forearmControl.dx, forearmControl.dy, hand.dx, hand.dy);
}

class _RunnerLegPose {
  const _RunnerLegPose({
    required this.knee,
    required this.ankle,
    required this.toe,
  });

  final Offset knee;
  final Offset ankle;
  final Offset toe;
}

class _RunnerArmPose {
  const _RunnerArmPose({required this.elbow, required this.hand});

  final Offset elbow;
  final Offset hand;
}

const _poseTimes = <double>[0, .25, .45, .72, 1];
const _legPoses = <_RunnerLegPose>[
  _RunnerLegPose(
    knee: Offset(.61, .61),
    ankle: Offset(.55, .715),
    toe: Offset(.59, .701),
  ),
  _RunnerLegPose(
    knee: Offset(.56, .65),
    ankle: Offset(.62, .79),
    toe: Offset(.665, .787),
  ),
  _RunnerLegPose(
    knee: Offset(.45, .68),
    ankle: Offset(.47, .81),
    toe: Offset(.515, .81),
  ),
  _RunnerLegPose(
    knee: Offset(.33, .68),
    ankle: Offset(.27, .77),
    toe: Offset(.24, .765),
  ),
  _RunnerLegPose(
    knee: Offset(.61, .61),
    ankle: Offset(.55, .715),
    toe: Offset(.59, .701),
  ),
];
const _armPoses = <_RunnerArmPose>[
  _RunnerArmPose(elbow: Offset(.605, .39), hand: Offset(.565, .34)),
  _RunnerArmPose(elbow: Offset(.57, .405), hand: Offset(.545, .37)),
  _RunnerArmPose(elbow: Offset(.49, .42), hand: Offset(.48, .44)),
  _RunnerArmPose(elbow: Offset(.40, .42), hand: Offset(.45, .48)),
  _RunnerArmPose(elbow: Offset(.605, .39), hand: Offset(.565, .34)),
];

_RunnerLegPose _sampleLegPose(double cycle) {
  final index = _poseInterval(cycle);
  final amount = _intervalAmount(cycle, index);
  final a = _legPoses[index];
  final b = _legPoses[index + 1];
  return _RunnerLegPose(
    knee: Offset.lerp(a.knee, b.knee, amount)!,
    ankle: Offset.lerp(a.ankle, b.ankle, amount)!,
    toe: Offset.lerp(a.toe, b.toe, amount)!,
  );
}

_RunnerArmPose _sampleArmPose(double cycle) {
  final index = _poseInterval(cycle);
  final amount = _intervalAmount(cycle, index);
  final a = _armPoses[index];
  final b = _armPoses[index + 1];
  return _RunnerArmPose(
    elbow: Offset.lerp(a.elbow, b.elbow, amount)!,
    hand: Offset.lerp(a.hand, b.hand, amount)!,
  );
}

int _poseInterval(double cycle) {
  for (var i = 0; i < _poseTimes.length - 1; i++) {
    if (cycle < _poseTimes[i + 1]) return i;
  }
  return _poseTimes.length - 2;
}

double _intervalAmount(double cycle, int index) {
  final raw =
      (cycle - _poseTimes[index]) / (_poseTimes[index + 1] - _poseTimes[index]);
  return _smoothStep(raw.clamp(0.0, 1.0));
}

class _ProgressLinePainter extends CustomPainter {
  const _ProgressLinePainter({
    required this.progress,
    required this.lineColor,
    required this.accentColor,
  });

  final double progress;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, size.height * .8)
      ..cubicTo(
        size.width * .2,
        size.height * .78,
        size.width * .22,
        size.height * .57,
        size.width * .39,
        size.height * .62,
      )
      ..cubicTo(
        size.width * .55,
        size.height * .68,
        size.width * .61,
        size.height * .30,
        size.width * .76,
        size.height * .38,
      )
      ..quadraticBezierTo(
        size.width * .89,
        size.height * .43,
        size.width - 3,
        size.height * .12,
      );
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    _drawPartialPath(canvas, path, paint, progress);
    if (progress >= .98) {
      canvas.drawCircle(
        Offset(size.width - 3, size.height * .12),
        4,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.accentColor != accentColor;
}

void _drawPartialPath(Canvas canvas, Path path, Paint paint, double progress) {
  for (final metric in path.computeMetrics()) {
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0, 1)),
      paint,
    );
  }
}

class _BottomStatus extends StatelessWidget {
  const _BottomStatus({
    required this.visible,
    required this.pulse,
    required this.color,
    required this.textColor,
    required this.statusText,
    required this.error,
    required this.onRetry,
    required this.onEnterAnyway,
  });

  final Animation<double> visible;
  final Animation<double> pulse;
  final Color color;
  final Color textColor;
  final String statusText;
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback? onEnterAnyway;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: visible,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: error == null
          ? Column(
              key: const ValueKey('loading'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: .75),
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 10),
                _LoadingTrack(animation: pulse, color: color),
              ],
            )
          : Column(
              key: const ValueKey('error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.loadingPreparationFailed,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.retry),
                    ),
                    if (onEnterAnyway != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onEnterAnyway,
                        child: Text(context.l10n.enterAnyway),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    ),
  );
}

class _LoadingTrack extends StatelessWidget {
  const _LoadingTrack({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 5,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          const highlightWidth = 13.0;
          final position = Curves.easeInOutCubic.transform(animation.value);
          final edgeFade = math.sin(animation.value * math.pi);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Positioned(
                left: (52 - highlightWidth) * position,
                child: Opacity(
                  opacity: edgeFade.clamp(0.0, 1.0),
                  child: Container(
                    width: highlightWidth,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
