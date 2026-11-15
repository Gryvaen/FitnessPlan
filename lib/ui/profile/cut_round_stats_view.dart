import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/workout_repository.dart';
import '../../domain/cut_cultivation.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/folded_notes.dart';
import '../widgets/form_options.dart'
    as gym
    show FormOptions, GymWeightUnit, formatKg;
import 'cultivation_labels.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Width of each right-aligned number column in the plan / exercise lists,
/// so every row's figures line up.
const _numberColumnWidth = 64.0;

/// 训练 → 历史 → 「统计」: the cut round's totals, one themed block each —
/// steps, training, diet, weight — then plans and exercises counted by name.
class CutRoundStatsView extends ConsumerWidget {
  const CutRoundStatsView({super.key, required this.segment});

  final CutCultivationSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = (start: segment.start, end: segment.end);
    final async = ref.watch(cutRoundStatsProvider(range));
    final stats = async.value;
    if (stats == null) {
      if (async.hasError) {
        return SportLoadError(
          onRetry: () => ref.invalidate(cutRoundStatsProvider(range)),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final number = NumberFormat.decimalPattern(locale.toString());
    final divider = AppThemeVisuals.of(context).divider;
    final training = stats.training;
    final planSessions = training.plans.fold<int>(0, (s, p) => s + p.count);

    final blocks = <Widget>[
      // Header
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cultivationHistorySegmentCurrent(
                AppDates.md(segment.start, locale),
              ),
              style: theme.textTheme.subsectionTitle,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cutRoundDayN('${stats.dayCount}'),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ),
      FoldedNotes(
        title: l10n.cutRoundRulesTitle,
        notes: [
          l10n.cutRoundRule1,
          l10n.cutRoundRule2,
          l10n.cutRoundRule3,
          l10n.cutRoundRule4,
          l10n.cutRoundRule5,
          l10n.cutRoundRule6,
          l10n.cutRoundRule7,
          l10n.cutRoundRule8,
          l10n.cutRoundRule9,
        ],
      ),
      _Block(
        glyph: InkGlyph.walk,
        color: AppColors.water,
        title: l10n.cutRoundStepsTitle,
        child: _MetricPair(
          left: _Metric(
            label: l10n.cutRoundTotalSteps,
            value: number.format(stats.steps),
            unit: l10n.unitSteps,
          ),
          right: _Metric(
            label: l10n.cutRoundAvgSteps,
            value: number.format(stats.avgSteps),
            unit: l10n.unitSteps,
          ),
        ),
      ),
      _Block(
        glyph: InkGlyph.training,
        color: AppColors.protein,
        title: l10n.cutRoundTrainingTitle,
        child: _MetricPair(
          left: _Metric(
            label: l10n.cutRoundTrainingDays,
            value: '${training.trainingDays}',
            unit: l10n.unitDays,
          ),
          right: _Metric(
            label: l10n.cutRoundPlanSessions,
            value: '$planSessions',
            unit: l10n.unitTimes,
          ),
        ),
      ),
      _Block(
        glyph: InkGlyph.food,
        color: AppColors.carb,
        title: l10n.cutRoundDietTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPair(
              left: _Metric(
                label: l10n.cutRoundDietOnTarget,
                value: '${stats.dietMetDays}',
                unit: l10n.unitDays,
                color: AppColors.success,
              ),
              right: _Metric(
                label: l10n.cutRoundDietOver,
                value: '${stats.dietMissedDays}',
                unit: l10n.unitDays,
                color: stats.dietMissedDays > 0
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            if (stats.dietMetDays + stats.dietMissedDays > 0) ...[
              const SizedBox(height: 12),
              _RatioBar(
                good: stats.dietMetDays,
                bad: stats.dietMissedDays,
                goodColor: AppColors.success,
                badColor: theme.colorScheme.error,
              ),
            ],
          ],
        ),
      ),
      _Block(
        glyph: InkGlyph.weight,
        color: AppColors.fat,
        title: l10n.cutRoundWeightTitle,
        child: _weightBody(context, stats),
      ),
      _Block(
        glyph: InkGlyph.target,
        color: AppColors.protein,
        title: l10n.cutRoundCategoriesTitle,
        hint: l10n.cutRoundExercisesHint,
        child: training.categories.isEmpty
            ? _EmptyLine(l10n.cutRoundNoExercises)
            : _NameRows(
                rows: [
                  for (final c in _byCategoryOrder(training.categories))
                    (
                      c.name.localizedExerciseCategory(l10n),
                      [
                        l10n.cutRoundTimes('${c.count}'),
                        l10n.cutRoundSets('${c.sets}'),
                      ],
                    ),
                ],
              ),
      ),
      _Block(
        glyph: InkGlyph.playlistAdd,
        color: AppColors.protein,
        title: l10n.cutRoundPlansTitle,
        hint: l10n.cutRoundPlansHint,
        child: training.plans.isEmpty
            ? _EmptyLine(l10n.cutRoundNoPlanWorkouts)
            : _NameRows(
                rows: [
                  for (final p in training.plans)
                    (p.name, [l10n.cutRoundTimes('${p.count}')]),
                ],
              ),
      ),
      _Block(
        glyph: InkGlyph.fire,
        color: AppColors.fat,
        title: l10n.cutRoundExercisesTitle,
        hint: l10n.cutRoundExercisesHint,
        child: training.exercises.isEmpty
            ? _EmptyLine(l10n.cutRoundNoExercises)
            : _NameRows(
                rows: [
                  for (final e in training.exercises)
                    (
                      e.name,
                      [
                        l10n.cutRoundTimes('${e.count}'),
                        l10n.cutRoundSets('${e.sets}'),
                      ],
                    ),
                ],
              ),
      ),
      _Block(
        glyph: InkGlyph.trophy,
        color: AppColors.fat,
        title: l10n.cutRoundLiftsTitle,
        hint: l10n.cutRoundLiftsHint,
        child: training.lifts.isEmpty
            ? _EmptyLine(l10n.cutRoundNoLifts)
            : _LiftRows(
                lifts: [
                  // Same order as the 动作 block.
                  for (final e in training.exercises)
                    if (training.lifts[e.name] case final lift?) (e.name, lift),
                ],
              ),
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.listPage,
        AppSpacing.field,
        AppSpacing.listPage,
        listBottomInset(context, hasFab: false),
      ),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: AppSpacing.section / 2),
            Divider(height: 1, color: divider),
            const SizedBox(height: AppSpacing.section / 2),
          ],
          blocks[i],
        ],
      ],
    );
  }

  Widget _weightBody(BuildContext context, CutRoundStats stats) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trend = stats.weight;
    if (trend == null) {
      return _EmptyLine(
        stats.weightExcluded > 0
            ? l10n.cutRoundWeightAllExcluded
            : l10n.cutRoundNoWeight,
      );
    }
    String caption(int samples, String Function(String) avg) =>
        samples == 1 ? l10n.cutRoundWeightSingle : avg('$samples');
    final end = _Metric(
      label: l10n.cutRoundEndWeight,
      value: formatKg(trend.endKg),
      unit: 'kg',
      caption: caption(trend.endSamples, l10n.cutRoundWeightEndAvg),
    );
    final excludedNote = stats.weightExcluded > 0
        ? _EmptyLine(l10n.cutRoundWeightExcluded('${stats.weightExcluded}'))
        : null;
    final startKg = trend.startKg;
    if (startKg == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricPair(left: end),
          if (excludedNote != null) ...[
            const SizedBox(height: 12),
            excludedNote,
          ],
        ],
      );
    }
    final rounded = double.parse((trend.endKg - startKg).toStringAsFixed(1));
    final sign = rounded > 0 ? '+' : (rounded < 0 ? '−' : '±');
    final deltaColor = rounded < 0
        ? AppColors.success
        : rounded > 0
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricPair(
          left: _Metric(
            label: l10n.cutRoundStartWeight,
            value: formatKg(startKg),
            unit: 'kg',
            caption: caption(trend.startSamples, l10n.cutRoundWeightStartAvg),
          ),
          right: end,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.cutRoundWeightDelta('$sign${formatKg(rounded.abs())}'),
          style: theme.textTheme.bodyText?.copyWith(
            color: deltaColor,
            fontWeight: FontWeight.w600,
            fontFeatures: _tabular,
          ),
        ),
        if (excludedNote != null) ...[const SizedBox(height: 4), excludedNote],
      ],
    );
  }
}

