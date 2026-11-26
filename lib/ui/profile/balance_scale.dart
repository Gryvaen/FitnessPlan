import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'cultivation_labels.dart';

/// 「日月同衡」水墨天秤的素材（由 tool/libra_assets.py 生成）。
const kBalanceAssetDir = 'assets/cultivation/maintain';
const kBalanceBeamAsset = '$kBalanceAssetDir/beam.png';
const kBalanceBaseAsset = '$kBalanceAssetDir/base.png';
const kBalancePanAsset = '$kBalanceAssetDir/pan.png';
const kBalanceMoonAsset = '$kBalanceAssetDir/moon.png';
const kBalanceSunAsset = '$kBalanceAssetDir/sun.png';
const kBalanceSealAsset = '$kBalanceAssetDir/seal.png';
const kBalanceBackgroundAsset = '$kBalanceAssetDir/maintain_bg.jpg';

const kBalanceAssets = [
  kBalanceBeamAsset,
  kBalanceBaseAsset,
  kBalancePanAsset,
  kBalanceMoonAsset,
  kBalanceSunAsset,
  kBalanceSealAsset,
];

/// 宣纸底色（取自背景图底部）。
const kBalancePaperColor = Color(0xFFF5EFE5);
const kBalanceInkColor = Color(0xFF1B2A24);

// ── 素材锚点（相对各自图片宽高的比例，见 tool/libra_assets.py 输出）────
const _beamAspect = 10.3333; // 宽 / 高，支点在图片正中
const _beamRingL = Offset(0.0274, 0.6958);
const _beamRingR = Offset(0.9754, 0.675);
const _panAspect = 0.8242;
const _panHook = Offset(0.5, 0.0345);
const _panRimY = 0.8654;
const _baseAspect = 0.5306;
const _baseTipY = 0.0053;

// ── 版式（相对天秤宽度 W）──────────────────────────────────────────
const _beamWidth = 0.80;
const _pivotY = 0.17;
const _panWidth = 0.29;
const _baseWidth = 0.40;

/// 吊盘挂环挂在横梁圆环下缘（相对横梁宽度）。
const _hookDrop = 0.012;

/// 天秤整体宽高比（宽 / 高）。
const kBalanceScaleAspect = 1 / (_pivotY + _baseWidth / _baseAspect + 0.02);

/// 宽为 [width] 的天秤在倾角 [angle] 时，左右吊盘挂环中心的位置
/// （坐标原点为天秤左上角）。正角度 = 右盘下沉。
(Offset, Offset) balanceHookPoints(double angle, double width) {
  final beamW = width * _beamWidth;
  final beamH = beamW / _beamAspect;
  final pivot = Offset(width / 2, width * _pivotY);
  final c = math.cos(angle);
  final s = math.sin(angle);
  Offset hang(Offset ring) {
    final dx = (ring.dx - 0.5) * beamW;
    final dy = (ring.dy - 0.5) * beamH;
    return pivot +
        Offset(dx * c - dy * s, dx * s + dy * c) +
        Offset(0, beamW * _hookDrop);
  }

  return (hang(_beamRingL), hang(_beamRingR));
}

/// 水墨天秤：砚台立柱 + 书法横梁 + 两只始终竖直下垂的吊盘。
/// 左盘盛新月（亏），右盘盛赭日（盈），日月大小随 [leftShare]/[rightShare]。
///
/// [tiltRadians] 变化时横梁以欠阻尼弹簧摆动后落定；[sway] 为 true 时
/// 另有极轻的待机微摆（系统关闭动画时自动停用）。
class BalanceScale extends StatefulWidget {
  const BalanceScale({
    super.key,
    required this.tiltRadians,
    this.leftShare = 0,
    this.rightShare = 0,
    this.leftCaption,
    this.rightCaption,
    this.leftValue,
    this.rightValue,
    this.sway = true,
  });

  final double tiltRadians;
  final double leftShare;
  final double rightShare;
  final String? leftCaption;
  final String? rightCaption;
  final String? leftValue;
  final String? rightValue;
  final bool sway;

