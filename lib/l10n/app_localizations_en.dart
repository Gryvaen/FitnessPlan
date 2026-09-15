// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plan';

  @override
  String get loadingTitleLeft => 'Discipline';

  @override
  String get loadingTitleRight => 'Freedom';

  @override
  String get loadingSubtitle => 'Every effort brings you closer to freedom';

  @override
  String get loadingPreparingPlan => 'Preparing today\'s plan';

  @override
  String get loadingPreparationFailed => 'Preparation failed. Please try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get replace => 'Replace';

  @override
  String get append => 'Append';

  @override
  String get later => 'Later';

  @override
  String get copy => 'Copy';

  @override
  String get change => 'Change';

  @override
  String get done => 'Done';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Reset';

  @override
  String get more => 'More';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get leaveBlank => 'Leave blank';

  @override
  String get saving => 'Saving…';

  @override
  String get saved => 'Saved';

  @override
  String get writing => 'Saving…';

  @override
  String get deleted => 'Deleted';

  @override
  String get unsaved => 'Unsaved';

  @override
  String get calculating => 'Calculating…';

  @override
  String get timing => 'Timing…';

  @override
  String get connecting => 'Connecting…';

  @override
  String get downloading => 'Downloading';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get sex => 'Sex';

  @override
  String get age => 'Age';

  @override
  String get ageUnit => 'yr';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get currentWeight => 'Current weight';

  @override
  String get targetWeight => 'Target weight';

  @override
  String get activityLevel => 'Activity level';

  @override
  String get goal => 'Goal';

  @override
  String get name => 'Name';

  @override
  String get mealType => 'Meal';

  @override
  String get grams => 'Grams';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get proteinShort => 'Protein';

  @override
  String get favorites => 'Favorites';

  @override
  String get unfavorite => 'Unfavorite';

  @override
  String get custom => 'Custom';

  @override
  String get searchFood => 'Search foods';

  @override
  String get noFoodFound => 'No foods found';

  @override
  String get commonPortions => 'Common portions';

  @override
  String get logMeal => 'Log meal';

  @override
  String get myProfile => 'My profile';

  @override
  String get toolbox => 'Toolbox';

  @override
  String get records => 'Records';

  @override
  String get today => 'Today';

  @override
  String get me => 'Me';

  @override
  String get foods => 'Foods';

  @override
  String get todayWord => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get exercise => 'Exercise';

  @override
  String get targetSets => 'Target sets';

  @override
  String get targetReps => 'Target reps';

  @override
  String get targetSeconds => 'Target seconds';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get exerciseNoteLabel => 'Notes';

  @override
  String get actualWeightLabel => 'Weight';

  @override
  String get optionalHint => 'Optional';

  @override
  String get reps => 'reps';

  @override
  String get seconds => 'sec';

  @override
  String get repsCount => 'Reps';

  @override
  String get deleteRecord => 'Delete entry';

  @override
  String get history => 'Daily records';

  @override
  String get water => 'Water';

  @override
  String get bodyFatPct => 'Body fat %';

  @override
  String get neck => 'Neck';

  @override
  String get waist => 'Waist';

  @override
  String get hip => 'Hip';

  @override
  String get portion => 'Portion';

  @override
  String get clearSelection => 'Clear';

  @override
  String get completed => 'Done';

  @override
  String get goRecords => 'Go to Records';

  @override
  String get startUsing => 'Get started';

  @override
  String get startWriting => 'Start writing';

  @override
  String get checkUpdate => 'Check for updates';

  @override
  String get downloadInstall => 'Download & install';

  @override
  String get clearData => 'Clear data';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get importDataBody =>
      'Import will replace all local data (meals, weight, workouts, profile, etc.). Continue?';

  @override
  String get importDataDone => 'Data imported';

  @override
  String importDataFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get exportDataDone => 'Data exported — save it somewhere safe';

  @override
  String exportDataFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportToFolder => 'Save to folder';

  @override
  String get exportToFolderHint => 'Choose a file name and location';

  @override
  String get exportViaShare => 'Share with another app';

  @override
  String get exportViaShareHint => 'Send to Drive, Files, and more';

  @override
  String exportDataSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get dataManagement => 'Data management';

  @override
  String get aboutLocalPrivacy =>
      'Data stays on this device — no account, no cloud';

  @override
  String get calcMethod => 'How it\'s calculated';

  @override
  String get tdeeCalcMethod => 'TDEE calculation method';

  @override
  String get dailyQuota => 'Daily targets';

  @override
  String get foodLibrary => 'Food library';

  @override
  String get categories => 'Categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get categoryEmpty => 'No foods in this category';

  @override
  String get foodNotFound => 'Food not found';

  @override
  String get foodNotFoundShort => 'Food not found';

  @override
  String get recordNotFound => 'Record not found';

  @override
  String get invalidFood => 'Invalid food';

  @override
  String get invalidRecord => 'Invalid record';

  @override
  String get per100g => 'Per 100 g';

  @override
  String get nutritionIntake => 'Nutrition';

  @override
  String get convertResult => 'Result';

  @override
  String get recentlyEaten => 'Recently eaten';

  @override
  String get badgeRecent => 'Recent';

  @override
  String get badgeFavorite => 'Fav';

  @override
  String get mealPresets => 'Meal presets';

  @override
  String get saveAsPreset => 'Save as preset';

  @override
  String get presetSaved => 'Preset saved';

  @override
  String get saveAsPlan => 'Save as workout plan';

  @override
  String get planSaved => 'Workout plan saved';

  @override
  String get noWorkoutToSave => 'Nothing to save for this day';

  @override
  String get copyYesterday => 'Copy yesterday';

  @override
  String copyNamed(String name) {
    return 'Copy $name';
  }

  @override
  String get copyYesterdayWorkout => 'Copy yesterday\'s workout';

  @override
  String get copyYesterdayWorkoutConfirm =>
      'Today already has a workout plan; append yesterday\'s?';

  @override
  String copiedWorkoutItems(int n) {
    return 'Copied $n exercises';
  }

  @override
  String get yesterdayNoWorkout => 'No workout logged yesterday';

  @override
  String get backfillMeal => 'Backfill';

  @override
  String get prevDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get cut100Kcal => 'Cut 100 kcal';

  @override
  String get walk3000Btn => '+~3000 steps';

  @override
  String get walk3000Snack => 'Try ~3000 extra steps/day first.';

  @override
  String get cutAdjCapReached => 'Adjustment limit reached';

  @override
  String get possiblePlateau => 'Possible plateau';

  @override
  String get noLogsToSave => 'Nothing to save for this day';

  @override
  String get yesterdayNoLogs => 'No logs yesterday';

  @override
  String get emptyMealsToday => 'No logs yet — tap + to log';

  @override
  String get emptyMealsThatDay => 'No logs that day (view only)';

  @override
  String get noMealsThatDay => 'No meals logged that day';

  @override
  String get emptyWeightLogs => 'No logs yet — tap + to add';

  @override
  String get pastDayReadOnly => 'Past days are view-only';

  @override
  String get chartWeightTitle => 'Weight (kg)';

  @override
  String get chartWeightEmpty => 'No weight data';

  @override
  String get chartBfTitle => 'Body fat (%)';

  @override
  String get chartBfEmpty => 'No body-fat logs';

  @override
  String get logWeightTitle => 'Log weight';

  @override
  String get fabLogWeight => 'Log weight';

  @override
  String get fabNewPlan => 'New plan';

  @override
  String get fabWriteNote => 'Write note';

  @override
  String get segmentBody => 'Body';

  @override
  String get segmentTrain => 'Train';

  @override
  String get segmentNotes => 'Notes';

  @override
  String get customExercise => 'Custom exercise';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get repsOrSeconds => 'Reps / sec';

  @override
  String get exerciseLibrary => 'Exercise library';

  @override
  String get noExercises => 'No exercises';

  @override
  String get exerciseCategoryChest => 'Chest';

  @override
  String get exerciseCategoryBack => 'Back';

  @override
  String get exerciseCategoryShoulders => 'Shoulders';

  @override
  String get exerciseCategoryArms => 'Arms';

  @override
  String get exerciseCategoryLegs => 'Legs';

  @override
  String get exerciseCategoryCore => 'Core';

  @override
  String get exerciseCategoryCoreTimed => 'Core (timed)';

  @override
  String get exerciseCategoryCardio => 'Cardio';

  @override
  String get exerciseCategoryAnaerobic => 'Anaerobic';

  @override
  String get exerciseCategoryShouldersArms => 'Shoulders & arms';

  @override
  String get exerciseCategoryCustom => 'Custom';

  @override
  String get exerciseCategoryOther => 'Other';

  @override
  String get workoutPlans => 'Workout plans';

  @override
  String get emptyPlans => 'No plans yet — tap + to create';

  @override
  String get deletePlan => 'Delete plan';

  @override
  String get noExercisesInPlan => 'No exercises';

  @override
  String get workoutHistory => 'Recent workouts';

  @override
  String get stepHistory => 'Daily steps';

  @override
  String get steps => 'Steps';

  @override
  String nSteps(int n) {
    return '$n steps';
  }

  @override
  String get fiber => 'Fiber';

  @override
  String get sodium => 'Sodium';

  @override
  String get sugar => 'Sugar';

  @override
  String get saturatedFat => 'Saturated fat';

  @override
  String get calcium => 'Calcium';

  @override
  String get fiberG => 'Fiber (g)';

  @override
  String get sodiumMg => 'Sodium (mg)';

  @override
  String get sugarG => 'Sugar (g)';

  @override
  String get saturatedFatG => 'Saturated fat (g)';

  @override
  String get calciumMg => 'Calcium (mg)';

  @override
  String get fiberGOptional => 'Fiber (g, optional)';

  @override
  String get sodiumMgOptional => 'Sodium (mg, optional)';

  @override
  String get sugarGOptional => 'Sugar (g, optional)';

  @override
  String get saturatedFatGOptional => 'Saturated fat (g, optional)';

  @override
  String get calciumMgOptional => 'Calcium (mg, optional)';

  @override
  String get stepsStatusConnected => 'System steps synced';

  @override
  String get stepsStatusDenied => 'Physical activity permission not granted';

  @override
  String get stepsStatusEmpty => 'Connected, but 0 steps read for today';

  @override
  String get stepsStatusUnsupported =>
      'Step sync is not supported on this platform';

  @override
  String get stepsStatusSyncing => 'Syncing steps…';

  @override
  String get stepsStatusFailed => 'Step sync failed';

  @override
  String get stepsStatusRetryHint => 'Tap for details';

  @override
  String get stepsSheetTitle => 'Step sync';

  @override
  String get stepsSheetSourceHint =>
      'Today\'s steps are the larger of Health Connect and the phone\'s step sensor. On OPPO, Xiaomi and similar phones the system health app does not share steps with third parties; without Health Connect data, the sensor counts from first authorization, earlier steps that day cannot be recovered, and days align automatically from the next day.';

  @override
  String get stepsSheetEmptyHint =>
      'If your system health app shows steps but this is 0: allow this app to read steps in Health Connect and enable data sharing in the health app; otherwise walk a bit and come back to this page.';

  @override
  String get stepsSheetDeniedHint =>
      'Grant the Physical activity permission to this app in system settings, then resync.';

  @override
  String get stepsSheetResync => 'Resync';

  @override
  String get stepsSheetOpenSettings => 'Open health / permission settings';

  @override
  String get stepsSheetDiagnostics => 'Diagnostics';

  @override
  String get stepsSheetDiagnosticsLoading => 'Loading…';

  @override
  String get stepsServiceTitle => 'Count steps in the background';

  @override
  String get stepsServiceHint =>
      'Shows an ongoing notification and keeps counting even when the system limits background apps — the reliable option on OPPO, Xiaomi and similar phones.';

  @override
  String get noSetLogs => 'No set logs';

  @override
  String get addExercisesFirst =>
      'Add exercises in the library first, then come back to build your plan';

  @override
  String get addExercisesFirstShort => 'Add exercises first';

  @override
  String get goToExerciseLibrary => 'Open library';

  @override
  String get addTodayExercise => 'Add today\'s exercise';

  @override
  String get planNameRequired => 'Enter a plan name';

  @override
  String get selectOneExercise => 'Select at least one exercise';

  @override
  String get newPlan => 'New plan';

  @override
  String get editPlan => 'Edit plan';

  @override
  String get planName => 'Plan name';

  @override
  String get planNameHint => 'e.g. Upper-body bodyweight';

  @override
  String get durationSeconds => 'Duration (sec)';

  @override
  String get completedSets => 'Completed sets';

  @override
  String get notesEmptyHint => 'Log training feel, sleep, or diet deviations';

  @override
  String get notesEmptyCta => 'Tap + to start writing';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get noteHint => 'Log today\'s training feel, sleep, or diet…';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get unsavedChangesBody => 'Profile has unsaved edits. What next?';

  @override
  String get dailyWaterGoal => 'Daily water goal';

  @override
  String get quotaReadyTitle => 'Daily targets ready';

  @override
  String get createProfileTitle => 'Create your profile';

  @override
  String get createProfileHint =>
      'Enter your stats to generate daily calorie and macro targets.';

  @override
  String get calculateAndStart => 'Calculate & start';

  @override
  String get addCommonPortion => 'Add portion';

  @override
  String get portionNameHint => 'e.g. 1 bowl / 500 ml bottle';

  @override
  String get deleteCustomFood => 'Delete custom food';

  @override
  String get deleteCustomFoodBody => 'Delete? Past logs keep the name.';

  @override
  String get noPortionsHint => 'None yet — quick-pick when logging';

  @override
  String get deleteCommonPortion => 'Delete portion';

  @override
  String confirmDeleteCommonPortion(String name) {
    return 'Delete the portion \"$name\"?';
  }

  @override
  String get customFoodAdded => 'Custom food added';

  @override
  String get editCustomFood => 'Edit custom food';

  @override
  String get addCustomFood => 'Add custom food';

  @override
  String get per100gNutrition => 'Per 100 g nutrition';

  @override
  String get kcalField => 'Calories (kcal)';

  @override
  String get kjField => 'Calories (kJ)';

  @override
  String get proteinG => 'Protein (g)';

  @override
  String get carbG => 'Carbs (g)';

  @override
  String get fatG => 'Fat (g)';

  @override
  String get alcoholGOptional => 'Alcohol (g, optional)';

  @override
  String get selectFoodAndGrams => 'Select a food and grams';

  @override
  String get mealDateRangeError =>
      'Meals only within the past year through today';

  @override
  String get searchToLog => 'Search a food to start logging';

  @override
  String get confirmDeleteMeal => 'Delete this entry?';

  @override
  String get clearThisMeal => 'Clear this meal';

  @override
  String confirmClearMeal(String name) {
    return 'Delete all $name entries logged today?';
  }

  @override
  String get toolBodyFat => 'Body-fat estimate';

  @override
  String get toolBodyFatSub => 'US Navy circumference method';

  @override
  String get toolBodyMetrics => 'Body metrics';

  @override
  String get toolBodyMetricsSub => 'BMI, ideal weight, WHtR, FFMI';

  @override
  String get toolFoodConvert => 'Food convert';

  @override
  String get toolFoodConvertSub => 'Convert macros by grams';

  @override
  String get toolRestTimer => 'Rest timer';

  @override
  String get toolRestTimerSub => 'Between-set timer with lock-screen alerts';

  @override
  String get toolCalculator => 'Calculator';

  @override
  String get toolCalculatorSub => 'Basic arithmetic';

  @override
  String get toolEnergyConvert => 'kcal / kJ convert';

  @override
  String get toolEnergyConvertSub => 'Convert energy between kcal and kJ';

  @override
  String get toolsDisclaimer =>
      'Results are not saved to profile or meal logs by default.';

  @override
  String get bfDisclaimer => 'US Navy estimate — not a scale/DEXA reading.';

  @override
  String get abdomenWaist => 'Abdomen (waist)';

  @override
  String get estimatedBf => 'Estimated body fat';

  @override
  String get bfCircumferenceError =>
      'Check measurements: waist/abdomen must exceed neck.';

  @override
  String get writeBfToWeight => 'Save BF% to today\'s weight log';

  @override
  String get bfNoWeightLog => 'No weight log today — log weight first';

  @override
  String get metricsLocalOnly =>
      'Local estimates only; won\'t change your profile. Tap to expand formulas.';

  @override
  String get bodyFat => 'Body fat';

  @override
  String get idealWeightDevine => 'Ideal weight (Devine)';

  @override
  String get whtr => 'Waist-to-height';

  @override
  String get leanMass => 'Lean mass';

  @override
  String get normalizedFfmi => 'Normalized FFMI';

  @override
  String get normalizedFfmiUnit => 'Adjusted to 1.8 m';

  @override
  String get ffmiNeedBf => 'FFMI: enter valid body fat (0–100%).';

  @override
  String bmiFormula(String weight, String heightM, String bmi) {
    return 'BMI = weight(kg) ÷ height(m)²\n= $weight ÷ $heightM²\n= $bmi\n\nWHO categories:\nUnderweight < 18.5 · Normal 18.5–24.9\nOverweight 25–29.9 · Obese ≥ 30';
  }

  @override
  String idealWeightFormula(
    String sex,
    String heightCm,
    String heightIn,
    String base,
    String inchesOver,
    String ideal,
  ) {
    return 'Devine formula ($sex)\nHeight = $heightCm cm ≈ $heightIn in\nIdeal weight = $base + 2.3 × (height inches − 60)\n= $base + 2.3 × $inchesOver\n= $ideal kg\n\nBelow 5 ft (152.4 cm), use base $base kg.';
  }

  @override
  String whtrFormula(String waist, String heightCm, String whtr, String ref) {
    return 'WHtR = waist(cm) ÷ height(cm)\n= $waist ÷ $heightCm\n= $whtr\n\nLower is generally better (within reason)\n≤ $ref: healthier reference; clearly above: often higher abdominal-fat risk.';
  }

  @override
  String get whtrAboveNow => '\n\nCurrently above the reference line.';

  @override
  String leanMassFormula(String weight, String bf, String ffm) {
    return 'Fat-free mass FFM = weight × (1 − body fat%)\n= $weight × (1 − $bf%)\n= $ffm kg';
  }

  @override
  String ffmiFormula(String ffm, String heightM, String ffmi) {
    return 'FFMI = FFM(kg) ÷ height(m)²\n= $ffm ÷ $heightM²\n= $ffmi\n\nAdult male rough guide:\n<19 average · 19–21 trained\n22–23 advanced · ≥24 elite reference\nWomen usually ~3–5 lower; not a hard standard.';
  }

  @override
  String normalizedFfmiFormula(String ffmi, String heightM, String normFfmi) {
    return 'Normalized FFMI = FFMI + 6.1 × (1.8 − height_m)\n= $ffmi + 6.1 × (1.8 − $heightM)\n= $normFfmi\n\nAdjusts for height away from 1.8 m for comparability.';
  }

  @override
  String get foodConvertHint =>
      'Search or pick a favorite to add it below — add as many foods as you like to see their combined totals.';

  @override
  String addedFoodsTitle(int count) {
    return 'Added ($count)';
  }

  @override
  String get clearAllFoods => 'Clear all';

  @override
  String get restNotifyPermissionHint =>
      'Without notification permission, lock-screen alerts may not fire; foreground timer still works.';

  @override
  String get restDoneSnack => 'Rest over — next set';

  @override
  String get restTimerIntro =>
      'Between-set countdown. With notifications, alerts work on lock screen / background.';

  @override
  String get workoutReminderTitle => 'Time to train';

  @override
  String get workoutReminderBodyNormal =>
      'Log a set today and keep the streak going.';

  @override
  String get workoutReminderBodyEncourage =>
      'Missed yesterday? No worries — move today and you’ll feel better.';

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersSubtitle => 'Workout, water, meals and weigh-in';

  @override
  String get workoutReminderTile => 'Daily workout reminder';

  @override
  String get workoutReminderSubtitleOff =>
      'Turn on to get a daily training nudge';

  @override
  String workoutReminderSubtitleOn(String time) {
    return 'Every day at $time';
  }

  @override
  String get workoutReminderPermissionDenied =>
      'Notification permission denied; daily reminder stays off.';

  @override
  String get reminderWaterTitle => 'Drink water';

  @override
  String get reminderWaterBody => 'Time for a glass of water.';

  @override
  String get reminderMealTitle => 'Log your meals';

  @override
  String get reminderMealBody => 'Don\'t forget to record what you ate today.';

  @override
  String get reminderWeighInTitle => 'Weigh-in';

  @override
  String get reminderWeighInBody => 'Step on the scale and log your weight.';

  @override
  String get reminderKindWorkout => 'Workout';

  @override
  String get reminderKindWater => 'Drink water';

  @override
  String get reminderKindMeal => 'Log meals';

  @override
  String get reminderKindWeighIn => 'Weigh-in';

  @override
  String get reminderKindWorkoutDesc => 'A daily nudge to train';

  @override
  String get reminderKindWaterDesc => 'A reminder to hydrate';

  @override
  String get reminderKindMealDesc => 'A nudge to record your food';

  @override
  String get reminderKindWeighInDesc => 'A morning reminder to weigh in';

  @override
  String reminderDailyAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderTimeLabel => 'Reminder time';

  @override
  String get reminderRepeatLabel => 'Repeat';

  @override
  String get reminderAlertModeRing => 'Ring';

  @override
  String get reminderAlertModeVibrate => 'Vibrate';

  @override
  String get reminderSoundLabel => 'Sound';

  @override
  String get reminderSoundDefault => 'System default';

  @override
  String get weekdayLettersMonSun => 'M,T,W,T,F,S,S';

  @override
  String get notificationPermissionRow => 'Notification permission';

  @override
  String get notificationPermissionOn => 'Allowed';

  @override
  String get notificationPermissionHint =>
      'Allow notifications so reminders are delivered.';

  @override
  String get reminderRestrictionsSummary =>
      'Some reminders may be restricted by your phone — tap to review';

  @override
  String get reminderRestrictionsSheetTitle => 'Reminder permissions';

  @override
  String get reminderOemHintTitle => 'Your phone may restrict reminders';

  @override
  String get reminderOemHintBody =>
      'Some phone brands restrict background apps, which can silence or block reminders from ringing, vibrating, or firing at all. It helps to disable battery optimization for this app and allow \"auto-start\" / background running in system settings.';

  @override
  String get reminderOemHintBatteryButton => 'Disable battery optimization';

  @override
  String get reminderOemHintAutostartButton => 'Auto-start settings';

  @override
  String get stepsOemHintBody =>
      'Some phone brands restrict background apps, which can stop step counting once the app is closed. Disabling battery optimization for this app helps it keep counting.';

  @override
  String get customDuration => 'Custom (0:30–10:00)';

  @override
  String get notifChannelName => 'Rest timer';

  @override
  String get notifChannelDesc => 'Between-set rest alerts';

  @override
  String get restDoneTitle => 'Rest over';

  @override
  String get restDoneBody => 'Start next set';

  @override
  String get restTimerReady => 'Ready';

  @override
  String get restTimerRunning => 'Resting';

  @override
  String get restTimerPaused => 'Paused';

  @override
  String get restTimerFinished => 'Rest complete';

  @override
  String get restTimerPause => 'Pause';

  @override
  String get restTimerResume => 'Resume';

  @override
  String get restTimerDismiss => 'Close';

  @override
  String get restTimerPresetTitle => 'Choose rest duration';

  @override
  String restTimerMinutes(String value) {
    return '$value min';
  }

  @override
  String get restTimerMinus15 => '−15 sec';

  @override
  String get restTimerPlus15 => '+15 sec';

  @override
  String get copiedClipboard => 'Copied to clipboard';

  @override
  String get calcHistory => 'History';

  @override
  String get noHistory => 'No history';

  @override
  String get calcError => 'Error';

  @override
  String get bmrSection => '1. BMR';

  @override
  String get tdeeSection => '2. TDEE';

  @override
  String get targetIntakeSection => '3. Target intake';

  @override
  String get macrosSection => '4. Macros';

  @override
  String get notesSection => 'Notes';

  @override
  String actualDeficitFormula(String planned) {
    return 'Actual deficit = plan $planned + remaining calories';
  }

  @override
  String actualDeficitForDay(String day, String kcal) {
    return '$day actual deficit $kcal kcal';
  }

  @override
  String remainingCaloriesLine(String kcal) {
    return 'Remaining $kcal kcal';
  }

  @override
  String get calendarRemainingHint =>
      'Select a day with meal logs to see remaining calories';

  @override
  String get legendColors => 'Colors';

  @override
  String get legendPastOk => 'Past · met';

  @override
  String get legendPastBad => 'Past · missed';

  @override
  String get legendTodayOngoing => 'Today · in progress';

  @override
  String get legendStandardChange => 'Standard change';

  @override
  String get legendNewStandardLine => 'Vertical line = new standard effective';

  @override
  String get legendBeforeNeutral => 'Before: neutral numbers';

  @override
  String get legendAfterGreenRed => 'After: past green/red';

  @override
  String get waterTapHint => 'Tap cup +250 · tap lid −250';

  @override
  String get noWorkoutPlanTitle => 'No workout plan yet';

  @override
  String get noWorkoutPlanBody =>
      'Add an exercise now, or create a plan under Records → Train.';

  @override
  String get replaceTodayWorkout => 'Replace today\'s workout';

  @override
  String get replaceTodayWorkoutBody =>
      'Today already has a workout; replace with this plan?';

  @override
  String get noWorkoutTodo => 'No workout for today';

  @override
  String get noWorkoutThatDay => 'No workout logged that day';

  @override
  String get addTodayWorkout => 'Add today\'s workout';

  @override
  String get quickAddExercise => 'Quick-add exercise';

  @override
  String get quickAddPlan => 'Quick-add plan';

  @override
  String get sectionThatDay => 'That day';

  @override
  String get foodsSeedLoadFailed => 'Failed to load food library';

  @override
  String get enterAnyway => 'Enter anyway';

  @override
  String get toolboxSubtitle =>
      'Body fat · metrics · food convert · rest timer';

  @override
  String get theme => 'Theme';

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get themeSunrise => 'Sunrise';

  @override
  String get clearDataBody =>
      'Clears all meals, weight, workouts, notes, favorites, and profile. Continue?';

  @override
  String get noInstallPackage => 'No install package for the new version';

  @override
  String get copyYesterdayConfirm =>
      'Day already has logs; append yesterday\'s meals?';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLight => 'Lightly active';

  @override
  String get activityModerate => 'Moderately active';

  @override
  String get activityHigh => 'Very active';

  @override
  String get activityAthlete => 'Athlete';

  @override
  String get goalCut => 'Cut';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalBulk => 'Bulk';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get ffmiAverage => 'Average';

  @override
  String get ffmiTrained => 'Trained';

  @override
  String get ffmiAdvanced => 'Advanced';

  @override
  String get ffmiElite => 'Near elite (not a hard cut-off)';

  @override
  String get bmrFormulaMale => 'Male: 10×weight + 6.25×height − 5×age + 5';

  @override
  String get bmrFormulaFemale =>
      'Female: 10×weight + 6.25×height − 5×age − 161';

  @override
  String loadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String addFailed(String error) {
    return 'Add failed: $error';
  }

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String clearFailed(String error) {
    return 'Clear failed: $error';
  }

  @override
  String checkUpdateFailed(String error) {
    return 'Update check failed: $error';
  }

  @override
  String cannotOpenApk(String message) {
    return 'Cannot open package: $message';
  }

  @override
  String workoutLoadFailed(String error) {
    return 'Workout load failed: $error';
  }

  @override
  String loadFoodsFailed(String error) {
    return 'Failed to load foods: $error';
  }

  @override
  String applyPresetFailed(String error) {
    return 'Apply failed: $error';
  }

  @override
  String aboutNWeeks(int weeks) {
    return '· ~$weeks wk';
  }

  @override
  String macroOverG(String g) {
    return 'Over $g g';
  }

  @override
  String macroRemainG(String g) {
    return '$g g left';
  }

  @override
  String kcalOver(String n) {
    return 'Over $n';
  }

  @override
  String kcalRemain(String n) {
    return '$n left';
  }

  @override
  String plateauHint(int days) {
    return 'Weight barely changed in $days days. Trim calories slightly, or add activity first.';
  }

  @override
  String cut100Applied(String kcal) {
    return 'Cut 100 kcal; daily intake $kcal';
  }

  @override
  String sectionCalories(String prefix) {
    return '$prefix calories';
  }

  @override
  String sectionLogs(String prefix) {
    return '$prefix logs';
  }

  @override
  String sectionWorkout(String prefix) {
    return '$prefix workout';
  }

  @override
  String deficitIntakeLine(String deficit, String intake) {
    return 'Deficit $deficit kcal · intake $intake kcal';
  }

  @override
  String alcoholExtraKcal(String kcal) {
    return 'Alcohol ≈ $kcal kcal extra';
  }

  @override
  String skippedItems(int n) {
    return ', skipped $n';
  }

  @override
  String copiedItems(int n, String skip) {
    return 'Copied $n$skip';
  }

  @override
  String skippedMissingFoods(int n) {
    return ', skipped $n missing foods';
  }

  @override
  String appliedPresetItems(int n, String skip) {
    return 'Applied $n$skip';
  }

  @override
  String loggedInto(String day) {
    return 'Logged to $day';
  }

  @override
  String logMealTitle(String day) {
    return 'Log meal · $day';
  }

  @override
  String confirmDeleteWeight(String date) {
    return 'Delete weight log for $date?';
  }

  @override
  String bodyFatPctLine(String pct) {
    return 'Body fat $pct%';
  }

  @override
  String weightLoggedSnack(String kcal) {
    return 'Weight saved; daily intake $kcal kcal';
  }

  @override
  String confirmDeletePlan(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String nSets(int n) {
    return '$n sets';
  }

  @override
  String setLine(String name, int index) {
    return '$name · set $index';
  }

  @override
  String nReps(int n) {
    return '$n reps';
  }

  @override
  String nSeconds(int n) {
    return '$n sec';
  }

  @override
  String nKinds(int n) {
    return '$n items';
  }

  @override
  String editSetsHint(int sets, String valueLabel) {
    return 'Target $sets sets · edit sets and $valueLabel';
  }

  @override
  String confirmDeleteNote(String title) {
    return 'Delete note for $title?';
  }

  @override
  String get deleteWorkoutItem => 'Delete exercise';

  @override
  String confirmDeleteWorkoutItem(String name) {
    return 'Remove \"$name\" from today\'s workout?';
  }

  @override
  String savedAt(String time) {
    return 'Saved · $time';
  }

  @override
  String charsUpdated(int chars, String time) {
    return '$chars chars · updated $time';
  }

  @override
  String waterDefaultHint(int ml) {
    return 'Leave blank for default $ml ml';
  }

  @override
  String quotaReadyBody(String kcal, String p, String c, String f) {
    return '$kcal kcal\nP $p · C $c · F $f\n\nDetails under Me → My profile.';
  }

  @override
  String alreadyLatest(String version) {
    return 'Already up to date ($version)';
  }

  @override
  String newVersionAsk(String version) {
    return 'New version $version. Download and install?';
  }

  @override
  String newVersionTitle(String version) {
    return 'New version $version';
  }

  @override
  String deficitLine(String kcal) {
    return 'Deficit $kcal kcal';
  }

  @override
  String weeklyLossLine(String kg) {
    return '· $kg kg/week';
  }

  @override
  String plateauAdjLine(String kcal) {
    return 'Plateau −$kcal kcal';
  }

  @override
  String profileSubtitle(
    String sex,
    int age,
    String height,
    String weight,
    String goal,
  ) {
    return '$sex · $age yr · $height cm · $weight kg · $goal';
  }

  @override
  String bfWrittenSnack(String pct) {
    return 'Saved $pct% body fat to today\'s weight log';
  }

  @override
  String whtrAboveRef(String ref) {
    return 'Above reference $ref';
  }

  @override
  String whtrRef(String ref) {
    return 'Reference $ref';
  }

  @override
  String alcoholWithKcal(String g, String kcal) {
    return 'Alcohol $g g (~$kcal kcal)';
  }

  @override
  String macroRule(String p) {
    return 'Protein $p g/kg · fat 0.8 g/kg · rest carbs';
  }

  @override
  String includesPlateauAdj(String kcal) {
    return 'Includes plateau −$kcal kcal';
  }

  @override
  String maintainLine(String kcal) {
    return 'Maintain: ≈ TDEE = $kcal kcal';
  }

  @override
  String bulkLine(String kcal) {
    return 'Bulk: TDEE × 1.1 = $kcal kcal';
  }

  @override
  String needLose(String kg) {
    return '(lose $kg)';
  }

  @override
  String dailyDeficitLine(String kcal) {
    return 'Daily deficit $kcal kcal';
  }

  @override
  String get narrowed => '(narrowed)';

  @override
  String shouldEat(String kcal) {
    return 'Eat $kcal kcal';
  }

  @override
  String tempEstimate80(String kcal) {
    return 'Temp estimate: TDEE × 80% = $kcal kcal';
  }

  @override
  String cutDefaultsToTdeeLine(String kcal) {
    return 'No fat-loss strategy set — eating at TDEE: $kcal kcal';
  }

  @override
  String kcalPerKgFatFact(String kcalPerKg) {
    return '$kcalPerKg kcal ≈ 1 kg of fat.';
  }

  @override
  String workoutProgressHint(int done, int total) {
    return 'Progress $done/$total · tap to edit · swipe to delete';
  }

  @override
  String setsProgress(int done, int total, String reps, String unit) {
    return '$done/$total sets · target $reps $unit';
  }

  @override
  String noteWeeklyLossTooHigh(String rate) {
    return 'Over 1 kg/week is not recommended (0.3–0.8 preferred). Adjusted to $rate kg/week.';
  }

  @override
  String noteWeeklyLossTooLow(String rate) {
    return 'Weekly loss raised to at least $rate kg/week.';
  }

  @override
  String noteDeficitCap(String max, String weekly, int weeks) {
    return 'Capped at $max kcal/day deficit. About $weekly kg/week; ~$weeks weeks.';
  }

  @override
  String noteEstimateWeeks(String kcalPerKg, String weekly, int weeks) {
    return '~$kcalPerKg kcal ≈ 1 kg fat, $weekly kg/week. About $weeks weeks.';
  }

  @override
  String noteEstimateWeeksShort(int weeks) {
    return 'About $weeks weeks to finish.';
  }

  @override
  String notePlateauAdj(String adj) {
    return 'Plateau adjustment applied: −$adj kcal/day.';
  }

  @override
  String estimatedWeeksAtRate(int weeks, String rate) {
    return '~$weeks weeks at $rate kg/week';
  }

  @override
  String get untitledWorkoutGroup => 'Other';

  @override
  String get removeDayWorkout => 'Remove this plan';

  @override
  String confirmRemoveDayWorkout(String name) {
    return 'Remove \"$name\" and all its exercises from today\'s workout?';
  }

  @override
  String get themeSubtitle => 'Appearance colors';

  @override
  String get themeGraphite => 'Graphite';

  @override
  String get expandSection => 'Expand';

  @override
  String get collapseSection => 'Collapse';

  @override
  String get noWorkoutShort => 'None planned';

  @override
  String get remainingWord => 'Remaining';

  @override
  String get overWord => 'Over';

  @override
  String get eatenWord => 'eaten';

  @override
  String eatenOfTarget(String eaten, String target) {
    return 'Eaten $eaten / target $target';
  }

  @override
  String waterAddMl(int ml) {
    return 'Add $ml ml water';
  }

  @override
  String waterUndoMl(int ml) {
    return 'Undo $ml ml water';
  }

  @override
  String mealsSummary(int count, String kcal) {
    return '$count items · $kcal kcal';
  }

  @override
  String get legacyTargetHint =>
      'Legacy estimate: this day predates per-day target records, so the target shown is derived from the current profile.';

  @override
  String get dietCompleteToggle => 'Today\'s food log is complete';

  @override
  String get dietCompleteHint =>
      'Only confirmed days count toward the taper review';

  @override
  String weeklyAvgLine(String kcal) {
    return 'Cycle avg $kcal kcal';
  }

  @override
  String get nutritionTargets => 'Nutrition targets';

  @override
  String nutritionComingSoonTitle(String goal) {
    return '\"$goal\" strategy is in the works';
  }

  @override
  String get nutritionComingSoonBody =>
      'The nutrition strategy for this goal is still being designed — stay tuned. Your profile\'s base target is used in the meantime.';

  @override
  String get dietStrategy => 'Fat-loss strategy';

  @override
  String get noStrategyShort => 'No strategy';

  @override
  String get strategySelectedShort => 'Selected';

  @override
  String get noStrategyYet =>
      'No strategy selected. Your profile target is used as-is until you choose one.';

  @override
  String get strategyOnlyForCut =>
      'Strategies apply to the cut goal only. Maintain / bulk keep the profile target.';

  @override
  String get chooseStrategy => 'Choose strategy';

  @override
  String get canChooseDietStrategy => 'Fat-loss strategy available';

  @override
  String get changeStrategy => 'Change strategy';

  @override
  String get adjustSchedule => 'Adjust schedule';

  @override
  String get stopStrategy => 'Stop strategy';

  @override
  String get stopStrategyBody =>
      'From today the profile target applies again. Past days keep the targets that were in effect.';

  @override
  String get strategyStopped => 'Strategy stopped';

  @override
  String get strategyApplied => 'Strategy saved';

  @override
  String planStartsOn(String date) {
    return 'Starts $date';
  }

  @override
  String planActiveSince(String date, int version) {
    return 'In effect since $date · v$version';
  }

  @override
  String planBaselineLine(String kg, String tdee, String e0) {
    return 'Ref. weight $kg kg · TDEE $tdee · avg target $e0 kcal';
  }

  @override
  String carbCyclePlanSummaryLine(String kg, String days, String e0) {
    return 'Ref. weight $kg kg · $days-day cycle · daily avg $e0 kcal';
  }

  @override
  String baseTargetLine(String kcal) {
    return 'Profile target $kcal kcal';
  }

  @override
  String get strategyBasisBody =>
      'TDEE is estimated with Mifflin–St Jeor × activity factor. Protein and fat are fixed per kg of reference weight; carbohydrate takes the remaining energy. Carb cycling redistributes the weekly budget across high / mid / low days with one common shrink factor so every day stays inside bounds and the weekly total is preserved. The taper lowers carbohydrate by 25 g (100 kcal) per stage.';

  @override
  String get strategyDisclaimer =>
      'Product defaults for generally healthy adults; not a clinical prescription and not medically validated. Consult a professional for medical conditions.';

  @override
  String get strategyScopeNote =>
      'Switching to maintain / bulk stops the strategy automatically. No extreme low-calorie, fasting or ketogenic presets are offered.';

  @override
  String get strategyPickerIntro =>
      'Choose one primary strategy. Protein and fat stay stable in all three; they differ in how carbohydrate and energy are arranged over time.';

  @override
  String get defaultWord => 'Recommended';

  @override
  String get currentWord => 'Current';

  @override
  String get strategyBalanced => 'Balanced deficit';

  @override
  String get strategyCarbCycle => 'Carb cycling';

  @override
  String get strategyCarbTaper => 'Carb taper';

  @override
  String get strategyBalancedDesc =>
      'Same energy and macros every day. Simple and easy to follow.';

  @override
  String get strategyCarbCycleDesc =>
      'A 3-5 day cycle you assign day by day (exactly one high-carb day); low/high-carb day macros scale directly from your reference weight, and any mid-carb day averages the two.';

  @override
  String get strategyCarbTaperDesc =>
      'Start at the baseline and lower carbohydrate one small step at a time; switch stages whenever you choose.';

  @override
  String get carbDayHigh => 'High-carb day';

  @override
  String get carbDayMid => 'Mid-carb day';

  @override
  String get carbDayLow => 'Low-carb day';

  @override
  String get carbDayHighShort => 'H';

  @override
  String get carbDayMidShort => 'M';

  @override
  String get carbDayLowShort => 'L';

  @override
  String taperStageLabel(int n) {
    return 'Stage $n';
  }

  @override
  String get targetSourceOverride => 'Custom target';

  @override
  String get targetSourceProfileCut => 'Cut · profile target';

  @override
  String get targetLegacyEstimate => 'Legacy estimate';

  @override
  String get issueInvalidWeight =>
      'Reference weight must be a positive number.';

  @override
  String get issueInvalidTdee =>
      'TDEE is unavailable; complete your profile first.';

  @override
  String get issueInvalidTargetEnergy =>
      'Target energy must be a positive number.';

  @override
  String get issueDeficitBelowRange =>
      'Deficit is below the 10% minimum for a fat-loss strategy.';

  @override
  String get issueDeficitAboveRange =>
      'Deficit exceeds the 20% self-service maximum.';

  @override
  String get issueEnergyBelowFloor =>
      'Energy would fall below the product floor (max(0.75×TDEE, 1201 kcal, P/F + 130 g carb)).';

  @override
  String get issueEnergyAboveTdee => 'Energy would exceed the estimated TDEE.';

  @override
  String issueCarbBelowMinimum(int g) {
    return 'Carbohydrate would fall below $g g/day; lower protein/fat per kg or reduce the deficit.';
  }

  @override
  String get issueInvalidSchedule => 'The cycle schedule is invalid.';

  @override
  String get issueInvalidCarbCycleRate =>
      'A low/high-day multiplier is outside the recommended range.';

  @override
  String get issueCarbCycleHighDayCarbDepleted =>
      'Too many mid-carb days for these rates — the high day would need negative carbs to keep the average steady. Lower the high-carb multiplier, raise the low-carb one, or use fewer mid days.';

  @override
  String issueUnderage(int age) {
    return 'Strategies are for adults ($age+). Please seek professional guidance instead.';
  }

  @override
  String get issueGoalNotCut => 'Only available with the cut goal.';

  @override
  String get strategyParameters => 'Parameters';

  @override
  String get referenceWeightKg => 'Reference weight';

  @override
  String get estimatedTdee => 'Estimated TDEE';

  @override
  String get deficitFractionLabel => 'Average deficit';

  @override
  String deficitFractionPercent(int pct) {
    return '$pct%';
  }

  @override
  String get averageTargetEnergy => 'Average target energy';

  @override
  String energyBoundsHint(int min, int max) {
    return 'Allowed $min–$max kcal';
  }

  @override
  String get proteinPerKgLabel => 'Protein per kg';

  @override
  String get carbPerKgLabel => 'Carb per kg';

  @override
  String get carbCycleAdjustedTooltip =>
      'Automatically adjusted to balance mid-carb days';

  @override
  String get fatPerKgLabel => 'Fat per kg';

  @override
  String get dailyBaselineTitle => 'Daily baseline';

  @override
  String get cycleSchedule => 'Cycle schedule';

  @override
  String referenceWeightFromProfile(String kg) {
    return 'Reference weight $kg kg (from your profile)';
  }

  @override
  String get cycleLengthLabel => 'Cycle length';

  @override
  String cycleLengthDaysOption(int n) {
    return '$n-day';
  }

  @override
  String get carbCycleEditHint =>
      'Every cycle has exactly one high-carb day. Tap it to move it to the other end of the cycle (first ↔ last) — the day it leaves becomes low-carb. Tap any other day to switch it between low- and mid-carb.';

  @override
  String get lowCarbDayRatesTitle => 'Low-carb day (per kg reference weight)';

  @override
  String get highCarbDayRatesTitle => 'High-carb day (per kg reference weight)';

  @override
  String weeklyBudgetLine(String total, String avg) {
    return 'Weekly budget $total kcal · daily average $avg kcal';
  }

  @override
  String get taperLadderTitle => 'Stage ladder (preview)';

  @override
  String get taperLadderHint =>
      'Each step is −25 g carbohydrate / −100 kcal. Once the strategy is active you can switch stages yourself anytime — no required waiting period.';

  @override
  String taperFloorLine(int kcal, int carb) {
    return 'Floor: $kcal kcal and $carb g carbohydrate';
  }

  @override
  String get currentStage => 'Current stage';

  @override
  String get effectiveDate => 'Effective date';

  @override
  String startTomorrow(String date) {
    return 'Tomorrow ($date)';
  }

  @override
  String get startToday => 'Start today';

  @override
  String applyStrategyFrom(String date) {
    return 'Apply from $date';
  }

  @override
  String get taperReview => 'Taper stages';

  @override
  String get taperNotActive => 'The carb taper is not active.';

  @override
  String get taperFreeChoiceHint =>
      'Switch to any stage anytime, at your own judgment — no observation period or review required.';

  @override
  String confirmNextStageBody(int kcal, String carb) {
    return 'From tomorrow the target becomes $kcal kcal with $carb g carbohydrate.';
  }

  @override
  String enterStage(int n) {
    return 'Enter stage $n';
  }

  @override
  String taperStageConfirmed(int n) {
    return 'Stage $n confirmed from tomorrow';
  }

  @override
  String get taperRulesBody =>
      'Rules: each step is −25 g carbohydrate / −100 kcal; never below the energy and 130 g carbohydrate floors.';

  @override
  String get cancelScheduledStrategy => 'Cancel scheduled change';

  @override
  String get cancelScheduledStrategyBody =>
      'The strategy that has not started yet is discarded. The strategy currently in effect keeps running.';

  @override
  String get scheduledStrategyCancelled => 'Scheduled change cancelled';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabHistory => 'History';

  @override
  String get tabRecent => 'Recent';

  @override
  String get filterAll => 'All';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get otherPlans => 'Other plans';

  @override
  String get exerciseSchedule => 'Exercises';

  @override
  String get startRecording => 'Start recording';

  @override
  String get continueRecording => 'Continue recording';

  @override
  String get viewDayRecords => 'View daily records';

  @override
  String get viewWorkoutDetails => 'View workout';

  @override
  String get dailyJournal => 'Daily journal';

  @override
  String get journalSubtitle => 'Reflect on training, food and how you feel';

  @override
  String get journalPrompt => 'How are you feeling today?';

  @override
  String get loadRecordsFailed => 'Unable to load records';

  @override
  String get discardChangesTitle => 'Discard unsaved changes?';

  @override
  String get sincePreviousRecord => 'Since previous record';

  @override
  String get stepsPermissionNeeded => 'Permission needed';

  @override
  String get stepsNotSynced => 'Not synced';

  @override
  String get appTagline => 'Track food, training and progress';

  @override
  String get selectDate => 'Select date';

  @override
  String get noWorkoutPlannedTitle => 'No workout planned yet';

  @override
  String get noWorkoutPlannedHint => 'Tap + to add your first workout plan';

  @override
  String get noMealsTitle => 'No meals logged yet';

  @override
  String get noMealsHint => 'Tap + to log today\'s first meal';

  @override
  String get recordStatusLabel => 'Record status';

  @override
  String get recordComplete => 'Fully logged';

  @override
  String get recordIncomplete => 'Not confirmed';

  @override
  String get mealNotLogged => 'Not logged';

  @override
  String get mealsRecordSection => 'Food log';

  @override
  String get noRecentFoods => 'No recent foods yet';

  @override
  String get removeFromRecent => 'Remove from recent';

  @override
  String confirmRemoveFromRecent(String name) {
    return 'Remove $name from your recent foods? Logging it again will bring it back.';
  }

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String confirmRemoveFavorite(String name) {
    return 'Remove $name from favorites?';
  }

  @override
  String get editKeywords => 'Edit keywords';

  @override
  String get createFood => 'New food';

  @override
  String charCount(int n) {
    return '$n characters';
  }

  @override
  String lastNDays(int n) {
    return '$n days';
  }

  @override
  String nExercises(int n) {
    return '$n exercises';
  }

  @override
  String planSummary(int exercises, int sets) {
    return '$exercises exercises · $sets sets';
  }

  @override
  String planProgress(String planName, int done, int total) {
    return '$planName · $done/$total';
  }

  @override
  String get viewWorkoutHistory => 'View workout history';

  @override
  String setsWithReps(int sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get recentSteps => 'Recent steps';

  @override
  String get allSteps => 'All steps';

  @override
  String get allWorkouts => 'All workouts';

  @override
  String get historyEmptyDay => 'None';

  @override
  String get saveThisSet => 'Save';

  @override
  String get adjustStrategy => 'Adjust strategy';

  @override
  String get cycleSummary => 'Cycle summary';

  @override
  String get carbDayType => 'Carb-day type';

  @override
  String get reviewPoints => 'Review points';

  @override
  String get dataPendingTitle => 'Data pending';

  @override
  String get dataPendingHint => 'Keep logging your weight';

  @override
  String get keepCurrentPlan => 'Keep current plan';

  @override
  String get addRecords => 'Add records';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get profileSectionBasics => 'Basics';

  @override
  String get profileSectionGoal => 'Goal';

  @override
  String get profileSectionOther => 'Other';

  @override
  String get profileSectionBasicsHint =>
      'Used to estimate your metabolism and metrics.';

  @override
  String get profileSectionGoalHint =>
      'Turns those numbers into your daily calorie and macro targets.';

  @override
  String get profileFieldSexHint =>
      'Sets which BMR and body-fat formula is used.';

  @override
  String get profileFieldAgeHint =>
      'Lowers the resting metabolic estimate as it rises.';

  @override
  String get profileFieldHeightHint =>
      'Feeds BMI, lean body mass and ideal-weight figures.';

  @override
  String get profileFieldWeightHint =>
      'The baseline for every calorie and macro target.';

  @override
  String get profileFieldActivityHint =>
      'Scales BMR into your total daily energy (TDEE).';

  @override
  String get profileFieldGoalHint =>
      'Chooses the calorie surplus or deficit and the protein target.';

  @override
  String get profileFieldWaterHint =>
      'The goal the water cup on the Today screen fills toward.';

  @override
  String get basalMetabolicRate => 'Basal metabolic rate (BMR)';

  @override
  String get totalDailyEnergy => 'Total daily energy (TDEE)';

  @override
  String get bmrMethodMifflin => 'Mifflin-St Jeor';

  @override
  String get bmrMethodKatch => 'Katch-McArdle · uses body fat';

  @override
  String bmrKatchFormula(String lbm, String bmr) {
    return '370 + 21.6 × $lbm kg lean mass = $bmr kcal';
  }

  @override
  String bmrMifflinFormula(
    String w,
    String h,
    int age,
    String sexTerm,
    String bmr,
  ) {
    return '10·$w + 6.25·$h − 5·$age $sexTerm = $bmr kcal';
  }

  @override
  String tdeeFormula(String bmr, String factor, String activity, String tdee) {
    return '$bmr kcal × $factor ($activity) = $tdee kcal';
  }

  @override
  String metricsFromProfile(String sex, int age, String activity) {
    return 'From your profile · $sex · $age yr · $activity';
  }

  @override
  String metricsFromProfileShort(String sex, int age) {
    return 'From your profile · $sex · $age yr';
  }

  @override
  String get toolboxTagline => 'Handy tools for your healthy routine';

  @override
  String get onboardingWelcomeCta => 'Get started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Finish setup';

  @override
  String onboardingStep(int step, int total) {
    return '$step/$total';
  }

  @override
  String get onboardingDataUseNote =>
      'We only use this to personalise your food and training plan — nothing else.';

  @override
  String get onboardingBasicTitle => 'Set up your info';

  @override
  String get onboardingGoalTitle => 'Choose your fitness goal';

  @override
  String get onboardingFeature1Title => 'Log your food';

  @override
  String get onboardingFeature1Sub => 'Track intake meal by meal';

  @override
  String get onboardingFeature2Title => 'Plan your training';

  @override
  String get onboardingFeature2Sub => 'Build plans, stay consistent';

  @override
  String get onboardingFeature3Title => 'See your progress';

  @override
  String get onboardingFeature3Sub => 'Keep logging, watch it change';

  @override
  String get goalCutDesc => 'Lose body fat for a leaner shape';

  @override
  String get goalMaintainDesc => 'Hold your current weight and shape';

  @override
  String get goalBulkDesc => 'Add muscle, build strength';

  @override
  String get profileTagline => 'Keep going — a better you is coming';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get cycleDayColumn => 'Date';

  @override
  String get targetKcalColumn => 'Target kcal';

  @override
  String get dailyAvgKcalLabel => 'Daily avg';

  @override
  String get hmlDayCountLabel => 'H / M / L days';

  @override
  String get servingSize => 'Serving size';

  @override
  String get nutritionResult => 'Nutrition';

  @override
  String mealAddedTo(String meal) {
    return 'Add to $meal';
  }

  @override
  String mealLoggedTo(String meal) {
    return 'Added to $meal';
  }

  @override
  String addMealNamed(String meal) {
    return 'Add $meal';
  }

  @override
  String get cultivationPageTitle => 'Cultivation';

  @override
  String get cultivationHeroLabel => 'My Realm';

  @override
  String get cultivationLockedTitle => 'Cultivation not yet unlocked';

  @override
  String get cultivationLockedBody =>
      'Cultivation only tracks progress under the \"Cut\" goal — every 7,700 kcal deficit becomes a step on your path. Switch to a cut goal to begin.';

  @override
  String get cultivationLockedCta => 'Switch to cut goal';

  @override
  String get cultivationMaxCaption => 'Divine Transformation · Perfected';

  @override
  String cultivationMaxSubcaption(String kg) {
    return '$kg kg lost or more · highest realm';
  }

  @override
  String cultivationNextLayerCaption(String kcal) {
    return '$kcal kcal to the next layer';
  }

  @override
  String cultivationNextRealmCaption(String kcal, String realm) {
    return '$kcal kcal to $realm';
  }

  @override
  String cultivationLostCaption(String kg) {
    return '$kg kg lost';
  }

  @override
  String cultivationStepsContribution(String kcal) {
    return 'Steps $kcal kcal';
  }

  @override
  String cultivationDietContribution(String kcal) {
    return 'Diet $kcal kcal';
  }

  @override
  String cultivationLayerBadge(String realm, String layer) {
    return '$realm · Layer $layer';
  }

  @override
  String get cultivationRealmQiRefining => 'Qi Refining';

  @override
  String get cultivationRealmFoundation => 'Foundation';

  @override
  String get cultivationRealmCoreFormation => 'Core Formation';

  @override
  String get cultivationRealmNascentSoul => 'Nascent Soul';

  @override
  String get cultivationRealmDivineTransformation => 'Divine Transformation';

  @override
  String get cultivationSideHistory => 'History';

  @override
  String get cultivationSideRealmGuide => 'Realm guide';

  @override
  String get cultivationSideSettings => 'Settings';

  @override
  String cultivationGoalLockedTitle(String goal) {
    return '$goal cultivation not yet unlocked';
  }

  @override
  String cultivationGoalLockedBody(String goal, String activeGoal) {
    return 'Your current goal is \"$activeGoal\" — $goal cultivation only opens for users on the \"$goal\" goal.';
  }

  @override
  String get cultivationGoalLockedCta => 'Go to settings';

  @override
  String cultivationComingSoonTitle(String goal) {
    return '$goal cultivation is being crafted';
  }

  @override
  String get cultivationComingSoonBody =>
      'This path\'s own realm system is still being designed — check back soon.';

  @override
  String get cultivationPickerTitle => 'Choose a realm';

  @override
  String get cultivationPickerActiveBadge => 'Active';

  @override
  String get cultivationPickerLockedBadge => 'Locked';

  @override
  String get cultivationPickerTaglineMaintain => 'A calm mind, day after day';

  @override
  String get cultivationPickerTaglineCut =>
      'Even a mortal\'s first step is cultivation';

  @override
  String get cultivationPickerTaglineBulk => 'Forge the body, surpass the self';

  @override
  String get realmGuideTitle => 'Realm system';

  @override
  String get realmGuideIntro =>
      'Every 7,700 kcal deficit ≈ 1 kg lost. Reach the cumulative weight-loss threshold shown for each realm to break through to the next — each realm is further divided into 9 layers.';

  @override
  String realmGuideRangeLine(String floor, String ceil, String kcal) {
    return '$floor–$ceil kg · $kcal kcal per layer';
  }

  @override
  String realmGuideMaxRangeLine(String floor) {
    return '≥ $floor kg · Fulfilled — no further breakthrough';
  }

  @override
  String realmGuideNextThresh(String realm, String kg) {
    return '→ $realm ${kg}kg';
  }

  @override
  String get realmGuideTagDone => 'Passed';

  @override
  String realmGuideTagCurrent(String layer) {
    return 'Current · Layer $layer';
  }

  @override
  String get realmGuideTagLocked => 'Locked';

  @override
  String get realmGuideTagLockedMax => 'Locked · Highest realm';

  @override
  String get realmGuideFootnoteTitle => 'kcal sources:';

  @override
  String get realmGuideFootnoteBody =>
      '① Steps × 0.04 kcal/step; ② diet, counted only when at least 2 distinct meal types are logged that day (breakfast/lunch/dinner/snack) — diet contribution = today\'s TDEE − today\'s intake (eating less yields a larger surplus; exceeding TDEE yields a negative setback).';

  @override
  String get realmGuideFootnoteNote =>
      'This feature is currently only available to users on the \"Cut\" goal.';

  @override
  String get cultivationHistoryTitle => 'Cultivation log';

  @override
  String get cultivationHistoryEmpty => 'No records yet';

  @override
  String get cultivationHistoryTodayLabel => 'Today';

  @override
  String get cultivationHistoryStepsLabel => 'Steps';

  @override
  String get cultivationHistoryDietLabel => 'Diet';

  @override
  String get cultivationHistoryTotalLabel => 'Total';

  @override
  String get cultivationHistoryWorkoutLabel => 'Training';

  @override
  String cultivationHistoryWorkoutProgress(String done, String total) {
    return '$done/$total';
  }

  @override
  String get editTrainingRecord => 'Edit training record';

  @override
  String get saveTrainingRecord => 'Save training record';

  @override
  String get addTrainingNote => 'Add note';

  @override
  String get trainingRepsPerSet => 'Reps per set';

  @override
  String get trainingSecondsPerSet => 'Seconds per set';

  @override
  String get decreaseCompletedSets => 'Decrease completed sets';

  @override
  String get increaseCompletedSets => 'Increase completed sets';

  @override
  String get decreasePerSetValue => 'Decrease per-set value';

  @override
  String get increasePerSetValue => 'Increase per-set value';

  @override
  String trainingSetTarget(int sets) {
    return 'Today’s target · $sets sets';
  }

  @override
  String trainingSetDenominator(int sets) {
    return '/ $sets sets';
  }
}
