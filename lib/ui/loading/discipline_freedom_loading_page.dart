import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';

/// A short, layered ink-painting startup sequence.
///
/// App initialization runs alongside the 1.8 second entrance. The page leaves
/// only after both finish, so fast startup never cuts the sword motion short.
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
    this.labProgress,
  });

  final Future<void> Function()? onInitialize;
  final VoidCallback onFinished;
  final VoidCallback? onPrewarm;
  final ValueChanged<Object>? onError;
  final VoidCallback? onEnterAnyway;

  // Kept for compatibility with the previous loading page. The new visual
  // deliberately contains no title or logo.
  final String? titleLeft;
  final String? titleRight;
  final String? subtitle;
  final String? statusText;

  /// Debug Lab: when set, entrance is scrubbed by this 0–1 value and the page
  /// never auto-finishes or tap-skips.
  final ValueNotifier<double>? labProgress;

  static const entranceDuration = Duration(milliseconds: 1000);

  @override
  State<DisciplineFreedomLoadingPage> createState() =>
      _DisciplineFreedomLoadingPageState();
}

class _DisciplineFreedomLoadingPageState
    extends State<DisciplineFreedomLoadingPage>
    with TickerProviderStateMixin {
  static const _exitDuration = Duration(milliseconds: 200);
  static const _holdDuration = Duration.zero;
  static const _paperAsset = 'assets/splash/paper-ink-v1.webp';
  static const _landscapeAsset = 'assets/splash/landscape-logo-ink-v1.webp';
  static const _swordAsset = 'assets/splash/sword-ink-jian-v1.webp';

  late final AnimationController _entrance;
  late final AnimationController _exit;
  late final Animation<double> _swordEntrance;
  late final Animation<double> _tipMorph;
  late final Animation<double> _expansion;
  late final Animation<double> _paperScale;
  late final Animation<double> _exitOpacity;

  Timer? _prewarmTimer;
  Object? _error;
  int _attempt = 0;
  bool _finishing = false;
  bool _prewarmed = false;

  bool get _lab => widget.labProgress != null;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: DisciplineFreedomLoadingPage.entranceDuration,
      value: widget.labProgress?.value ?? 0,
    );
    _exit = AnimationController(vsync: this, duration: _exitDuration);

    _swordEntrance = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.06, .76),
    );
    // The sword's center crosses the viewport center at about .43 of the
    // master timeline; only then does its pointed trail start rounding out.
    _tipMorph = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(.43, .76, curve: Curves.easeInOutCubic),
    );
    _expansion = CurvedAnimation(
      parent: _entrance,
      // Start with velocity the instant the cap touches the top; an ease-in
      // here reads as a pause between the vertical and horizontal motion.
      curve: const Interval(.76, .96, curve: Curves.easeOutCubic),
    );
    // Sword progress .25 and .50 map to master-timeline values .235 and .41.
    // Hold before that, reach 1.1x at halfway, then push through to 1.4x when
    // the landscape finishes opening at .96.
    _paperScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 23.5),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 17.5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 55,
      ),
      TweenSequenceItem(tween: ConstantTween(1.4), weight: 4),
    ]).animate(_entrance);
    _exitOpacity = ReverseAnimation(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );

    if (_lab) {
      widget.labProgress!.addListener(_onLabProgress);
      _entrance.value = widget.labProgress!.value.clamp(0.0, 1.0);
    } else {
      _entrance.forward();
      _schedulePrewarm();
      _initialize();
    }
  }

  void _onLabProgress() {
    if (!mounted) return;
    _entrance.value = widget.labProgress!.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant DisciplineFreedomLoadingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labProgress != widget.labProgress) {
      oldWidget.labProgress?.removeListener(_onLabProgress);
      widget.labProgress?.addListener(_onLabProgress);
      if (widget.labProgress != null) {
        _entrance.value = widget.labProgress!.value.clamp(0.0, 1.0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_paperAsset), context);
    precacheImage(const AssetImage(_landscapeAsset), context);
    precacheImage(const AssetImage(_swordAsset), context);

    if (!_lab &&
        MediaQuery.disableAnimationsOf(context) &&
        _entrance.value < 1) {
      _entrance.value = 1;
    }
  }

  void _schedulePrewarm() {
    _prewarmTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _finishing || _prewarmed) return;
      _prewarmed = true;
      widget.onPrewarm?.call();
    });
  }

  Future<void> _initialize() async {
    final attempt = ++_attempt;
    if (mounted) setState(() => _error = null);

    try {
      final initialization =
          widget.onInitialize?.call() ?? Future<void>.value();
      await Future.wait<void>([
        initialization,
        _entrance.forward().then<void>((_) {}),
      ]);
      if (!mounted || attempt != _attempt || _finishing) return;
      await Future<void>.delayed(_holdDuration);
      if (!mounted || attempt != _attempt || _finishing) return;
      await _finish();
    } catch (error) {
      if (!mounted || attempt != _attempt || _finishing) return;
      widget.onError?.call(error);
      setState(() => _error = error);
    }
  }

  void _skip() {
    if (_lab || _finishing || _error != null) return;
    _finishing = true;
    _prewarmTimer?.cancel();
    _entrance.stop();
    widget.onFinished();
  }

  Future<void> _finish() async {
    if (_lab || _finishing) return;
    _finishing = true;
    _prewarmTimer?.cancel();
    await _exit.forward();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    widget.labProgress?.removeListener(_onLabProgress);
    _prewarmTimer?.cancel();
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = !_lab && MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xffeeeae1),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (!_lab && _error == null) ? _skip : null,
        child: FadeTransition(
          opacity: _exitOpacity,
          child: AnimatedBuilder(
            animation: _entrance,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                _PaperLayer(scale: reduceMotion ? 1.4 : _paperScale.value),
                _LandscapeLayer(
                  swordProgress: reduceMotion ? 1 : _swordEntrance.value,
                  tipMorph: reduceMotion ? 1 : _tipMorph.value,
                  expansion: reduceMotion ? 1 : _expansion.value,
                ),
                _SwordLayer(entrance: reduceMotion ? 1 : _swordEntrance.value),
                if (_error != null)
                  _ErrorControls(
                    onRetry: _initialize,
                    onEnterAnyway: widget.onEnterAnyway,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperLayer extends StatelessWidget {
  const _PaperLayer({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Image.asset(
        _DisciplineFreedomLoadingPageState._paperAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _LandscapeLayer extends StatelessWidget {
  const _LandscapeLayer({
    required this.swordProgress,
    required this.tipMorph,
    required this.expansion,
  });

  final double swordProgress;
  final double tipMorph;
  final double expansion;

  @override
  Widget build(BuildContext context) {
    // Landscape is the foreground sheet. The clip removes a straight vertical
    // trail only after the sword has passed and exposes the paper below.
    return ClipPath(
      clipper: _SwordCutClipper(
        swordProgress.clamp(0, 1),
        tipMorph.clamp(0, 1),
        expansion.clamp(0, 1),
      ),
      child: Image.asset(
        _DisciplineFreedomLoadingPageState._landscapeAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _SwordCutClipper extends CustomClipper<Path> {
  const _SwordCutClipper(this.swordProgress, this.tipMorph, this.expansion);

  final double swordProgress;
  final double tipMorph;
  final double expansion;

  @override
  Path getClip(Size size) {
    final center = size.width / 2;
    final swordBottom =
        size.height *
        (.5 + _swordVerticalPosition(swordProgress) + _swordHeightFactor / 2);
    if (swordBottom >= size.height) {
      return Path()..addRect(Offset.zero & size);
    }

    // The leading edge remains attached to the sword's tail. Once the sword
    // leaves the screen, the rounded cap continues out during side expansion.
    final initialCutWidth = size.width * .18;
    final roundedCutWidth = size.width * .48;
    final morphingCutWidth =
        initialCutWidth + (roundedCutWidth - initialCutWidth) * tipMorph;
    final cutWidth =
        morphingCutWidth + (size.width * 1.02 - morphingCutWidth) * expansion;
    final halfWidth = cutWidth / 2;
    final capHeight = halfWidth;
    final cutTop =
        swordBottom.clamp(-size.height, size.height) - capHeight * expansion;

    // The point is fully semicircular on contact. While the width expands,
    // the complete cap moves above the viewport, so the visible opening reads
    // as a rectangle spreading sideways.
    final roundness = Curves.easeInOutCubic.transform(tipMorph);
    final controlDx = halfWidth * (.5 + .5 * roundness);
    final controlY = cutTop + capHeight * .5 * (1 - roundness);
    final cut = Path()
      ..moveTo(center, cutTop)
      ..quadraticBezierTo(
        center + controlDx,
        controlY,
        center + halfWidth,
        cutTop + capHeight,
      )
      ..lineTo(center + halfWidth, size.height)
      ..lineTo(center - halfWidth, size.height)
      ..lineTo(center - halfWidth, cutTop + capHeight)
      ..quadraticBezierTo(center - controlDx, controlY, center, cutTop)
      ..close();

    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(cut, Offset.zero);
  }

  @override
  bool shouldReclip(_SwordCutClipper oldClipper) =>
      oldClipper.swordProgress != swordProgress ||
      oldClipper.tipMorph != tipMorph ||
      oldClipper.expansion != expansion;
}

const _swordHeightFactor = .91;

double _swordVerticalPosition(double progress) {
  final t = progress.clamp(0, 1);
  const morphStart = .525;
  if (t < morphStart) {
    final u = t / morphStart;
    // Enter quickly, then shed a little speed before reaching center. The
    // derivative at u=1 matches the accelerating segment below.
    return 1.20 - 1.604 * u + .404 * u * u;
  }
  // Once the point starts becoming a semicircle, add restrained acceleration
  // through the top edge. The 75/25 blend is deliberately milder than a full
  // ease-in so the sword gathers pace without suddenly darting away.
  final u = (t - morphStart) / (1 - morphStart);
  final accelerated = .75 * u + .25 * u * u;
  return -.96 * accelerated;
}

class _SwordLayer extends StatelessWidget {
  const _SwordLayer({required this.entrance});

  final double entrance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final swordHeight = constraints.maxHeight * _swordHeightFactor;
        return Transform.translate(
          offset: Offset(
            0,
            constraints.maxHeight * _swordVerticalPosition(entrance),
          ),
          child: Center(
            child: Image.asset(
              _DisciplineFreedomLoadingPageState._swordAsset,
              height: swordHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorControls extends StatelessWidget {
  const _ErrorControls({required this.onRetry, this.onEnterAnyway});

  final VoidCallback onRetry;
  final VoidCallback? onEnterAnyway;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 36 + MediaQuery.paddingOf(context).bottom,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xddf5f1e8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x33231f1b)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.loadingPreparationFailed,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff28231e),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(onPressed: onRetry, child: const Text('重试')),
                    if (onEnterAnyway != null)
                      TextButton(
                        onPressed: onEnterAnyway,
                        child: const Text('直接进入'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
