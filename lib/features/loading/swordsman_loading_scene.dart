import 'package:flutter/material.dart';

import 'ink_particle_painter.dart';
import 'loading_config.dart';
import 'swordsman_animation.dart';

class SwordsmanLoadingScene extends StatelessWidget {
  const SwordsmanLoadingScene({
    super.key,
    required this.animation,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final characterHeight =
            (size.height * SwordsmanLoadingConfig.characterHeightFactor).clamp(
              0.0,
              size.width *
                  1.63 *
                  SwordsmanLoadingConfig.characterMaxWidthFactor,
            );
        final character = Image.asset(
          'assets/loading/swordsman.png',
          height: characterHeight,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          cacheHeight: (characterHeight * pixelRatio).round().clamp(1, 1602),
        );
        final flyingSword = Image.asset(
          'assets/loading/flying_sword.png',
          width: size.width * SwordsmanLoadingConfig.flyingSwordWidthFactor,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          cacheWidth:
              (size.width *
                      SwordsmanLoadingConfig.flyingSwordWidthFactor *
                      pixelRatio)
                  .round()
                  .clamp(1, 2172),
        );
        final slash = Image.asset(
          'assets/loading/ink_slash.png',
          width: size.width * SwordsmanLoadingConfig.inkSlashWidthFactor,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          cacheWidth:
              (size.width *
                      SwordsmanLoadingConfig.inkSlashWidthFactor *
                      pixelRatio)
                  .round()
                  .clamp(1, 2172),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final frame = SwordsmanFrame.at(
              animation.value,
              reduceMotion: reduceMotion,
            );
            final characterCenter = Offset(
              size.width * SwordsmanLoadingConfig.characterCenter.dx,
              size.height * SwordsmanLoadingConfig.characterCenter.dy,
            );
            final swordCenter = Offset(
              frame.swordPosition.dx * size.width,
              frame.swordPosition.dy * size.height,
            );

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                CustomPaint(painter: const _InkMistPainter()),
                Positioned(
                  left: characterCenter.dx - size.width * .39,
                  top:
                      characterCenter.dy -
                      characterHeight * .46 +
                      frame.characterDy,
                  width: size.width * .78,
                  height: characterHeight,
                  child: Transform.rotate(
                    angle: frame.characterRotation,
                    alignment: const Alignment(.2, .4),
                    child: Transform.scale(
                      scale: frame.characterScale,
                      child: RepaintBoundary(child: character),
                    ),
                  ),
                ),
                if (frame.swordOpacity > 0)
                  Positioned(
                    left: swordCenter.dx - size.width * .17,
                    top: swordCenter.dy - size.width * .057,
                    width: size.width * .34,
                    height: size.width * .114,
                    child: Opacity(
                      opacity: frame.swordOpacity,
                      child: Transform.rotate(
                        angle: frame.swordRotation,
                        child: RepaintBoundary(child: flyingSword),
                      ),
                    ),
                  ),
                if (frame.slashOpacity > 0)
                  Positioned(
                    left: size.width * (-.04 + frame.slashDx),
                    top: size.height * .42,
                    width: size.width * 1.08,
                    child: Opacity(
                      opacity: frame.slashOpacity,
                      child: Transform.scale(
                        scaleX: frame.slashScaleX,
                        alignment: Alignment.centerLeft,
                        child: RepaintBoundary(child: slash),
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: InkParticlePainter(
                      progress: frame.particleProgress,
                      strength: frame.particleStrength,
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

class _InkMistPainter extends CustomPainter {
  const _InkMistPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SwordsmanLoadingConfig.mist
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final horizon = size.height * .72;
    final path = Path()
      ..moveTo(0, horizon)
      ..quadraticBezierTo(
        size.width * .18,
        horizon - 13,
        size.width * .37,
        horizon - 4,
      )
      ..quadraticBezierTo(
        size.width * .63,
        horizon + 9,
        size.width,
        horizon - 2,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkMistPainter oldDelegate) => false;
}
