import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../domain/diet_plan.dart';
import '../domain/diet_strategy.dart';
import '../domain/models.dart';
import 'core_providers.dart';

const strategyReviewWeightThreshold = 0.03;
const _dismissalKey = 'strategy_review_dismissal_v1';
const _profileReviewKey = 'strategy_profile_review_v1';

final profileStrategyReviewProvider =
    NotifierProvider<ProfileStrategyReviewNotifier, ProfileStrategyReview?>(
      ProfileStrategyReviewNotifier.new,
    );

class ProfileStrategyReview {
  const ProfileStrategyReview({
    required this.planKey,
    required this.revision,
    required this.dismissedRevision,
  });

  final String planKey;
  final int revision;
  final int dismissedRevision;

  static ProfileStrategyReview? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileStrategyReview(
        planKey: data['planKey'] as String,
        revision: data['revision'] as int,
        dismissedRevision: data['dismissedRevision'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  String toJson() => jsonEncode({
    'planKey': planKey,
    'revision': revision,
    'dismissedRevision': dismissedRevision,
  });
}

class ProfileStrategyReviewNotifier extends Notifier<ProfileStrategyReview?> {
  @override
  ProfileStrategyReview? build() => ProfileStrategyReview.fromJson(
    ref.read(sharedPreferencesProvider).getString(_profileReviewKey),
  );

  Future<void> record(DietStrategyPlan plan) async {
    final previous = state;
    final samePlan = previous?.planKey == StrategyReviewDismissal.keyFor(plan);
    final next = ProfileStrategyReview(
      planKey: StrategyReviewDismissal.keyFor(plan),
      revision: samePlan ? previous!.revision + 1 : 1,
      dismissedRevision: samePlan ? previous!.dismissedRevision : 0,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString(_profileReviewKey, next.toJson());
    state = next;
  }

  Future<void> dismiss() async {
    final current = state;
    if (current == null) return;
    final next = ProfileStrategyReview(
      planKey: current.planKey,
      revision: current.revision,
      dismissedRevision: current.revision,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString(_profileReviewKey, next.toJson());
    state = next;
  }
}

bool profileAffectsNutrition(UserProfile old, UserProfile next) =>
    old.sex != next.sex ||
    old.age != next.age ||
    old.heightCm != next.heightCm ||
    old.weightKg != next.weightKg ||
    old.activity != next.activity;

bool profileDiffersFromPlan(UserProfile profile, DietStrategyPlan plan) {
  if ((profile.weightKg - plan.referenceWeightKg).abs() > 1e-6 ||
      ((profile.tdee ?? 0) - plan.estimatedTdee).abs() > 1e-6) {
    return true;
  }
  if (plan.kind == DietStrategyKind.carbCycle) {
    final schedule = plan.schedule;
    final rates = plan.carbCycleRates;
    if (schedule == null || rates == null) return false;
    final next = CarbCyclePlanner.compute(
      referenceWeightKg: profile.weightKg,
      rates: rates,
      schedule: schedule,
    );
    return (next.cycleAverageEnergy - plan.baseEnergy).abs() > 1e-6;
  }
  final nextEnergy = (profile.tdee ?? 0) * (1 - plan.deficitFraction);
  return (nextEnergy - plan.baseEnergy).abs() > 1e-6;
}

bool shouldSuggestProfileStrategyReview({
  required DietStrategyPlan? plan,
  required UserProfile? profile,
  required ProfileStrategyReview? review,
}) =>
    plan != null &&
    profile != null &&
    review?.planKey == StrategyReviewDismissal.keyFor(plan) &&
    review!.revision > review.dismissedRevision &&
    profileDiffersFromPlan(profile, plan);

final strategyReviewDismissalProvider =
    NotifierProvider<StrategyReviewDismissalNotifier, StrategyReviewDismissal?>(
      StrategyReviewDismissalNotifier.new,
    );

class StrategyReviewDismissal {
  const StrategyReviewDismissal({
    required this.planKey,
    required this.weightKg,
  });

  final String planKey;
  final double weightKg;

  static String keyFor(DietStrategyPlan plan) =>
      '${plan.id}:${plan.version}:${plan.createdAt.microsecondsSinceEpoch}';

  static StrategyReviewDismissal? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final weight = (data['weightKg'] as num).toDouble();
      if (!weight.isFinite || weight <= 0) return null;
      return StrategyReviewDismissal(
        planKey: data['planKey'] as String,
        weightKg: weight,
      );
    } catch (_) {
      return null;
    }
  }

  String toJson() => jsonEncode({'planKey': planKey, 'weightKg': weightKg});
}

class StrategyReviewDismissalNotifier
    extends Notifier<StrategyReviewDismissal?> {
  @override
  StrategyReviewDismissal? build() => StrategyReviewDismissal.fromJson(
    ref.read(sharedPreferencesProvider).getString(_dismissalKey),
  );

  Future<void> dismiss(DietStrategyPlan plan, double weightKg) async {
    final dismissal = StrategyReviewDismissal(
      planKey: StrategyReviewDismissal.keyFor(plan),
      weightKg: weightKg,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString(_dismissalKey, dismissal.toJson());
    state = dismissal;
  }
}

bool shouldSuggestStrategyReview({
  required DietStrategyPlan? plan,
  required double? currentWeightKg,
  required StrategyReviewDismissal? dismissal,
  DateTime? now,
}) {
  if (plan == null || currentWeightKg == null) return false;
  if (!currentWeightKg.isFinite || currentWeightKg <= 0) return false;
  final reference = plan.referenceWeightKg;
  if (!reference.isFinite || reference <= 0) return false;
  if (plan.effectiveFrom.isAfter(CalendarDay.todayLocal(now))) return false;
  if ((currentWeightKg - reference).abs() / reference <
      strategyReviewWeightThreshold) {
    return false;
  }
  if (dismissal?.planKey != StrategyReviewDismissal.keyFor(plan)) return true;
  return (currentWeightKg - dismissal!.weightKg).abs() / dismissal.weightKg >=
      strategyReviewWeightThreshold;
}
