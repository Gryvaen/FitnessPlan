import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/calendar_day.dart';
import '../../domain/maintain.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import 'strategy_target_card.dart';

/// 维持 tab body while the profile goal is maintain, laid out exactly like
/// the cut tab with its one default strategy, 均衡维持:
///
/// | cut tab                         | maintain tab                     |
/// |---------------------------------|----------------------------------|
/// | overview「碳循环 · 第 N 版」     | overview「均衡维持 · 第 N 天」    |
/// | strategy section (循环安排)      | strategy section (体重)          |
/// | 本版策略基准 + facts             | 策略基准 + facts                  |
/// | TDEE 计算方法                    | TDEE 计算方法                     |
/// | 管理 (更换 / 停用)               | 管理 (按当前体重重算)             |
///
/// There is nothing to choose or stop: switching the goal is the switch.
class MaintainTargetsView extends ConsumerWidget {
  const MaintainTargetsView({
    super.key,
    required this.profile,
    required this.tdeeTile,
  });

  final UserProfile profile;

  /// The shared "TDEE 计算方法" row, in the same slot as on the cut tab.
  final Widget tdeeTile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final today = CalendarDay.todayLocal();
    final since = profile.calorieStandardSince;
    final t = profile.targets;
    final band = maintainBand(t.calories.toDouble());
    final day = since == null ? null : today.difference(since).inDays + 1;
    final sinceLabel = since == null ? null : AppDates.md(since, locale);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.compact,
        AppSpacing.formPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        StrategyTargetCard(
          key: const ValueKey('maintainOverview'),
          title: day == null || day < 1
              ? l10n.maintainStrategyName
              : l10n.maintainTitleDay(day),
          status: l10n.strategyStatusActive,
          kcal: t.calories.toDouble(),
          kcalCaption: l10n.everyDayCaption,
          proteinG: t.proteinG,
          carbG: t.carbG,
          fatG: t.fatG,
          footnote: sinceLabel == null
              ? l10n.maintainBandShort(band.low.round(), band.high.round())
              : l10n.maintainFootnote(
                  band.low.round(),
                  band.high.round(),
                  sinceLabel,
                ),
        ),
        _WeightStability(since: since),
        MaintainBasisSection(targets: t, profile: profile),
        tdeeTile,
        StrategySectionHeader(title: l10n.strategyManageTitle),
        // Same slot as the cut tab's 调整策略: straight to the configure page.
        StrategyActionRow(
          key: const ValueKey('maintainAdjustStrategy'),
          icon: InkGlyph.edit,
          label: l10n.adjustStrategy,
          onTap: () => context.push('/profile/nutrition/maintain/configure'),
        ),
        // Same slot as the cut tab's 更换策略: the picker → configure page,
        // where the protein rate can be changed.
        StrategyActionRow(
          key: const ValueKey('maintainChangeStrategy'),
          icon: InkGlyph.swapHorizontal,
          label: l10n.changeStrategy,
          onTap: () => context.push('/profile/nutrition/maintain'),
        ),
        _RecalculateRow(profile: profile),
      ],
    );
  }
}

/// 7-day average weight and its change since maintenance began.
class _WeightStability extends ConsumerWidget {
  const _WeightStability({required this.since});

  final DateTime? since;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final logs = <(DateTime, double)>[
      for (final w in ref.watch(weightLogsProvider).value ?? const [])
        (w.date, w.weightKg),
    ];
    final today = CalendarDay.todayLocal();
    final recent = recentWeightAverage(logs, today: today);
    // On the start day both windows are the same week, so the change is
    // always 0 — only show it from the second day on.
    final start = since == null || !since!.isBefore(today) ? null : since;
    final baseline = start == null
        ? null
        : maintainBaselineWeight(logs, since: start);
    final delta = recent != null && baseline != null ? recent - baseline : null;

    String kg(double v) => v.toStringAsFixed(1);
    String signed(double v) {
      final r = (v * 10).round() / 10;
      if (r == 0) return '0.0';
      return '${r > 0 ? '+' : '−'}${kg(r.abs())}';
    }

    return Column(
      key: const ValueKey('maintainWeight'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StrategySectionHeader(
          title: l10n.maintainWeightTitle,
          hint: l10n.maintainWeightHint,
        ),
        if (recent == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.field),
            child: Text(l10n.maintainWeightTooFew, style: theme.textTheme.meta),
          )
        else ...[
          StrategyFactRow(
            label: l10n.maintainWeightAvg7,
            value: kg(recent),
            unit: 'kg',
          ),
          if (delta != null)
            StrategyFactRow(
              key: const ValueKey('maintainWeightDelta'),
              label: l10n.maintainWeightVsStart,
              value: signed(delta),
              unit: 'kg',
            ),
        ],
      ],
    );
  }
}

/// 策略基准: what the maintenance target is computed from, mirroring the cut
/// tab's「本版策略基准」rows. Shared by the 维持 tab (the fixed target) and
/// its switch preview (what switching now would fix).
class MaintainBasisSection extends StatelessWidget {
  const MaintainBasisSection({
    super.key = const ValueKey('maintainBasis'),
    required this.targets,
    required this.profile,
  });

