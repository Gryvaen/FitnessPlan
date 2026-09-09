import 'diet_strategy.dart';
import 'models.dart';

/// Whether the self-service fat-loss strategies apply to a profile.
abstract final class StrategyEligibility {
  /// Blocking reasons, empty when strategies may be configured.
  static List<StrategyIssue> check(UserProfile? profile) {
    if (profile == null) return const [StrategyIssue.invalidTdee];
    final issues = <StrategyIssue>[];
    if (profile.age < StrategyRules.minAdultAge) {
      issues.add(StrategyIssue.underage);
    }
    if (profile.goal != FitnessGoal.cut) issues.add(StrategyIssue.goalNotCut);
    final tdee = profile.tdee;
    if (tdee == null || !tdee.isFinite || tdee <= 0) {
      issues.add(StrategyIssue.invalidTdee);
    }
    if (!profile.weightKg.isFinite || profile.weightKg <= 0) {
      issues.add(StrategyIssue.invalidWeight);
    }
    return issues;
  }

  static bool eligible(UserProfile? profile) => check(profile).isEmpty;
}