/// [kExerciseCategoryOrder] first (胸, 背, 肩 …), anything else after.
List<ExerciseTally> _byCategoryOrder(List<ExerciseTally> categories) {
  int rank(String key) {
    final i = kExerciseCategoryOrder.indexOf(key);
    return i < 0 ? kExerciseCategoryOrder.length : i;
  }

  return [...categories]..sort((a, b) {
    final r = rank(a.name).compareTo(rank(b.name));
    return r != 0 ? r : a.name.compareTo(b.name);
  });
}

/// A themed block: icon badge + title (and an optional grey hint on the
/// right), then its content 12 below.
class _Block extends StatelessWidget {
  const _Block({
    required this.glyph,
    required this.color,
    required this.title,
    required this.child,
    this.hint,
  });

  final InkGlyph glyph;
  final Color color;
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MenuIconBadge(
              color: color,
              child: InkIcon(glyph, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: theme.textTheme.rowTitle)),
            if (hint != null)
              Flexible(
                child: Text(
                  hint!,
                  style: theme.textTheme.meta?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Two metrics side by side, each taking half the width.
class _MetricPair extends StatelessWidget {
  const _MetricPair({required this.left, this.right});

  final _Metric left;
  final _Metric? right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right ?? const SizedBox.shrink()),
      ],
    );
  }
}

