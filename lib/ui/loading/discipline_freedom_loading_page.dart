import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/app_theme.dart';

/// A lightweight startup page that runs [onInitialize] alongside its entrance
/// animation. After both complete, it dwells briefly so the runner keeps
/// moving, then calls [onFinished]. Tap anywhere to enter the home page
/// immediately with no exit animation (initialization may continue in the
/// background).
///
/// [onPrewarm] fires shortly after the entrance animation settles so the host
/// can build the real app behind this page, keeping the hand-off cheap.
class DisciplineFreedomLoadingPage extends StatefulWidget {
  const DisciplineFreedomLoadingPage({
    super.key,
    this.onInitialize,
    required this.onFinished,
    this.onPrewarm,
    this.onError,
    this.onEnterAnyway,
    this.titleLeft,
    this.titleRight,
    this.subtitle,
    this.statusText,
  });

  final Future<void> Function()? onInitialize;
  final VoidCallback onFinished;
  final VoidCallback? onPrewarm;
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
  static const _dwell = Duration(milliseconds: 2500);
  static const _prewarmDelay = Duration(milliseconds: 150);

  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final AnimationController _runnerController;
  late final AnimationController _exit;

  late final CurvedAnimation _exitCurve;
  late final Animation<double> _exitOpacity;
  late final CurvedAnimation _inkBloom;
  late final CurvedAnimation _contentFade;
  late final CurvedAnimation _runnerProgress;
  late final CurvedAnimation _subtitleProgress;
  late final CurvedAnimation _progressLine;
  late final CurvedAnimation _statusVisible;

