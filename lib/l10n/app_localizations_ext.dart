import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';
import '../domain/body_metrics.dart';
import '../domain/calorie_calculator.dart';
import '../domain/models.dart';

export 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ActivityLevelL10n on ActivityLevel {
  String label(AppLocalizations l10n) => switch (this) {
        ActivityLevel.sedentary => l10n.activitySedentary,
        ActivityLevel.light => l10n.activityLight,
        ActivityLevel.moderate => l10n.activityModerate,
        ActivityLevel.high => l10n.activityHigh,
        ActivityLevel.athlete => l10n.activityAthlete,
      };
}

extension FitnessGoalL10n on FitnessGoal {
  String label(AppLocalizations l10n) => switch (this) {
        FitnessGoal.cut => l10n.goalCut,
        FitnessGoal.maintain => l10n.goalMaintain,
        FitnessGoal.bulk => l10n.goalBulk,
      };
}

extension MealTypeL10n on MealType {
  String label(AppLocalizations l10n) => switch (this) {
        MealType.breakfast => l10n.mealBreakfast,
        MealType.lunch => l10n.mealLunch,
        MealType.dinner => l10n.mealDinner,
        MealType.snack => l10n.mealSnack,
      };
}

extension ExerciseUnitL10n on ExerciseUnit {
  String label(AppLocalizations l10n) => switch (this) {
        ExerciseUnit.reps => l10n.reps,
        ExerciseUnit.seconds => l10n.seconds,
      };
}

extension BmiCategoryL10n on BmiCategory {
  String label(AppLocalizations l10n) => switch (this) {
        BmiCategory.underweight => l10n.bmiUnderweight,
        BmiCategory.normal => l10n.bmiNormal,
        BmiCategory.overweight => l10n.bmiOverweight,
        BmiCategory.obese => l10n.bmiObese,
      };
}

extension FfmiBandL10n on FfmiBand {
  String label(AppLocalizations l10n) => switch (this) {
        FfmiBand.average => l10n.ffmiAverage,
        FfmiBand.trained => l10n.ffmiTrained,
        FfmiBand.advanced => l10n.ffmiAdvanced,
        FfmiBand.elite => l10n.ffmiElite,
      };
}

extension SexL10n on Sex {
  String label(AppLocalizations l10n) => switch (this) {
        Sex.male => l10n.male,
        Sex.female => l10n.female,
      };
}

extension CalorieNoteL10n on CalorieNote {
  String localize(AppLocalizations l10n) {
    switch (id) {
      case CalorieNoteId.missingTargetWeight:
        return l10n.noteMissingTargetWeight;
      case CalorieNoteId.weeklyLossTooHigh:
        return l10n.noteWeeklyLossTooHigh(params['rate'] as String);
      case CalorieNoteId.weeklyLossTooLow:
        return l10n.noteWeeklyLossTooLow(params['rate'] as String);
      case CalorieNoteId.deficitCap:
        return l10n.noteDeficitCap(
          params['max'] as String,
          params['weekly'] as String,
          params['weeks'] as int,
        );
      case CalorieNoteId.estimateWeeks:
        return l10n.noteEstimateWeeks(
          params['kcalPerKg'] as String,
          params['weekly'] as String,
          params['weeks'] as int,
        );
      case CalorieNoteId.estimateWeeksShort:
        return l10n.noteEstimateWeeksShort(params['weeks'] as int);
      case CalorieNoteId.plateauAdj:
        return l10n.notePlateauAdj(params['adj'] as String);
    }
  }
}

extension CaloriePlanL10n on CaloriePlan {
  String bmrFormula(AppLocalizations l10n) => sex == Sex.male
      ? l10n.bmrFormulaMale
      : l10n.bmrFormulaFemale;
}

/// Locale-aware date formatting helpers.
abstract final class AppDates {
  static String md(DateTime d, Locale locale) {
    final code = locale.languageCode;
    if (code == 'zh') return DateFormat('M月d日', 'zh').format(d);
    return DateFormat.MMMd(code).format(d);
  }

  static String ymd(DateTime d, Locale locale) {
    final code = locale.languageCode;
    if (code == 'zh') return DateFormat('yyyy年M月d日', 'zh').format(d);
    return DateFormat.yMMMMd(code).format(d);
  }

  static String ym(DateTime d, Locale locale) {
    final code = locale.languageCode;
    if (code == 'zh') return DateFormat('yyyy年M月', 'zh').format(d);
    return DateFormat.yMMMM(code).format(d);
  }

  static String weekdayShort(DateTime d, Locale locale) {
    return DateFormat.E(locale.languageCode).format(d);
  }

  static String mdWithWeekday(DateTime d, Locale locale) {
    return '${md(d, locale)} ${weekdayShort(d, locale)}';
  }

  static String ymdWithWeekday(DateTime d, Locale locale) {
    return '${ymd(d, locale)} ${weekdayShort(d, locale)}';
  }

  static String relativeDayTitle(DateTime d, DateTime today, AppLocalizations l10n, Locale locale) {
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    if (day == t) return l10n.todayWord;
    if (day == t.subtract(const Duration(days: 1))) return l10n.yesterday;
    if (day.year == t.year) return mdWithWeekday(day, locale);
    return ymdWithWeekday(day, locale);
  }
}

extension FoodCategoryL10n on String {
  /// Localize known category keys (e.g. custom); leave seed categories as-is.
  String localizedCategory(AppLocalizations l10n) {
    if (this == '自定义') return l10n.custom;
    return this;
  }
}
