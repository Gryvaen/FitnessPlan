import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RiverDistortionPainter extends CustomPainter {
  const RiverDistortionPainter({
    required this.program,
    required this.image,
    required this.progress,
    required this.time,
  });

  final ui.FragmentProgram program;
  final ui.Image image;
  final double progress;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, progress)
      ..setFloat(5, time)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant RiverDistortionPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      time != oldDelegate.time ||
      image != oldDelegate.image ||
      program != oldDelegate.program;
}
