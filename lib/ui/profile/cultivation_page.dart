import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cultivation.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import 'cultivation_labels.dart';

/// 「我的境界」入口：始终展示当前用户所选目标（减脂/增肌/维持）对应的
/// 境界体系（[CultivationGoalScreen]）；用户尚未建立档案（选目标）时展示
/// 通用的 [_CultivationLockedView]。三大体系互不打扰——切换目标会自动
/// 切换到相应的画轴，见 [CultivationGoalPickerPage]。
class CultivationPage extends ConsumerWidget {
  const CultivationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(profileProvider)?.goal;
    if (goal == null) return const _CultivationLockedView(targetGoal: null);
    return CultivationGoalScreen(goal: goal);
  }
}

/// 某一个目标体系的境界页：仅当 [goal] 与用户当前所选目标一致时展示真实
/// 内容（减脂 = 完整修仙玩法；增肌/维持 = 玩法尚在设计中的占位页），否则展示
/// 该目标专属美术的「尚未开启」页。由 [CultivationPage]（当前目标）与
/// [CultivationGoalPickerPage]（画轴选择页，可能点进非当前目标）共用。
class CultivationGoalScreen extends ConsumerWidget {
  const CultivationGoalScreen({super.key, required this.goal});

  final FitnessGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoal = ref.watch(profileProvider)?.goal;
    if (activeGoal != goal) return _CultivationLockedView(targetGoal: goal);
    return switch (goal) {
      FitnessGoal.cut => const _CultivationHome(),
      FitnessGoal.bulk ||
      FitnessGoal.maintain => _CultivationComingSoonHome(goal: goal),
    };
  }
}

class _CultivationHome extends ConsumerStatefulWidget {
  const _CultivationHome();

  @override
  ConsumerState<_CultivationHome> createState() => _CultivationHomeState();
}

class _CultivationHomeState extends ConsumerState<_CultivationHome> {
  bool _collapsed = false;

  void _toggle() => setState(() => _collapsed = !_collapsed);

  void _onDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v > 150) setState(() => _collapsed = true);
    if (v < -150) setState(() => _collapsed = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = ref.watch(cultivationProgressProvider);
    final stepsKcal = stepsToKcal(
      ref.watch(cultivationStepsTodayProvider).value ?? 0,
    );
    final dietKcal = ref.watch(cultivationDietKcalTodayProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        // 境界详情是从画轴选择流进入的，退出时直接回到 Me，
        // 不再返回画轴选择页和境界主页。
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(l10n.cultivationPageTitle),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            progress.realm.artAsset(progress.layer),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.4),
          ),
          // Scrim so the white back button / title stay legible over a
          // light sky regardless of which realm's art is behind them.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kToolbarHeight + MediaQuery.paddingOf(context).top + 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.6, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            // Clear the AppBar's own hit-test area (it still absorbs taps
            // across its full height while transparent) — anchor to the
            // real status-bar inset rather than a guessed constant, or taps
            // near the top of the first icon land on the AppBar instead.
            top: kToolbarHeight + MediaQuery.paddingOf(context).top + 12,
            right: 14,
            child: Column(
              children: [
                _SideAction(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.cultivationSideHistory,
                  onTap: () => context.push('/profile/cultivation/history'),
                ),
                const SizedBox(height: 12),
                _SideAction(
                  icon: Icons.emoji_events_outlined,
                  label: l10n.cultivationSideRealmGuide,
                  onTap: () => context.push('/profile/cultivation/realm-guide'),
                ),
                const SizedBox(height: 12),
                _SideAction(
                  icon: Icons.settings_outlined,
                  label: l10n.cultivationSideSettings,
                  onTap: () => context.push('/profile/cultivation/settings'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onVerticalDragEnd: _onDragEnd,
              child: _RealmPanel(
                collapsed: _collapsed,
                progress: progress,
                stepsKcal: stepsKcal,
                dietKcal: dietKcal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white70, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: const Color(0xFF1B2A24)),
          ),
        ),
      ),
    );
  }
}

class _RealmPanel extends StatelessWidget {
  const _RealmPanel({
    required this.collapsed,
    required this.progress,
    required this.stepsKcal,
    required this.dietKcal,
  });