  Object? _error;
  bool _finishing = false;
  bool _prewarmed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _entrance =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2000),
          )
          ..addStatusListener(_onEntranceStatus)
          ..forward();
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

    _exitCurve = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
    _exitOpacity = ReverseAnimation(_exitCurve);
    _inkBloom = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, .55, curve: Curves.easeOutCubic),
    );
    _contentFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.28, .42, curve: Curves.easeIn),
    );
    _runnerProgress = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.30, .52, curve: Curves.easeOutCubic),
    );
    _subtitleProgress = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.58, .78, curve: Curves.easeOutCubic),
    );
    _progressLine = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.70, .95, curve: Curves.easeOutCubic),
    );
    _statusVisible = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.72, .88, curve: Curves.easeIn),
    );

    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    void sync(AnimationController c) {
      if (reduce) {
        c.stop();
        c.value = 0;
      } else if (!c.isAnimating && c.duration != null) {
        c.repeat();
      }
    }

    sync(_ambient);
    sync(_runnerController);
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _prewarmed) return;
    _prewarmed = true;
    // Let the last entrance frame land before building the real app tree.
    Future.delayed(_prewarmDelay, () {
      if (!mounted || _finishing) return;
      widget.onPrewarm?.call();
    });
  }

  Future<void> _initialize() async {
    final attempt = ++_attempt;
    if (mounted) setState(() => _error = null);
    try {
      final task = widget.onInitialize?.call() ?? Future<void>.value();
      await Future.wait<void>([task, _entrance.forward().then((_) {})]);
      if (!mounted || attempt != _attempt) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        await Future.delayed(_dwell);
      }
      if (!mounted || attempt != _attempt || _finishing) return;
      await _finish();
    } catch (error) {
      if (!mounted || attempt != _attempt || _finishing) return;
      widget.onError?.call(error);
      setState(() => _error = error);
    }
  }

  void _stopAmbientMotion() {
    _entrance.stop();
    _ambient.stop();
    _runnerController.stop();
  }

  void _skip() {
    if (_finishing) return;
    _finishing = true;
    _stopAmbientMotion();
    widget.onFinished();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _exit.forward();
    _stopAmbientMotion();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _exitCurve.dispose();
    _inkBloom.dispose();
    _contentFade.dispose();
    _runnerProgress.dispose();
    _subtitleProgress.dispose();
    _progressLine.dispose();
    _statusVisible.dispose();
    _entrance.dispose();
    _ambient.dispose();
    _runnerController.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colors = _LoadingColors.from(theme.colorScheme);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _error == null ? _skip : null,
        child: FadeTransition(
          opacity: _exitOpacity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.background),
              RepaintBoundary(
                child: _InkRainbowBloom(bloom: _inkBloom),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 620;
                    final contentWidth = math.min(
                      constraints.maxWidth - 40,
                      440.0,
                    );
                    final travel = constraints.maxWidth / 2 + 80;
                    return FadeTransition(
                      opacity: _contentFade,
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
                                    progress: _runnerProgress,
                                    gait: _runnerController,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 12 : 20),
                                  _KineticTitle(
                                    left:
                                        widget.titleLeft ??
                                        l10n.loadingTitleLeft,
                                    right:
                                        widget.titleRight ??
                                        l10n.loadingTitleRight,
                                    entrance: _entrance,
                                    reduceMotion: reduceMotion,
                                    compact: compact,
                                    travel: travel,
                                  ),
                                  SizedBox(height: compact ? 12 : 18),
                                  _AnimatedSubtitle(
                                    text:
                                        widget.subtitle ?? l10n.loadingSubtitle,
                                    animation: _subtitleProgress,
                                    entrance: _entrance,
                                    reduceMotion: reduceMotion,
                                  ),
                                  SizedBox(height: compact ? 20 : 30),
                                  RepaintBoundary(
                                    child: SizedBox(
                                      width: math.min(contentWidth * .65, 250),
                                      height: compact ? 48 : 58,
                                      child: AnimatedBuilder(
                                        animation: _progressLine,
                                        builder: (context, _) => CustomPaint(
                                          painter: _ProgressLinePainter(
                                            progress: _progressLine.value,
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
                              visible: _statusVisible,
                              pulse: _ambient,
                              entrance: _entrance,
                              reduceMotion: reduceMotion,
                              color: colors.accent,
                              statusText:
                                  widget.statusText ??
                                  l10n.loadingPreparingPlan,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Bright rainbow for loading text / runner (readable on soft wash).
const _loadingBrightRainbow = <Color>[
  Color(0xFFFF3B5C),
  Color(0xFFFF8A00),
  Color(0xFFFFE135),
  Color(0xFF00C853),
  Color(0xFF00B0FF),
  Color(0xFF7C4DFF),
  Color(0xFFFF2D95),
];

/// Tints opaque ink with a bright rainbow (no blur halo).
class _RainbowTint extends StatelessWidget {
  const _RainbowTint({required this.builder, this.shift = 0});

  final WidgetBuilder builder;
  final double shift;

  static final _flowColors = [
    ..._loadingBrightRainbow,
    _loadingBrightRainbow.first,
  ];

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _flowColors,
        tileMode: TileMode.repeated,
        transform: _SlidingGradientTransform(shift: shift),
      ).createShader(bounds),
      child: builder(context),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.shift});

  final double shift;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(shift * bounds.width, 0, 0);
  }
}

/// Full-screen rainbow bloom fill.
class _InkRainbowBloom extends StatelessWidget {
  const _InkRainbowBloom({required this.bloom});

  final Animation<double> bloom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bloom,
      builder: (context, _) => CustomPaint(
        painter: _InkRainbowBloomPainter(bloomT: bloom.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _InkRainbowBloomPainter extends CustomPainter {
  _InkRainbowBloomPainter({required this.bloomT});

  final double bloomT;

  @override
  void paint(Canvas canvas, Size size) {
    if (bloomT <= 0.001) return;

    final cx = size.width * 0.5;
    final impact = Offset(cx, size.height * 0.42);
    final fullRect = Offset.zero & size;
    final maxR =
        math.sqrt(
          math.pow(math.max(cx, size.width - cx), 2) +
              math.pow(math.max(impact.dy, size.height - impact.dy), 2),
        ) *
        1.2;
    final bloomR = maxR * bloomT;

    final washPaint = Paint()
      ..shader = AppTheme.oilRainbowWash.createShader(fullRect);
    canvas.drawCircle(impact, bloomR, washPaint);
  }

  @override
  bool shouldRepaint(covariant _InkRainbowBloomPainter oldDelegate) {
    if (oldDelegate.bloomT >= 1.0 && bloomT >= 1.0) return false;
    return oldDelegate.bloomT != bloomT;
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
    decoration: Colors.white.withValues(alpha: 0.92),
  );

  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color decoration;
}

class _KineticTitle extends StatelessWidget {
  const _KineticTitle({
    required this.left,
    required this.right,
    required this.entrance,
    required this.reduceMotion,
    required this.compact,
    required this.travel,
  });

  final String left;
  final String right;
  final AnimationController entrance;
  final bool reduceMotion;
  final bool compact;
  final double travel;

  static const _titleBegin = 0.30;
  static const _titleEnd = 0.62;
  static const _charSpan = 0.18;
  static const _stagger = 0.03;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontFamily: AppTheme.displayFontFamily,
      fontSize: compact ? 32 : 38,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.15,
      color: Colors.white,
    );
    final leftChars = left.characters.toList();
    final rightChars = right.characters.toList();
    final gap = compact ? 18.0 : 26.0;

    return AnimatedBuilder(
      animation: entrance,
      builder: (context, _) {
        final spacing = Tween<double>(begin: 12, end: 3).transform(
          _intervalValue(
            entrance.value,
            _titleBegin,
            _titleEnd,
            Curves.easeOutCubic,
          ),
        );
        // Rainbow flows only during entrance, then settles.
        final shift = reduceMotion
            ? 0.0
            : Curves.easeOut.transform(
                (entrance.value / _titleEnd).clamp(0.0, 1.0),
              );

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: _RainbowTint(
            shift: shift * 0.35,
            builder: (context) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._buildGroup(
                  chars: leftChars,
                  style: style,
                  fromLeft: true,
                  spacing: spacing,
                ),
                SizedBox(width: gap),
                ..._buildGroup(
                  chars: rightChars,
                  style: style,
                  fromLeft: false,
                  spacing: spacing,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGroup({
    required List<String> chars,
    required TextStyle? style,
    required bool fromLeft,
    required double spacing,
  }) {
    final widgets = <Widget>[];
    for (var i = 0; i < chars.length; i++) {
      // Stagger from outer edge inward so both sides meet near the center.
      final staggerIndex = fromLeft ? i : (chars.length - 1 - i);
      final begin = (_titleBegin + staggerIndex * _stagger).clamp(0.0, 1.0);
      final end = (begin + _charSpan).clamp(0.0, 1.0);
      final t = _intervalValue(entrance.value, begin, end, Curves.easeOutCubic);
      final dx = fromLeft ? -(1 - t) * travel : (1 - t) * travel;
      if (i > 0) widgets.add(SizedBox(width: spacing));
      final alpha = t.clamp(0.0, 1.0);
      widgets.add(
        Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: Text(
              chars[i],
              style: style?.copyWith(
                color: Colors.white.withValues(alpha: alpha),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _AnimatedSubtitle extends StatelessWidget {
  const _AnimatedSubtitle({
    required this.text,
    required this.animation,
    required this.entrance,
    required this.reduceMotion,
  });

  final String text;
  final Animation<double> animation;
  final AnimationController entrance;
  final bool reduceMotion;

  List<String> _tokens(String value) {
    final hasCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(value);
    if (hasCjk) return value.characters.toList();
    return value.split(RegExp(r'(\s+)')).where((t) => t.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: AppTheme.displayFontFamily,
      color: Colors.white,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w500,
    );
    final tokens = _tokens(text);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final shift = reduceMotion
            ? 0.0
            : Curves.easeOut.transform(entrance.value.clamp(0.0, 1.0)) * 0.25;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _RainbowTint(
            shift: shift,
            builder: (context) => Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < tokens.length; i++)
                  _staggerToken(
                    token: tokens[i],
                    index: i,
                    total: tokens.length,
                    style: baseStyle,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _staggerToken({
    required String token,
    required int index,
    required int total,
    required TextStyle? style,
  }) {
    final span = total <= 1 ? 1.0 : 1.0 / (total + 1);
    final begin = (index * span * 0.85).clamp(0.0, 1.0);
    final end = (begin + 0.45).clamp(0.0, 1.0);
    final t = _intervalValue(animation.value, begin, end, Curves.easeOutCubic);
    final alpha = t.clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, (1 - t) * 10),
      child: Text(
        token,
        style: style?.copyWith(color: Colors.white.withValues(alpha: alpha)),
      ),
    );
  }
}

double _intervalValue(
  double parent,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) {
  if (end <= begin) return parent >= end ? 1.0 : 0.0;
  final raw = ((parent - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(raw);
}

class _AnimatedRunner extends StatelessWidget {
  const _AnimatedRunner({
    required this.progress,
    required this.gait,
    required this.compact,
  });

  final Animation<double> progress;
  final Animation<double> gait;
  final bool compact;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      width: compact ? 70 : 82,
      height: compact ? 60 : 70,
      child: AnimatedBuilder(
        animation: Listenable.merge([progress, gait]),
        builder: (context, _) => _RainbowTint(
          builder: (context) => CustomPaint(
            painter: _MinimalRunnerPainter(
              progress: progress.value,
              phase: gait.value,
              color: Colors.white,
            ),
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
    this.lineWidth = 2.2,
  });

  final double progress;
  final double phase;
  final Color color;
  final double lineWidth;

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

    final limbWidth = lineWidth * 0.82;
    final mainPaint = stroke(color, lineWidth);
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
      limbWidth + rightDepth * lineWidth * 0.18,
    );
    final leftPaint = stroke(
      color.withValues(alpha: .42 + leftDepth * .58),
      limbWidth + leftDepth * lineWidth * 0.18,
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
      oldDelegate.color != color ||
      oldDelegate.lineWidth != lineWidth;
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
  final t = progress.clamp(0.0, 1.0);
  if (t <= 0) return;
  if (t >= 1) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final metric in path.computeMetrics()) {
    canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
  }
}

class _BottomStatus extends StatelessWidget {
  const _BottomStatus({
    required this.visible,
    required this.pulse,
    required this.entrance,
    required this.reduceMotion,
    required this.color,
    required this.statusText,
    required this.error,
    required this.onRetry,
    required this.onEnterAnyway,
  });

  final Animation<double> visible;
  final Animation<double> pulse;
  final AnimationController entrance;
  final bool reduceMotion;
  final Color color;
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
                AnimatedBuilder(
                  animation: entrance,
                  builder: (context, _) {
                    final shift = reduceMotion
                        ? 0.0
                        : Curves.easeOut.transform(
                                entrance.value.clamp(0.0, 1.0),
                              ) *
                              0.2;
                    return _RainbowTint(
                      shift: shift,
                      builder: (context) => Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.displayFontFamily,
                          color: Colors.white,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                RepaintBoundary(
                  child: _LoadingTrack(animation: pulse, color: color),
                ),
              ],
            )
          : Column(
              key: const ValueKey('error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                _RainbowTint(
                  builder: (context) => Text(
                    context.l10n.loadingPreparationFailed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: AppTheme.displayFontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
