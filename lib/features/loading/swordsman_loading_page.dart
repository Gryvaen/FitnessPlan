import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import 'loading_config.dart';
import 'swordsman_loading_scene.dart';

class SwordsmanLoadingPage extends StatefulWidget {
  const SwordsmanLoadingPage({
    super.key,
    this.onInitialize,
    required this.onFinished,
    this.onPrewarm,
    this.onError,
    this.onEnterAnyway,
  });

  final Future<void> Function()? onInitialize;
  final VoidCallback onFinished;
  final VoidCallback? onPrewarm;
  final ValueChanged<Object>? onError;
  final VoidCallback? onEnterAnyway;

  @override
  State<SwordsmanLoadingPage> createState() => _SwordsmanLoadingPageState();
}

class _SwordsmanLoadingPageState extends State<SwordsmanLoadingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _assets = <String>[
    'assets/splash/paper.webp',
    'assets/splash/landscape.webp',
    'assets/splash/sword.webp',
  ];

  late final AnimationController _scene;
  late final AnimationController _exit;
  late final CurvedAnimation _exitCurve;
  late final Animation<double> _exitOpacity;
  Timer? _prewarmTimer;
  Object? _error;
  bool _started = false;
  bool _finishing = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scene = AnimationController(
      vsync: this,
      duration: SwordsmanLoadingConfig.cycleDuration,
    );
    _exit = AnimationController(
      vsync: this,
      duration: SwordsmanLoadingConfig.exitDuration,
    );
    _exitCurve = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
    _exitOpacity = ReverseAnimation(_exitCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  Future<void> _start() async {
    await Future.wait(
      _assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) _scene.forward();
    _prewarmTimer = Timer(SwordsmanLoadingConfig.prewarmDelay, () {
      if (mounted && !_finishing) widget.onPrewarm?.call();
    });
    await _initialize(reduceMotion: reduceMotion);
  }

  Future<void> _initialize({required bool reduceMotion}) async {
    final attempt = ++_attempt;
    if (mounted) setState(() => _error = null);
    try {
      final minimum = Future<void>.delayed(
        reduceMotion
            ? SwordsmanLoadingConfig.reducedMotionDuration
            : SwordsmanLoadingConfig.cycleDuration,
      );
      await Future.wait<void>([
        widget.onInitialize?.call() ?? Future<void>.value(),
        minimum,
      ]);
      if (!mounted || attempt != _attempt || _finishing) return;
      await _finish();
    } catch (error) {
      if (!mounted || attempt != _attempt || _finishing) return;
      widget.onError?.call(error);
      setState(() => _error = error);
    }
  }

  void _skip() {
    if (_finishing || _error != null) return;
    _finishing = true;
    _prewarmTimer?.cancel();
    _scene.stop();
    widget.onFinished();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _prewarmTimer?.cancel();
    await _exit.forward();
    _scene.stop();
    if (mounted) widget.onFinished();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finishing || MediaQuery.disableAnimationsOf(context)) return;
    if (state == AppLifecycleState.resumed) {
      if (!_scene.isCompleted) _scene.forward();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _scene.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prewarmTimer?.cancel();
    _exitCurve.dispose();
    _scene.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: SwordsmanLoadingConfig.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _error == null ? _skip : null,
        child: FadeTransition(
          opacity: _exitOpacity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: SwordsmanLoadingConfig.background),
              RepaintBoundary(
                child: SwordsmanLoadingScene(
                  animation: _scene,
                  reduceMotion: reduceMotion,
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: _LoadingStatus(
                  error: _error,
                  onRetry: () => _initialize(reduceMotion: reduceMotion),
                  onEnterAnyway: widget.onEnterAnyway,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus({
    required this.error,
    required this.onRetry,
    required this.onEnterAnyway,
  });

  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback? onEnterAnyway;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: SwordsmanLoadingConfig.ink.withValues(alpha: .62),
      letterSpacing: 2,
      fontFamily: 'LXGWWenKai',
    );
    if (error == null) {
      return Semantics(
        liveRegion: true,
        label: context.l10n.loadingPreparingPlan,
        child: Text(
          context.l10n.loadingPreparingPlan,
          textAlign: TextAlign.center,
          style: style,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.loadingPreparationFailed, style: style),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            if (onEnterAnyway != null)
              TextButton(
                onPressed: onEnterAnyway,
                child: Text(context.l10n.enterAnyway),
              ),
          ],
        ),
      ],
    );
  }
}
