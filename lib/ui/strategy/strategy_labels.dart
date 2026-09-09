import '../../domain/diet_plan.dart';
import '../../domain/diet_strategy.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';

extension DietStrategyKindL10n on DietStrategyKind {
  String label(AppLocalizations l10n) => switch (this) {
    DietStrategyKind.balanced => l10n.strategyBalanced,
    DietStrategyKind.carbCycle => l10n.strategyCarbCycle,
    DietStrategyKind.carbTaper => l10n.strategyCarbTaper,
  };

  String description(AppLocalizations l10n) => switch (this) {
    DietStrategyKind.balanced => l10n.strategyBalancedDesc,
    DietStrategyKind.carbCycle => l10n.strategyCarbCycleDesc,
    DietStrategyKind.carbTaper => l10n.strategyCarbTaperDesc,
  };
}

extension CarbDayTypeL10n on CarbDayType {
  String label(AppLocalizations l10n) => switch (this) {
    CarbDayType.high => l10n.carbDayHigh,
    CarbDayType.mid => l10n.carbDayMid,
    CarbDayType.low => l10n.carbDayLow,
  };

  String shortLabel(AppLocalizations l10n) => switch (this) {
    CarbDayType.high => l10n.carbDayHighShort,
    CarbDayType.mid => l10n.carbDayMidShort,
    CarbDayType.low => l10n.carbDayLowShort,
  };
}

extension StrategyIssueL10n on StrategyIssue {
  String message(AppLocalizations l10n) => switch (this) {
    StrategyIssue.invalidWeight => l10n.issueInvalidWeight,
    StrategyIssue.invalidTdee => l10n.issueInvalidTdee,
    StrategyIssue.invalidTargetEnergy => l10n.issueInvalidTargetEnergy,
    StrategyIssue.deficitBelowRange => l10n.issueDeficitBelowRange,
    StrategyIssue.deficitAboveRange => l10n.issueDeficitAboveRange,
    StrategyIssue.energyBelowFloor => l10n.issueEnergyBelowFloor,
    StrategyIssue.energyAboveTdee => l10n.issueEnergyAboveTdee,
    StrategyIssue.carbBelowMinimum => l10n.issueCarbBelowMinimum(
      StrategyRules.minCarbG.round(),
    ),
    StrategyIssue.invalidSchedule => l10n.issueInvalidSchedule,
    StrategyIssue.amplitudeNegligible => l10n.issueAmplitudeNegligible,
    StrategyIssue.underage => l10n.issueUnderage(StrategyRules.minAdultAge),
    StrategyIssue.goalNotCut => l10n.issueGoalNotCut,
  };
}

extension TaperReviewStatusL10n on TaperReviewStatus {
  String label(AppLocalizations l10n) => switch (this) {
    TaperReviewStatus.observing => l10n.taperStatusObserving,
    TaperReviewStatus.insufficientWeightData =>
      l10n.taperStatusInsufficientWeight,
    TaperReviewStatus.insufficientDietData => l10n.taperStatusInsufficientDiet,
    TaperReviewStatus.hold => l10n.taperStatusHold,
    TaperReviewStatus.stepDownCandidate => l10n.taperStatusStepDown,
    TaperReviewStatus.floorReached => l10n.taperStatusFloor,
    TaperReviewStatus.rateTooHigh => l10n.taperStatusTooFast,
  };
}

/// Compact label for the Today hero chip, e.g. "碳循环 · 高碳日".
String targetChipLabel(
  DailyNutritionTarget target,
  UserProfile profile,
  AppLocalizations l10n,
) {
  switch (target.source) {
    case TargetSource.override:
      return l10n.targetSourceOverride;
    case TargetSource.strategy:
      final kind = target.strategy ?? DietStrategyKind.balanced;
      switch (kind) {
        case DietStrategyKind.balanced:
          return kind.label(l10n);
        case DietStrategyKind.carbCycle:
          final day = target.dayType;
          return day == null
              ? kind.label(l10n)
              : '${kind.label(l10n)} · ${day.label(l10n)}';
        case DietStrategyKind.carbTaper:
          final stage = _taperStageFromReason(target.reason);
          return stage == null
              ? kind.label(l10n)
              : '${kind.label(l10n)} · ${l10n.taperStageLabel(stage)}';
      }
    case TargetSource.profile:
      if (target.isLegacyEstimate) return l10n.targetLegacyEstimate;
      return switch (profile.goal) {
        FitnessGoal.cut => l10n.targetSourceProfileCut,
        FitnessGoal.maintain => l10n.goalMaintain,
        FitnessGoal.bulk => l10n.goalBulk,
      };
  }
}

int? _taperStageFromReason(String? reason) {
  if (reason == null) return null;
  const prefix = 'taperStage:';
  if (!reason.startsWith(prefix)) return null;
  return int.tryParse(reason.substring(prefix.length));
}
