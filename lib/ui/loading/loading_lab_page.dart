import 'package:flutter/material.dart';

import 'discipline_freedom_loading_page.dart';

/// Debug-only splash playground: loop / freeze / scrub without entering Home.
///
/// Run with:
/// `flutter run --dart-define=LOADING_LAB=true`
class LoadingLabPage extends StatefulWidget {
  const LoadingLabPage({super.key});

  @override
  State<LoadingLabPage> createState() => _LoadingLabPageState();
}

class _LoadingLabPageState extends State<LoadingLabPage>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _progress;
  late final AnimationController _player;

  var _autoLoop = true;
  var _frozen = false;

  @override
  void initState() {
    super.initState();
    _progress = ValueNotifier(0);
    _player = AnimationController(
      vsync: this,
      duration: DisciplineFreedomLoadingPage.entranceDuration,
    )..addListener(_syncProgressFromPlayer);
    _player.addStatusListener(_onPlayerStatus);
    // Stay on the opening frame until play is pressed.
    _frozen = true;
    _player.value = 0;
    _progress.value = 0;
  }

  void _syncProgressFromPlayer() {
    if (_frozen) return;
    _progress.value = _player.value;
  }

  void _onPlayerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _frozen) return;
    if (_autoLoop) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || _frozen || !_autoLoop) return;
        _player.forward(from: 0);
      });
    } else {
      setState(() => _frozen = true);
    }
  }

  void _freeze() {
    _player.stop();
    _progress.value = _player.value;
    setState(() => _frozen = true);
  }

  void _play() {
    setState(() {
      _frozen = false;
      _autoLoop = true;
    });
    if (_player.value >= 1) {
      _player.forward(from: 0);
    } else {
      _player.forward();
    }
  }

  void _scrub(double value) {
    _player.stop();
    _player.value = value;
    _progress.value = value;
    if (!_frozen) setState(() => _frozen = true);
  }

  void _replay() {
    setState(() {
      _frozen = false;
      _autoLoop = true;
    });
    _player.forward(from: 0);
  }

  @override
  void dispose() {
    _player.removeListener(_syncProgressFromPlayer);
    _player.removeStatusListener(_onPlayerStatus);
    _player.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        DisciplineFreedomLoadingPage(
          labProgress: _progress,
          releaseDeferredFirstFrame: true,
          onInitialize: () async {},
          onFinished: () {},
          onError: (_) {},
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12 + bottom,
          child: Material(
            color: const Color(0xee2b2722),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (context, value, _) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${(value * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xfff4efe6),
                                fontSize: 12,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: const Color(0xfff4efe6),
                                inactiveTrackColor: const Color(0x55f4efe6),
                                thumbColor: const Color(0xfff4efe6),
                              ),
                              child: Slider(
                                value: value.clamp(0.0, 1.0),
                                onChanged: _scrub,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        _frozen ? '定格' : (_autoLoop ? '循环' : '播放'),
                        style: const TextStyle(
                          color: Color(0xfff4efe6),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _frozen ? '继续播放' : '定格',
                        onPressed: _frozen ? _play : _freeze,
                        icon: Icon(
                          _frozen ? Icons.play_arrow : Icons.pause,
                          color: const Color(0xfff4efe6),
                          size: 22,
                        ),
                      ),
                      IconButton(
                        tooltip: _autoLoop ? '关闭循环' : '开启循环',
                        onPressed: () => setState(() => _autoLoop = !_autoLoop),
                        icon: Icon(
                          Icons.repeat,
                          color: _autoLoop
                              ? const Color(0xfff4efe6)
                              : const Color(0x66f4efe6),
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: '从头重播',
                        onPressed: _replay,
                        icon: const Icon(
                          Icons.replay,
                          color: Color(0xfff4efe6),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
