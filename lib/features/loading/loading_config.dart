import 'package:flutter/material.dart';

abstract final class SwordsmanLoadingConfig {
  static const cycleDuration = Duration(seconds: 6);
  static const exitDuration = Duration(milliseconds: 280);
  static const reducedMotionDuration = Duration(milliseconds: 300);
  static const prewarmDelay = Duration(milliseconds: 4200);

  static const background = Color(0xFFFFFFFF);
  static const ink = Color(0xFF000000);
  static const mist = Color(0x14000000);

  static const characterCenter = Offset(.53, .56);
  static const characterHeightFactor = .66;
  static const characterMaxWidthFactor = .78;
  static const characterFloat = 2.6;
  static const characterScaleMin = .995;
  static const characterScaleMax = 1.005;
  static const idleRotation = .5 * 3.141592653589793 / 180;
  static const strikeRotation = 2.2 * 3.141592653589793 / 180;

  static const flyingSwordWidthFactor = .34;
  static const inkSlashWidthFactor = 1.08;
  static const particleCount = 28;
}
