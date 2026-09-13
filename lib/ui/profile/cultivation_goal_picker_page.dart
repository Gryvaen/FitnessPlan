import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import 'cultivation_labels.dart';

/// 「境界画轴」选择页：仙侠大厅中同屏悬挂着维持/减脂/增肌三幅立轴，排布成
/// 一个虚拟圆柱的截面——三幅卷轴始终都在同一屏内、互不遮挡，中央那幅正对
/// 玩家（最大最亮），两侧的随夹角向外倾斜、往圆柱背面收，像绕着一个转轴
/// 排开（而不是叠在中央卷轴后方）。左右滑动时角度连续变化，越过任一端会
/// 循环回另一端（[_wrappedDelta]，周期 3）。手指拖拽实时跟手，松手按拖拽
/// 距离/速度 spring 回中央或切到下一幅；也可直接点击左右卷轴。点进中央那
/// 幅即可查看该目标体系（若与当前所选目标一致，进入真实玩法；否则展示
/// 「尚未开启」占位页——见 [CultivationGoalScreen]）。从境界主页右上角齿轮
/// 图标进入。
const _kGoalOrder = [FitnessGoal.maintain, FitnessGoal.cut, FitnessGoal.bulk];
const _kPeriod = 3.0;

/// 三张去底立绘（见 [CultivationGoalTheme.cultivationScrollAsset]）宽高比
/// 相近（约 0.563–0.569），取一个共用近似值，避免逐资源异步读取尺寸。
const _kScrollAspect = 0.565;

/// 圆柱式轮播：三幅卷轴铺在圆柱朝向用户的前弧面上，而不是组成闭合
/// 的三角柱。中央卷轴正对用户，左右两幅退到约 ±60°；滑动时整组
/// 卷轴沿前弧面连续滚动。
const _kAnglePerStep = math.pi / 3; // 60°
const _kPerspective = 0.0016;

/// 圆柱半径相对「卷轴基准宽度」的倍数：正三边形内切圆半径公式
/// `w / (2·tan(π/n))`（n=3）保证均分时相邻卷轴刚好不重叠，这里再放大
/// 一些换取更明显的空间层次（也是 spec 允许的「如需更大空间可增大半径」）。
const _kRadiusMultiplier = 2.0;
// 轮播跨过前弧面边缘时，卷轴会淡到几乎不可见，再从另一侧出现，
// 让循环看起来像绕过用户身后，而不是瞬移。
const _kMinOpacity = 0.05;

/// 把 `index - page` 换算成周期 [_kPeriod] 下最短的有符号夹角步数，
/// 范围 (-period/2, period/2]——这样左右滑动越过任一端会自然循环到另一端，
/// 而不是停在头尾。
double _wrappedDelta(double index, double page) {
  var d = index - page;
  final half = _kPeriod / 2;
  while (d > half) {
    d -= _kPeriod;
  }
  while (d <= -half) {
    d += _kPeriod;
  }
  return d;
}

class CultivationGoalPickerPage extends ConsumerStatefulWidget {
  const CultivationGoalPickerPage({super.key});

  @override
  ConsumerState<CultivationGoalPickerPage> createState() =>
      _CultivationGoalPickerPageState();
}

