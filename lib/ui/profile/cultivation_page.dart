import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cultivation.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import 'cultivation_labels.dart';

/// 「我的境界」详情页：练气/筑基/结丹/元婴/化神，5 大境界 × 9 层，
/// 由累计减重换算修为进度。仅对选择「减脂」目标的用户开放
/// （[cultivationEligibleProvider] 为 false 时展示 [_CultivationLockedView]）。
class CultivationPage extends ConsumerWidget {
  const CultivationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(cultivationEligibleProvider);
    if (!eligible) return const _CultivationLockedView();
    return const _CultivationHome();
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

class _CultivationLockedView extends StatelessWidget {
  const _CultivationLockedView();

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
            'assets/cultivation/locked_bg.jpg',
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
                    l10n.cultivationLockedTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.cultivationLockedBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: () => GoRouter.of(context).push('/profile/edit'),
                    child: Text(l10n.cultivationLockedCta),
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