  final bool collapsed;
  final CultivationProgress progress;
  final double stepsKcal;
  final double dietKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final realm = progress.realm;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: collapsed ? const Offset(0, 1) : Offset.zero,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A24).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              l10n.cultivationLayerBadge(
                realm.label(l10n),
                '${progress.layer}',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: realm.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= kCultivationLayers; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  _LayerDot(
                    state: i < progress.layer
                        ? _DotState.done
                        : i == progress.layer
                        ? _DotState.current
                        : _DotState.future,
                    color: realm.textColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (progress.isMax) ...[
              Text(
                l10n.cultivationMaxCaption,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cultivationMaxSubcaption(formatKg(progress.kgLost)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1B2A24).withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFF1B2A24).withValues(alpha: 0.10),
                      ),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: progress.layerProgress.clamp(0.0, 1.0),
                        child: ColoredBox(color: realm.textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress.layer >= kCultivationLayers && realm.next != null
                    ? l10n.cultivationNextRealmCaption(
                        formatKcal(progress.kcalToNextRealm ?? 0),
                        realm.next!.label(l10n),
                      )
                    : l10n.cultivationNextLayerCaption(
                        formatKcal(progress.kcalToNextLayer ?? 0),
                      ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cultivationLostCaption(formatKg(progress.kgLost)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1B2A24).withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF1B2A24).withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 14,
                    color: const Color(0xFF1B2A24).withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.cultivationStepsContribution(
                      formatSignedKcal(stepsKcal),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF1B2A24).withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.restaurant_outlined,
                    size: 14,
                    color: const Color(0xFF1B2A24).withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.cultivationDietContribution(
                      formatSignedKcal(dietKcal),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF1B2A24).withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DotState { done, current, future }

class _LayerDot extends StatelessWidget {
  const _LayerDot({required this.state, required this.color});

  final _DotState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (state == _DotState.current) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      );
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _DotState.done
            ? color
            : const Color(0xFF1B2A24).withValues(alpha: 0.14),
      ),
    );
  }
}

/// 境界修行「尚未开启」页。[targetGoal] 为 null 时用于用户尚未建立档案
/// （从未选过任何目标）的通用场景，沿用原有减脂向文案与背景；不为 null
/// 时用于从 [CultivationGoalPickerPage] 点进一个与当前目标不同的画轴，
/// 展示该目标专属美术 + 「当前你的目标是 X，Y 境界修行只对选择 Y 目标的
/// 用户开放」的说明。
class _CultivationLockedView extends ConsumerWidget {
  const _CultivationLockedView({required this.targetGoal});

  final FitnessGoal? targetGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goal = targetGoal;
    final activeGoal = ref.watch(profileProvider)?.goal;
    final bgAsset =
        goal?.cultivationBackgroundAsset ?? 'assets/cultivation/locked_bg.jpg';
    final titleText = goal == null
        ? l10n.cultivationLockedTitle
        : l10n.cultivationGoalLockedTitle(goal.label(l10n));
    final bodyText = goal == null
        ? l10n.cultivationLockedBody
        : l10n.cultivationGoalLockedBody(
            goal.label(l10n),
            activeGoal?.label(l10n) ?? '—',
          );
    final ctaText = goal == null
        ? l10n.cultivationLockedCta
        : l10n.cultivationGoalLockedCta;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(goal?.label(l10n) ?? l10n.cultivationPageTitle),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.15),
            colorBlendMode: BlendMode.darken,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kToolbarHeight + MediaQuery.paddingOf(context).top + 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.6, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 30,
                      color: Color(0xFF5C6B65),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bodyText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: () => GoRouter.of(context).push('/profile/edit'),
                    child: Text(ctaText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 增肌/维持境界的占位主页：目标已生效（用户当前就是这个目标），但具体
/// 修为换算与境界体系还在设计中（见对话记录 —— 用户明确表示先只做 UI）。
/// 展示该目标专属美术 + 「打磨中」文案 + 齿轮入口，其余（历史/境界体系）
/// 按钮暂不展示，因为对应玩法尚不存在。
class _CultivationComingSoonHome extends StatelessWidget {
  const _CultivationComingSoonHome({required this.goal});

  final FitnessGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(goal.label(l10n)),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(goal.cultivationBackgroundAsset, fit: BoxFit.cover),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kToolbarHeight + MediaQuery.paddingOf(context).top + 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.6, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight + MediaQuery.paddingOf(context).top + 12,
            right: 14,
            child: _SideAction(
              icon: Icons.settings_outlined,
              label: l10n.cultivationSideSettings,
              onTap: () => context.push('/profile/cultivation/settings'),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cultivationComingSoonTitle(goal.label(l10n)),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: goal.cultivationAccentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cultivationComingSoonBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1B2A24).withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
