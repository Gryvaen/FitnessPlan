import 'package:flutter/material.dart';

abstract final class SwordsmanLoadingConfig {
  static const cycleDuration = Duration(milliseconds: 3600);
  static const exitDuration = Duration(milliseconds: 420);
  static const reducedMotionDuration = Duration(milliseconds: 320);
  static const prewarmDelay = Duration(milliseconds: 2200);

  static const background = Color(0xFFF3EFE5);
  static const ink = Color(0xFF242320);

  // Retained for the legacy particle painter used by preview tooling.
  static const particleCount = 28;
}
