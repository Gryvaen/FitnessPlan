import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RiverDistortionPainter extends CustomPainter {
  const RiverDistortionPainter({
    required this.program,
    required this.image,
    required this.progress,
  });

  final ui.FragmentProgram program;
  final ui.Image image;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, progress)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant RiverDistortionPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      image != oldDelegate.image ||
      program != oldDelegate.program;
}