/// Small grey label above a large tabular value with its unit.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
    this.caption,
  });

  final String label;
  final String value;
  final String unit;
  final Color? color;

  /// Grey note under the value, e.g. how it was averaged.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.meta?.copyWith(color: muted)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.statValue?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: _tabular,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.bodyText?.copyWith(color: muted),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: theme.textTheme.meta?.copyWith(color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Thin rounded bar split by the [good] : [bad] ratio.
class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.good,
    required this.bad,
    required this.goodColor,
    required this.badColor,
  });

  final int good;
  final int bad;
  final Color goodColor;
  final Color badColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Row(
          children: [
            if (good > 0)
              Expanded(
                flex: good,
                child: ColoredBox(color: goodColor),
              ),
            if (good > 0 && bad > 0) const SizedBox(width: 2),
            if (bad > 0)
              Expanded(
                flex: bad,
                child: ColoredBox(color: badColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Name rows with fixed-width, right-aligned figure columns, divided by
/// hairlines.
class _NameRows extends StatelessWidget {
  const _NameRows({required this.rows});

  final List<(String, List<String>)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = AppThemeVisuals.of(context).divider;
    final figureStyle = theme.textTheme.bodyText?.copyWith(
      fontFeatures: _tabular,
    );
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: divider),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: theme.textTheme.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final (j, figure) in rows[i].$2.indexed) ...[
                  if (j > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: _numberColumnWidth,
                    child: Text(
                      figure,
                      style: figureStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Each exercise's latest load, right-aligned, with when it was logged and
/// how it moved since the round's first load.
class _LiftRows extends StatelessWidget {
  const _LiftRows({required this.lifts});

  final List<(String, LiftRecord)> lifts;

  @override
  Widget build(BuildContext context) {
    final divider = AppThemeVisuals.of(context).divider;
    return Column(
      children: [
        for (var i = 0; i < lifts.length; i++) ...[
          if (i > 0) Divider(height: 1, color: divider),
          _row(context, lifts[i]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, (String, LiftRecord) entry) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final caption = theme.textTheme.meta?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final (name, lift) = entry;
    final unit = gym.GymWeightUnit.parse(lift.unit);
    final last = gym.FormOptions.fromKg(lift.lastKg, unit);
    final first = gym.FormOptions.fromKg(lift.firstKg, unit);
    final delta = ((last - first) * 100).round() / 100;
    final moved = lift.firstDay != lift.lastDay && delta != 0;
    final sign = delta > 0 ? '+' : '−';
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.cutRoundLiftOn(
                          AppDates.md(lift.lastDay, locale),
                        ),
                      ),
                      if (moved)
                        TextSpan(
                          text:
                              ' · ${l10n.cutRoundLiftDelta('$sign${gym.formatKg(delta.abs())} ${unit.storageKey}')}',
                          style: TextStyle(
                            color: delta > 0
                                ? AppColors.success
                                : theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  style: caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: gym.formatKg(last),
                  style: theme.textTheme.statFigure?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: _tabular,
                  ),
                ),
                TextSpan(text: ' ${unit.storageKey}', style: caption),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyText?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
