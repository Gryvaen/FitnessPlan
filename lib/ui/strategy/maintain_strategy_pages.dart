import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/goal_schedule_repository.dart';
import '../../domain/calendar_day.dart';
import '../../domain/maintain.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../profile/goal_switch.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'stepper_row.dart';
import 'strategy_fold_section.dart';
import 'strategy_target_card.dart';

/// Profile → Nutrition → 维持 → 选择策略: the maintain counterpart of the
/// fat-loss picker, with its one default strategy, 均衡维持.
class MaintainStrategyPickerPage extends ConsumerWidget {
  const MaintainStrategyPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(profileProvider)?.goal == FitnessGoal.maintain;
    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.maintainStrategyTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          StrategyOptionRow(
            optionKey: const ValueKey('strategy-option-maintain'),
            glyph: InkGlyph.target,
            label: l10n.maintainStrategyName,
            description: l10n.maintainStrategyDescription,
            current: current,
            isDefault: true,
            enabled: true,
            onTap: () => context.push('/profile/nutrition/maintain/configure'),
          ),
        ],
      ),
    );
  }
}

/// 均衡维持 configure page, laid out like the fat-loss one: preview overview,
/// then the folded 当前档案 / 目标与营养 / 生效日期 rows (all closed at first),
/// the disclaimer and the pinned apply bar. The protein and fat rates
/// (目标与营养) and the start day are adjustable. Applying switches the goal to maintain —
/// today right away, or booked for tomorrow (carried out by
/// `applyDueGoalSwitch`). While already maintaining, a new rate applies today
/// and re-fixes the target from the current profile.
class MaintainStrategyConfigurePage extends ConsumerStatefulWidget {
  const MaintainStrategyConfigurePage({super.key});

  @override
  ConsumerState<MaintainStrategyConfigurePage> createState() =>
      _MaintainStrategyConfigurePageState();
}

enum _MaintainSection { profile, target, effective }