  final MacroTargets targets;

  /// Weight and TDEE are read from the profile as they are now (weigh-ins
  /// move them), even though the maintenance target stays fixed until it is
  /// recalculated.
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = targets;
    final band = maintainBand(t.calories.toDouble());
    final basisWeight = profile.weightKg;
    // Maintenance = TDEE − plateau trim; fall back to that without a TDEE.
    final basisTdee =
        profile.tdee?.round() ?? t.calories + profile.calorieAdjustment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StrategySectionHeader(
          title: l10n.maintainBasisTitle,
          hint: l10n.maintainStrategyDescription,
        ),
        StrategyFactRow(
          label: l10n.referenceWeightKg,
          value: basisWeight.toStringAsFixed(1),
          unit: 'kg',
        ),
        StrategyFactRow(
          label: l10n.estimatedTdee,
          value: '$basisTdee',
          unit: 'kcal',
        ),
        StrategyFactRow(
          label: l10n.maintainKcalLabel,
          value: '${t.calories}',
          unit: 'kcal',
        ),
        StrategyFactRow(
          label: l10n.maintainBandLabel,
          value: l10n.maintainBandValue(
            band.low.round(),
            band.high.round(),
            (maintainBandFraction * 100).round(),
          ),
        ),
      ],
    );
  }
}

/// 管理: re-fix the target from the current weight (weigh-ins never change it
/// on their own). Disabled when it would come out the same.
class _RecalculateRow extends ConsumerWidget {
  const _RecalculateRow({required this.profile});

  final UserProfile profile;

  Future<void> _recalculate(
    BuildContext context,
    WidgetRef ref, {
    required int from,
    required int to,
  }) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.maintainRecalc),
        content: Text(l10n.maintainRecalcBody(from, to)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final updated = await ref
        .read(profileProvider.notifier)
        .recalculateMaintenance();
    if (!context.mounted || updated == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.maintainRecalcDone(updated.targets.calories)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = profile.targets.calories;
    // What an explicit save would fix now (includes any plateau trim).
    final byWeight = ref
        .read(profileRepositoryProvider)
        .buildPlan(profile)
        .targets
        .calories;
    return StrategyActionRow(
      key: const ValueKey('maintainRecalc'),
      icon: InkGlyph.calculator,
      label: l10n.maintainRecalc,
      onTap: byWeight != current
          ? () => _recalculate(context, ref, from: current, to: byWeight)
          : null,
    );
  }
}

/// 维持 tab while a switch to maintain is booked for a later day: the same
/// skeleton as a scheduled fat-loss strategy (status 待生效, first-day
/// caption), the basis it would fix from the current profile, the TDEE row,
/// and 管理 with 取消预约切换.
class MaintainScheduledView extends ConsumerWidget {
  const MaintainScheduledView({
    super.key,
    required this.profile,
    required this.from,
    required this.tdeeTile,
  });

  final UserProfile profile;

  /// The booked first day on maintain.
  final DateTime from;
  final Widget tdeeTile;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final date = AppDates.md(from, Localizations.localeOf(context));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelScheduledStrategy),
        content: Text(l10n.maintainCancelScheduledBody(date)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelScheduledStrategy),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(pendingGoalSwitchProvider.notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.scheduledStrategyCancelled)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final t = ref
        .read(profileRepositoryProvider)
        .buildPlan(profile.copyWith(goal: FitnessGoal.maintain))
        .targets;
    final band = maintainBand(t.calories.toDouble());
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.formPage,
        AppSpacing.compact,
        AppSpacing.formPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        StrategyTargetCard(
          key: const ValueKey('maintainScheduledOverview'),
          title: l10n.maintainStrategyName,
          status: l10n.strategyStatusScheduled,
          kcal: t.calories.toDouble(),
          kcalCaption: l10n.firstDayCaption(AppDates.md(from, locale)),
          proteinG: t.proteinG,
          carbG: t.carbG,
          fatG: t.fatG,
          footnote: l10n.maintainBandShort(band.low.round(), band.high.round()),
        ),
        MaintainBasisSection(targets: t, profile: profile),
        tdeeTile,
        StrategySectionHeader(title: l10n.strategyManageTitle),
        // Same order as a scheduled fat-loss strategy: 调整 / 更换 / 取消预约.
        StrategyActionRow(
          key: const ValueKey('maintainScheduledAdjust'),
          icon: InkGlyph.edit,
          label: l10n.adjustStrategy,
          onTap: () => context.push('/profile/nutrition/maintain/configure'),
        ),
        StrategyActionRow(
          key: const ValueKey('maintainScheduledChange'),
          icon: InkGlyph.swapHorizontal,
          label: l10n.changeStrategy,
          onTap: () => context.push('/profile/nutrition/maintain'),
        ),
        StrategyActionRow(
          key: const ValueKey('maintainCancelScheduled'),
          icon: InkGlyph.stop,
          label: l10n.cancelScheduledStrategy,
          destructive: true,
          showChevron: false,
          onTap: () => _cancel(context, ref),
        ),
      ],
    );
  }
}
