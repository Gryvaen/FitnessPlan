import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';

/// Asks before switching the profile goal to [to]. The dialog only states
/// what will happen (no advice): the cut round settles, a fat-loss strategy
/// stops, and what the new goal sets. [toLine] replaces that last line (the
/// strategy configure pages name the strategy being applied). [leadLine]
/// goes first (a booked switch's "from {date}:" line).
///
/// Returns true when there is nothing to confirm (already on [to]).
Future<bool> confirmGoalSwitch(
  BuildContext context,
  WidgetRef ref,
  FitnessGoal to, {
  String? toLine,
  String? leadLine,
}) async {
  final l10n = context.l10n;
  final profile = ref.read(profileProvider);
  if (profile == null) return false;
  if (profile.goal == to) return true;

  final leavingCut = profile.goal == FitnessGoal.cut;
  final hasStrategy =
      leavingCut &&
      await ref.read(dietStrategyRepositoryProvider).activePlan() != null;
  if (!context.mounted) return false;
  final preview = ref
      .read(profileRepositoryProvider)
      .buildPlan(profile.copyWith(goal: to))
      .targets
      .calories;
  final lines = [
    ?leadLine,
    if (leavingCut) l10n.switchGoalLeaveCut,
    if (hasStrategy) l10n.switchGoalStopStrategy,
    toLine ??
        switch (to) {
          FitnessGoal.cut => l10n.switchGoalToCut,
          FitnessGoal.maintain => l10n.switchGoalToMaintain(preview),
          FitnessGoal.bulk => l10n.switchGoalToBulk(preview),
        },
  ];

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.switchGoalTitle(to.label(l10n))),
      content: Text(lines.join('\n')),
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
  return ok == true;
}

/// Switches the profile goal to [to] with the same side effects as the
/// profile editor: `ProfileNotifier.save` stops a fat-loss strategy, settles
/// or opens the cut round and re-stamps the new-standard day. No-op when
/// already on [to].
///
/// [maintainProteinPerKg] / [maintainFatPerKg] set the 维持 macro rates
/// (kept when omitted).
Future<void> switchGoal(
  WidgetRef ref,
  FitnessGoal to, {
  double? maintainProteinPerKg,
  double? maintainFatPerKg,
}) async {
  final profile = ref.read(profileProvider);
  if (profile == null || profile.goal == to) return;
  // Same target-weight rule as the profile editor: keep it only for cut,
  // and only while it is still below the current weight.
  final target = profile.targetWeightKg;
  final keepTarget =
      to == FitnessGoal.cut && target != null && target < profile.weightKg;
  await ref
      .read(profileProvider.notifier)
      .save(
        sex: profile.sex,
        age: profile.age,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        activity: profile.activity,
        goal: to,
        targetWeightKg: keepTarget ? target : null,
        calorieAdjustment: profile.calorieAdjustment,
        maintainProteinPerKg: maintainProteinPerKg,
        maintainFatPerKg: maintainFatPerKg,
      );
}

/// Confirm + switch, for the cultivation pages' "switch to X" action.
/// Switching to cut then opens the strategy picker (without a strategy cut
/// eats at TDEE). Returns whether the goal changed.
Future<bool> confirmAndSwitchGoal(
  BuildContext context,
  WidgetRef ref,
  FitnessGoal to,
) async {
  final l10n = context.l10n;
  if (ref.read(profileProvider)?.goal == to) return false;
  if (!await confirmGoalSwitch(context, ref, to) || !context.mounted) {
    return false;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    await switchGoal(ref, to);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    return false;
  }
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.switchedGoal(to.label(l10n)))),
  );
  if (to == FitnessGoal.cut && context.mounted) {
    context.push('/profile/nutrition/strategy');
  }
  return true;
}