class _MaintainStrategyConfigurePageState
    extends ConsumerState<MaintainStrategyConfigurePage> {
  bool _saving = false;

  /// Same default as the fat-loss configure page: start tomorrow.
  bool _startToday = false;
  final Set<_MaintainSection> _open = {};

  /// Protein and fat g/kg being configured; start from the profile's.
  double? _protein;
  double? _fat;

  DateTime get _tomorrow => CalendarDay.addDays(CalendarDay.todayLocal(), 1);

  /// Already maintaining: only a rate change can be applied, and it applies
  /// today (there is no goal switch to book).
  bool get _maintaining =>
      ref.read(profileProvider)?.goal == FitnessGoal.maintain;

  DateTime get _from =>
      _startToday || _maintaining ? CalendarDay.todayLocal() : _tomorrow;

  static bool _sameRate(double a, double b) =>
      (a * 10).round() == (b * 10).round();

  Widget _section(
    _MaintainSection section, {
    required String title,
    required String summary,
    required InkGlyph icon,
    required Widget child,
  }) => StrategyFoldSection(
    key: ValueKey('maintain-section-${section.name}'),
    title: title,
    summary: summary,
    expanded: _open.contains(section),
    onTap: () => setState(() {
      if (!_open.remove(section)) _open.add(section);
    }),
    leading: icon,
    child: child,
  );

  /// Already maintaining: re-fix the target with the new rates.
  Future<void> _applyRates(double protein, double fat) async {
    final l10n = context.l10n;
    final p = ref.read(profileProvider)!;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(profileProvider.notifier)
          .save(
            sex: p.sex,
            age: p.age,
            heightCm: p.heightCm,
            weightKg: p.weightKg,
            activity: p.activity,
            goal: p.goal,
            targetWeightKg: p.targetWeightKg,
            calorieAdjustment: p.calorieAdjustment,
            maintainProteinPerKg: protein,
            maintainFatPerKg: fat,
          );
      messenger.showSnackBar(SnackBar(content: Text(l10n.strategyApplied)));
      if (mounted) context.go('/profile');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _apply() async {
    if (_saving) return;
    final protein = _protein!;
    final fat = _fat!;
    if (_maintaining) return _applyRates(protein, fat);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final from = _from;
    final today = !from.isAfter(CalendarDay.todayLocal());
    final dateLabel = AppDates.md(from, locale);
    if (!await confirmGoalSwitch(
          context,
          ref,
          FitnessGoal.maintain,
          leadLine: today ? null : l10n.switchGoalFrom(dateLabel),
        ) ||
        !mounted) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (today) {
        await switchGoal(
          ref,
          FitnessGoal.maintain,
          maintainProteinPerKg: protein,
          maintainFatPerKg: fat,
        );
        messenger.showSnackBar(SnackBar(content: Text(l10n.strategyApplied)));
      } else {
        await ref
            .read(pendingGoalSwitchProvider.notifier)
            .schedule(
              PendingGoalSwitch(
                goal: FitnessGoal.maintain,
                from: from,
                proteinPerKg: protein,
                fatPerKg: fat,
              ),
            );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.goalSwitchScheduled(
                dateLabel,
                FitnessGoal.maintain.label(l10n),
              ),
            ),
          ),
        );
      }
      if (mounted) context.go('/profile');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final pending = ref.watch(pendingGoalSwitchProvider);
    if (profile == null) {
      return AppChromeScaffold(
        appBar: AppBar(title: Text(l10n.maintainStrategyName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final maintaining = profile.goal == FitnessGoal.maintain;
    // A booked switch opens with the rates it was booked with.
    final booked = !maintaining && pending?.goal == FitnessGoal.maintain
        ? pending
        : null;
    final protein = _protein ??=
        booked?.proteinPerKg ?? profile.maintainProteinPerKg;
    final fat = _fat ??= booked?.fatPerKg ?? profile.maintainFatPerKg;
    // Nothing new to apply while maintaining at the same rates.
    final applied =
        maintaining &&
        _sameRate(protein, profile.maintainProteinPerKg) &&
        _sameRate(fat, profile.maintainFatPerKg);
    final scheduled =
        !maintaining &&
        pending?.goal == FitnessGoal.maintain &&
        CalendarDay.dayOnly(pending!.from) == _from &&
        _sameRate(
          protein,
          pending.proteinPerKg ?? profile.maintainProteinPerKg,
        ) &&
        _sameRate(fat, pending.fatPerKg ?? profile.maintainFatPerKg);
    // While maintaining unchanged, show the fixed target; otherwise what
    // applying would fix from the current profile at the chosen rate.
    final plan = ref
        .read(profileRepositoryProvider)
        .buildPlan(
          profile.copyWith(
            goal: FitnessGoal.maintain,
            maintainProteinPerKg: protein,
            maintainFatPerKg: fat,
          ),
        );
    final t = applied ? profile.targets : plan.targets;
    final band = maintainBand(t.calories.toDouble());
    final weight = profile.weightKg;
    // Weight and TDEE of the current profile, from the same computation as
    // the previewed target.
    final tdee = plan.tdee.round();
    final pct = (maintainBandFraction * 100).round();
    final tomorrowLabel = l10n.startTomorrow(AppDates.md(_tomorrow, locale));

    return AppChromeScaffold(
      appBar: AppBar(
        title: Text(l10n.maintainStrategyName),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      bottomNavigationBar: StrategyApplyBar(
        label: applied
            ? l10n.strategyAlreadyApplied
            : scheduled
            ? l10n.strategyAlreadyScheduled
            : l10n.applyStrategyFrom(AppDates.md(_from, locale)),
        onPressed: applied || scheduled || _saving ? null : _apply,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          StrategyTargetCard(
            key: const ValueKey('maintainConfigureOverview'),
            title: l10n.maintainStrategyName,
            status: l10n.strategyStatusPreview,
            kcal: t.calories.toDouble(),
            kcalCaption: l10n.everyDayCaption,
            proteinG: t.proteinG,
            carbG: t.carbG,
            fatG: t.fatG,
            footnote: l10n.planBaselineLine(
              weight.toStringAsFixed(1),
              '$tdee',
              '${t.calories}',
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _section(
            _MaintainSection.profile,
            title: l10n.strategyCurrentProfile,
            summary: '${weight.toStringAsFixed(1)} kg · $tdee kcal',
            icon: InkGlyph.profile,
            child: Column(
              children: [
                StrategyReadOnlyMetric(
                  label: l10n.referenceWeightKg,
                  value: weight.toStringAsFixed(1),
                  unit: 'kg',
                ),
                StrategyReadOnlyMetric(
                  label: l10n.estimatedTdee,
                  value: '$tdee',
                  unit: 'kcal',
                ),
              ],
            ),
          ),
          _section(
            _MaintainSection.target,
            title: l10n.strategyGoalRates,
            summary: l10n.maintainRatesSummary(pct, t.calories),
            icon: InkGlyph.target,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrategyReadOnlyMetric(
                  label: l10n.maintainKcalLabel,
                  value: '${t.calories}',
                  unit: 'kcal',
                ),
                StrategyReadOnlyMetric(
                  label: l10n.maintainBandLabel,
                  value: '${band.low.round()}–${band.high.round()}',
                  unit: 'kcal',
                ),
                StepperRow(
                  label: l10n.proteinPerKgLabel,
                  value: protein,
                  min: MaintainProtein.minPerKg,
                  max: MaintainProtein.maxPerKg,
                  step: 0.1,
                  unit: 'g/kg',
                  onChanged: (v) => setState(() => _protein = v),
                ),
                StepperRow(
                  label: l10n.fatPerKgLabel,
                  value: fat,
                  min: MaintainFat.minPerKg,
                  max: MaintainFat.maxPerKg,
                  step: 0.1,
                  unit: 'g/kg',
                  onChanged: (v) => setState(() => _fat = v),
                ),
                const SizedBox(height: AppSpacing.compact),
                Text(
                  l10n.maintainStrategyDescription,
                  style: theme.textTheme.meta,
                ),
              ],
            ),
          ),
          _section(
            _MaintainSection.effective,
            title: l10n.effectiveDate,
            summary: _startToday || maintaining
                ? l10n.startToday
                : tomorrowLabel,
            icon: InkGlyph.calendar,
            child: Column(
              children: [
                // Already maintaining: a rate change can only start today.
                if (!maintaining)
                  StrategyDateOption(
                    label: tomorrowLabel,
                    selected: !_startToday,
                    onTap: () => setState(() => _startToday = false),
                  ),
                StrategyDateOption(
                  label: l10n.startToday,
                  selected: _startToday || maintaining,
                  onTap: () => setState(() => _startToday = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(l10n.strategyDisclaimer, style: theme.textTheme.meta),
        ],
      ),
    );
  }
}
