import 'package:flutter/material.dart';

abstract final class SwordsmanLoadingConfig {
  static const cycleDuration = Duration(milliseconds: 3600);
  // The visual sequence (river flow + freeze + sword exiting the screen) is
  // already fully settled by t=.82 of cycleDuration (~2952ms) - revealProgress
  // clamps to 1 and every row's disturbance is frozen by then. This is kept
  // separate from cycleDuration (which still drives _scene, a
  // AnimationController, and every t-relative timing constant upstream)
  // so it can be tuned independently as "how long to wait" rather than
  // "how long the animation cycle is".
  static const minimumDisplayDuration = Duration(milliseconds: 3100);
  static const exitDuration = Duration(milliseconds: 420);
  static const reducedMotionDuration = Duration(milliseconds: 320);
  static const prewarmDelay = Duration(milliseconds: 2200);

  static const background = Color(0xFFF3EFE5);
  static const ink = Color(0xFF242320);

  // Retained for the legacy particle painter used by preview tooling.
  static const particleCount = 28;
}