  @override
  State<BalanceScale> createState() => _BalanceScaleState();
}

class _BalanceScaleState extends State<BalanceScale>
    with TickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 50, damping: 6);
  static const _swayAmplitude = 0.4 * math.pi / 180;

  late final AnimationController _angle = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    // 首次出现时从水平摆到当前倾角，像刚把东西放上秤。
    _springTo(widget.tiltRadians);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSway();
  }

  @override
  void didUpdateWidget(BalanceScale old) {
    super.didUpdateWidget(old);
    if (old.tiltRadians != widget.tiltRadians) _springTo(widget.tiltRadians);
    if (old.sway != widget.sway) _syncSway();
  }

  void _springTo(double target) {
    _angle.animateWith(
      SpringSimulation(_spring, _angle.value, target, _angle.velocity),
    );
  }

  void _syncSway() {
    final on = widget.sway && !MediaQuery.disableAnimationsOf(context);
    if (on && !_sway.isAnimating) {
      _sway.repeat();
    } else if (!on && _sway.isAnimating) {
      _sway
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _angle.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var w = constraints.maxWidth;
        if (constraints.hasBoundedHeight) {
          w = math.min(w, constraints.maxHeight * kBalanceScaleAspect);
        }
        return Center(
          child: SizedBox(
            width: w,
            height: w / kBalanceScaleAspect,
            child: AnimatedBuilder(
              animation: Listenable.merge([_angle, _sway]),
              builder: (context, _) => _buildScale(
                context,
                w,
                _angle.value +
                    math.sin(_sway.value * 2 * math.pi) * _swayAmplitude,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScale(BuildContext context, double w, double angle) {
    final beamW = w * _beamWidth;
    final beamH = beamW / _beamAspect;
    final pivot = Offset(w / 2, w * _pivotY);
    final panW = w * _panWidth;
    final panH = panW / _panAspect;
    final baseW = w * _baseWidth;
    final (leftHook, rightHook) = balanceHookPoints(angle, w);

    Widget img(String asset, double width) => Image.asset(
      asset,
      width: width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );

    List<Widget> pan(
      Offset hook,
      String orbAsset,
      double share,
      String? caption,
      String? value,
      Color captionColor,
    ) {
      final left = hook.dx - panW * _panHook.dx;
      final top = hook.dy - panH * _panHook.dy;
      final rimY = top + panH * _panRimY;
      final orbW = panW * (0.22 + 0.30 * share.clamp(0.0, 1.0));
      return [
        if (share > 0)
          Positioned(
            left: hook.dx - orbW / 2,
            top: rimY - orbW * 0.72,
            child: img(orbAsset, orbW),
          ),
        Positioned(left: left, top: top, child: img(kBalancePanAsset, panW)),
        if (caption != null || value != null)
          Positioned(
            left: hook.dx - panW * 0.7,
            width: panW * 1.4,
            top: top + panH + 4,
            child: _PanLabel(
              caption: caption,
              value: value,
              color: captionColor,
            ),
          ),
      ];
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: pivot.dx - baseW / 2,
          top: pivot.dy - baseW / _baseAspect * _baseTipY + beamH * 0.12,
          child: img(kBalanceBaseAsset, baseW),
        ),
        Positioned(
          left: pivot.dx - beamW / 2,
          top: pivot.dy - beamH / 2,
          child: Transform.rotate(
            angle: angle,
            child: img(kBalanceBeamAsset, beamW),
          ),
        ),
        ...pan(
          leftHook,
          kBalanceMoonAsset,
          widget.leftShare,
          widget.leftCaption,
          widget.leftValue,
          kBalanceDeficitColor,
        ),
        ...pan(
          rightHook,
          kBalanceSunAsset,
          widget.rightShare,
          widget.rightCaption,
          widget.rightValue,
          kBalanceSurplusColor,
        ),
      ],
    );
  }
}

class _PanLabel extends StatelessWidget {
  const _PanLabel({
    required this.caption,
    required this.value,
    required this.color,
  });

  final String? caption;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null)
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(color: color),
          ),
        if (value != null)
          Text(
            value!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: kBalanceInkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