class _CultivationGoalPickerPageState
    extends ConsumerState<CultivationGoalPickerPage>
    with TickerProviderStateMixin {
  /// 连续的「页码」，对 [_kPeriod] 取模后对应 [_kGoalOrder] 下标；非整数表示
  /// 正在两幅之间过渡。拖拽时直接改写，松手后由 [_springController] 驱动着
  /// 弹簧滑向最近的整数。
  late double _page;
  int _settledIndex = 0;
  double? _pendingTarget;

  late final AnimationController _springController;

  /// 单个常驻 ticker 驱动粒子漂浮 + 卷轴呼吸浮动，避免每个粒子/每张卷轴各开
  /// 一个 AnimationController。
  late final AnimationController _ambient;

  /// 新卷轴居中「定格」时短促播放一次的强调动画（缩放回弹 + 辉光加强），
  /// 呼应「选中反馈」，但不做弹窗或系统 toast。
  late final AnimationController _settlePop;

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final activeGoal = ref.read(profileProvider)?.goal;
    final initialIndex = activeGoal == null
        ? 1
        : _kGoalOrder.indexOf(activeGoal);
    _settledIndex = initialIndex;
    _page = initialIndex.toDouble();
    _springController =
        AnimationController(
            vsync: this,
            lowerBound: -100,
            upperBound: 100,
            value: _page,
          )
          ..addListener(() {
            setState(() => _page = _springController.value);
          })
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) return;
            final target = _pendingTarget;
            if (target == null) return;
            // 定格后把 _page 折回 [0, period) 附近，避免拖拽很久后数值无限
            // 增长；折回值与 target 相差整数个周期，视觉上无缝（_wrappedDelta
            // 只关心 mod period 的结果）。
            final settled = ((target % _kPeriod) + _kPeriod) % _kPeriod;
            final settledIndex = settled.round() % _kGoalOrder.length;
            _springController.value = settled;
            if (settledIndex != _settledIndex) {
              setState(() => _settledIndex = settledIndex);
              _settlePop.forward(from: 0);
            }
          });
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _settlePop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _particles = List.generate(
      16,
      (i) => _Particle.random(math.Random(i * 97 + 13)),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _ambient.dispose();
    _settlePop.dispose();
    super.dispose();
  }

  void _springTo(double target, {double velocity = 0}) {
    _pendingTarget = target;
    _springController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 280, damping: 26),
        _page,
        target,
        velocity,
      ),
    );
  }

  double? _dragSpacingPx;

  void _onDragStart(DragStartDetails details) {
    // 新手势开始时取消上一段 spring，避免旧动画继续覆盖手指当前的位置。
    _springController.stop();
    _pendingTarget = null;
    _springController.value = _page;
  }

  void _onDragUpdate(DragUpdateDetails details, double spacingPx) {
    // 手指向左拖（delta.dx 为负）让卷轴向左滚动，下一幅从右侧进入。
    // 页面坐标与视觉滚动方向相反，因此这里减去手指位移。
    setState(() {
      _page -= details.delta.dx / spacingPx;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final spacingPx = _dragSpacingPx;
    if (spacingPx == null) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    double target;
    if (vx.abs() > 400) {
      target = vx < 0 ? _page.floor() + 1 : _page.ceil() - 1;
    } else {
      target = _page.roundToDouble();
    }
    // _page 与手指位移方向相反，所以 page velocity 也要反向换算。
    _springTo(target, velocity: -vx / spacingPx);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeGoal = ref.watch(profileProvider)?.goal;
    final frontIndex =
        ((_page.round() % _kGoalOrder.length) + _kGoalOrder.length) %
        _kGoalOrder.length;
    final frontGoal = _kGoalOrder[frontIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFFF1E3BC),
        title: Text(
          l10n.cultivationPickerTitle,
          style: const TextStyle(
            color: Color(0xFFF1E3BC),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — 固定不动的仙侠大厅背景：轻微虚化制造景深，不随画轴
          // 滑动而移动。RepaintBoundary 隔离，避免轮播/粒子重绘时连带这层
          // 昂贵的模糊一起重算。
          RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 7,
                sigmaY: 7,
                tileMode: TileMode.decal,
              ),
              child: Image.asset(
                'assets/cultivation/goal_picker_hall.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.46),
            ),
          ),
          // 随聚焦目标变色的极淡环境光——「灵气」而非霓虹光效。
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 1.0,
                  colors: [
                    frontGoal.cultivationAccentColor.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 2 — 漂浮花瓣 / 尘埃 / 光粒子，数量克制。
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  t: _ambient.value,
                  accent: frontGoal.cultivationAccentColor,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          // Layer 3 — 三幅同屏悬挂的立轴，绕虚拟圆柱排开：中央正对玩家、
          // 最大最亮，两侧随夹角向外倾斜、缩小变暗，互不遮挡；循环滑动。
          // 高度拉满整个安全区——信息卡/分页点不再单独占一行，改成浮在
          // 卷轴下方（见 Layer 4），这样卷轴能用到全部竖直空间。
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  // 拖满约 0.55 倍屏宽切换一整幅，手感接近卷轴自身宽度。
                  _dragSpacingPx = w * 0.55;

                  // 卷轴用满这块区域的整段高度（减去顶部给已选徽记预留
                  // 的空间，否则徽记一出现就会把内容顶到底部溢出）；宽度
                  // 严格按画轴素材比例反推。信息卡是浮在卷轴下方的悬浮
                  // 卡片（Layer 4），不再挤占竖直空间。
                  const selectedMarkBudget = 6 + 10.0;
                  final maxCardH = h - selectedMarkBudget;
                  var cardH = maxCardH;
                  var cardW = cardH * _kScrollAspect;
                  // 窄屏时避免两侧卷轴被完全裁掉；正常手机宽度会
                  // 走上面的满高分支。
                  final maxCardW = w * 0.94;
                  if (cardW > maxCardW) {
                    cardW = maxCardW;
                    cardH = cardW / _kScrollAspect;
                  }
                  // 前弧面不使用三角形内切圆半径，否则第三张会被推到
                  // 圆柱背面；这里按卷轴宽度控制左右间距。
                  final radius = cardW * 0.29 * _kRadiusMultiplier;

                  // 圆柱背面（|t| 更大）的先画，正对玩家的后画（在最
                  // 上层），避免出现绘制顺序导致的瞬间穿插。
                  final order = List.generate(_kGoalOrder.length, (i) => i)
                    ..sort((a, b) {
                      final ta = _wrappedDelta(a.toDouble(), _page).abs();
                      final tb = _wrappedDelta(b.toDouble(), _page).abs();
                      return tb.compareTo(ta);
                    });
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: (d) =>
                        _onDragUpdate(d, _dragSpacingPx!),
                    onHorizontalDragEnd: _onDragEnd,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_ambient, _settlePop]),
                      builder: (context, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final index in order)
                            _buildScrollCard(
                              context,
                              index: index,
                              cardW: cardW,
                              cardH: cardH,
                              radius: radius,
                              activeGoal: activeGoal,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Layer 4 — 分页点浮在卷轴底部的卷杆/流苏（纯装饰、可以被压住）
          // 上，而不是画面本体上。标题/文案已经画进 describtion 版立绘
          // 本身（见 CultivationGoalTheme.cultivationScrollAsset），不再
          // 需要单独的信息卡，卷轴因此能拉满整屏高度。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _kGoalOrder.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _PageDot(active: frontIndex == i),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollCard(
    BuildContext context, {
    required int index,
    required double cardW,
    required double cardH,
    required double radius,
    required FitnessGoal? activeGoal,
  }) {
    final goal = _kGoalOrder[index];
    // t 是前弧面轮播的最短有符号步数（周期 3），越过任一端会自动从另一端
    // 接上；三幅卷轴之间保持圆柱式前弧面角度。
    final t = _wrappedDelta(index.toDouble(), _page);
    final theta = t * _kAnglePerStep;
    final isFront = t.abs() < 0.02;
    // 标记的是「当前选择的策略」（用户档案里的目标），不是「轮播当前转到
    // 谁面前」——哪怕把这幅卷轴滑到一边，只要它是已选策略，横线也要跟着。
    final isSelected = goal == activeGoal;
    // 圆柱前弧面的深度同时控制缩放、呼吸浮动和边缘淡出；到 ±90° 时
    // 卷轴几乎不可见，因此跨过循环边界不会显得像瞬移。
    final depthFactor = (math.cos(theta).clamp(0.0, 1.0)).toDouble();
    final opacity = ui.lerpDouble(_kMinOpacity, 1.0, depthFactor)!;

    // 呼吸浮动：越靠近中央幅度越明显（~5s 周期）。
    final breathPhase = _ambient.value * 2 * math.pi * 4;
    final floatY =
        math.sin(breathPhase + index * 1.7) * 5.0 * (0.25 + depthFactor * 0.75);

    final popScale = isFront ? (0.96 + 0.04 * _settlePop.value) : 1.0;
    // 只取圆柱朝向用户的前弧面：x 沿弧线移动，z 只做很小的景深变化。
    // 中央卷轴额外保持最大比例，确保视觉上最近；三张卷轴始终在屏幕这一侧。
    final x = radius * math.sin(theta);
    final z = -radius * 0.34 * math.cos(theta);
    final arcScale = ui.lerpDouble(0.76, 1.0, depthFactor)!;

    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, floatY),
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 已选策略标记：只有用户档案里已选目标对应的那幅卷轴
                    // 才会用到这枚徽记，其余两幅永远不会出现；而且只在它
                    // 转回正对玩家时才显现，一滑走失焦就淡出——不是常驻
                    // 标签。放在 3D 变换之外，保持水平、不随卷轴旋转。
                    if (isSelected) ...[
                      _SelectedMark(
                        visible: isFront,
                        color: goal.cultivationAccentColor,
                        width: cardW * 0.25,
                      ),
                      const SizedBox(height: 10),
                    ],
                    // 显式写入前弧面坐标，避免链式 translateZ 把卷轴排成
                    // 闭合圆柱；卷轴本身仍绕 Y 轴旋转并保持切线朝向。
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _kPerspective)
                        ..rotateY(theta)
                        ..setTranslationRaw(x, 0.0, z)
                        ..scaleByDouble(
                          arcScale * popScale,
                          arcScale * popScale,
                          arcScale * popScale,
                          1,
                        ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isFront) {
                            context.push(
                              '/profile/cultivation/goal/${goal.name}',
                            );
                          } else {
                            _springTo(_page + t);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isFront) ...[
                              // 柔和的目标色辉光——东方幻想的「灵气」，不是
                              // 霓虹描边。
                              Container(
                                width: cardH * 0.38,
                                height: cardH * 0.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: goal.cultivationAccentColor
                                          .withValues(alpha: 0.32),
                                      blurRadius: 100,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              // 实体投影——比辉光更「压得住」的接触阴影，让中央
                              // 卷轴明确浮在两侧卷轴前面，而不只是「更大更亮」。
                              Container(
                                width: cardW * 0.7,
                                height: cardH * 0.94,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      blurRadius: 46,
                                      spreadRadius: -6,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(
                              height: cardH,
                              width: cardW,
                              child: Image.asset(
                                goal.cultivationScrollAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已选策略的印记：一枚小圆牌 + 对勾，呼应卷轴画面里本来就有的朱红印章，
/// 而不是网页式的胶囊标签。[visible] 为 false 时（卷轴滑离焦点）淡出+
/// 缩小，而不是直接消失，避免生硬跳变。
class _SelectedMark extends StatelessWidget {
  const _SelectedMark({
    required this.visible,
    required this.color,
    required this.width,
  });

  final bool visible;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: visible ? 1 : 0,
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          // 画轴素材左右透明边距略有差异，向左做很小的视觉中心校正。
          offset: Offset(-width * 0.08, 0),
          child: Container(
            width: width,
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.65),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.9 : 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// 一粒环境粒子（尘埃或花瓣）的静态参数，由固定种子生成，保证跨帧稳定
/// （不是每帧重新随机）。[_ParticlePainter] 按 [t]（0..1 循环）把它换算成
/// 屏幕坐标。
class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.sway,
    required this.isPetal,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final double sway;
  final bool isPetal;

  factory _Particle.random(math.Random r) {
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: r.nextBool() ? 1.5 + r.nextDouble() * 2 : 4 + r.nextDouble() * 4,
      speed: 0.35 + r.nextDouble() * 0.5,
      phase: r.nextDouble() * 2 * math.pi,
      sway: 8 + r.nextDouble() * 16,
      isPetal: r.nextDouble() < 0.3,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.accent,
  });

  final List<_Particle> particles;
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // 缓慢向上漂移，越过顶部后从底部循环出现。
      final travel = (p.y - t * p.speed) % 1.0;
      final dy = travel * size.height;
      final sway = math.sin(t * 2 * math.pi * p.speed * 3 + p.phase) * p.sway;
      final dx = (p.x * size.width + sway).clamp(0.0, size.width);
      final fade = (math.sin(travel * math.pi)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (p.isPetal ? accent : Colors.white).withValues(
          alpha: (p.isPetal ? 0.3 : 0.4) * fade,
        );
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accent != accent;
}
