import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'river_distortion_painter.dart';
import 'swordsman_animation.dart';

class SwordsmanLoadingScene extends StatefulWidget {
  const SwordsmanLoadingScene({
    super.key,
    required this.animation,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final bool reduceMotion;

  @override
  State<SwordsmanLoadingScene> createState() => _SwordsmanLoadingSceneState();
}

class _SwordsmanLoadingSceneState extends State<SwordsmanLoadingScene> {
  late final Future<(ui.FragmentProgram, ui.Image)> _riverResources;
  ui.Image? _decodedLandscape;

  @override
  void initState() {
    super.initState();
    _riverResources = _loadRiverResources();
  }

  Future<(ui.FragmentProgram, ui.Image)> _loadRiverResources() async {
    final results = await Future.wait<Object>([
      ui.FragmentProgram.fromAsset('shaders/river_distortion.frag'),
      rootBundle.load('assets/splash/landscape.png'),
    ]);
    final program = results[0] as ui.FragmentProgram;
    final data = results[1] as ByteData;
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    _decodedLandscape = frame.image;
    return (program, frame.image);
  }

  @override
  void dispose() {
    _decodedLandscape?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final targetWidth = (size.width * pixelRatio).round().clamp(1, 941);
        final targetHeight = (size.height * pixelRatio).round().clamp(1, 1672);

        final paper = Image.asset(
          'assets/splash/paper.webp',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          cacheWidth: targetWidth,
          cacheHeight: targetHeight,
        );

        return AnimatedBuilder(
          animation: widget.animation,
          builder: (context, _) {
            final frame = SwordsmanFrame.at(
              widget.animation.value,
              reduceMotion: widget.reduceMotion,
            );
            final swordHeight = size.height * .42;
            final swordWidth = swordHeight * (635 / 2069);
            final swordTop = frame.swordY * size.height - swordHeight * .16;
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                paper,
                if (!widget.reduceMotion)
                  FutureBuilder<(ui.FragmentProgram, ui.Image)>(
                    future: _riverResources,
                    builder: (context, snapshot) {
                      final resources = snapshot.data;
                      if (resources == null) {
                        return Image.asset(
                          'assets/splash/landscape.png',
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          cacheWidth: targetWidth,
                          cacheHeight: targetHeight,
                        );
                      }
                      return CustomPaint(
                        painter: RiverDistortionPainter(
                          program: resources.$1,
                          image: resources.$2,
                          progress: frame.revealProgress,
                          time: widget.animation.value,
                        ),
                      );
                    },
                  ),
                if (frame.swordOpacity > 0)
                  Positioned(
                    left: (size.width - swordWidth) / 2,
                    top: swordTop,
                    width: swordWidth,
                    height: swordHeight,
                    child: Opacity(
                      opacity: frame.swordOpacity,
                      child: Image.asset(
                        'assets/splash/sword.webp',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                        cacheHeight: (swordHeight * pixelRatio).round().clamp(
                          1,
                          2069,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
