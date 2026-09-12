import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get appTitle;

  /// No description provided for @loadingTitleLeft.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get loadingTitleLeft;

  /// No description provided for @loadingTitleRight.
  ///
  /// In en, this message translates to:
  /// **'Freedom'**
  String get loadingTitleRight;

  /// No description provided for @loadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every effort brings you closer to freedom'**
  String get loadingSubtitle;

  /// No description provided for @loadingPreparingPlan.
  ///
  /// In en, this message translates to:
  /// **'Preparing today\'s plan'**
  String get loadingPreparingPlan;

  /// No description provided for @loadingPreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'Preparation failed. Please try again'**
  String get loadingPreparationFailed;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @append.
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get append;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @leaveBlank.
  ///
  /// In en, this message translates to:
  /// **'Leave blank'**
  String get leaveBlank;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get writing;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsaved;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculating;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing…'**
  String get timing;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageUnit.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get ageUnit;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get currentWeight;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get targetWeight;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get activityLevel;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @weeklyLossTarget.
  ///
  /// In en, this message translates to:
  /// **'Weekly loss target'**
  String get weeklyLossTarget;

  /// No description provided for @weeklyLossHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended 0.3–0.8 kg/week'**
  String get weeklyLossHint;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @mealType.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealType;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get grams;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @alcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get alcohol;

  /// No description provided for @proteinShort.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinShort;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get unfavorite;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @searchFood.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get searchFood;

  /// No description provided for @noFoodFound.
  ///
  /// In en, this message translates to:
  /// **'No foods found'**
  String get noFoodFound;

  /// No description provided for @commonPortions.
  ///
  /// In en, this message translates to:
  /// **'Common portions'**
  String get commonPortions;

  /// No description provided for @logMeal.
  ///
  /// In en, this message translates to:
  /// **'Log meal'**
  String get logMeal;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @toolbox.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get toolbox;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @foods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get foods;

  /// No description provided for @todayWord.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayWord;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @targetSets.
  ///
  /// In en, this message translates to:
  /// **'Target sets'**
  String get targetSets;

  /// No description provided for @targetReps.
  ///
  /// In en, this message translates to:
  /// **'Target reps'**
  String get targetReps;

  /// No description provided for @targetSeconds.
  ///
  /// In en, this message translates to:
  /// **'Target seconds'**
  String get targetSeconds;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get reps;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get seconds;

  /// No description provided for @repsCount.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsCount;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteRecord;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Daily records'**
  String get history;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @bodyFatPct.
  ///
  /// In en, this message translates to:
  /// **'Body fat %'**
  String get bodyFatPct;

  /// No description provided for @neck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get neck;

  /// No description provided for @waist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get waist;

  /// No description provided for @hip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get hip;

  /// No description provided for @portion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portion;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get completed;

  /// No description provided for @goFillIn.
  ///
  /// In en, this message translates to:
  /// **'Fill in'**
  String get goFillIn;

  /// No description provided for @goRecords.
  ///
  /// In en, this message translates to:
  /// **'Go to Records'**
  String get goRecords;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get startUsing;

  /// No description provided for @startWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get startWriting;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdate;

  /// No description provided for @downloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & install'**
  String get downloadInstall;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear data'**
  String get clearData;

  /// No description provided for @calcMethod.
  ///
  /// In en, this message translates to:
  /// **'How it\'s calculated'**
  String get calcMethod;

  /// No description provided for @dailyQuota.
  ///
  /// In en, this message translates to:
  /// **'Daily targets'**
  String get dailyQuota;

  /// No description provided for @foodLibrary.
  ///
  /// In en, this message translates to:
  /// **'Food library'**
  String get foodLibrary;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavorites;

  /// No description provided for @categoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No foods in this category'**
  String get categoryEmpty;

  /// No description provided for @foodNotFound.
  ///
  /// In en, this message translates to:
  /// **'Food not found'**
  String get foodNotFound;

  /// No description provided for @foodNotFoundShort.
  ///
  /// In en, this message translates to:
  /// **'Food not found'**
  String get foodNotFoundShort;

  /// No description provided for @recordNotFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get recordNotFound;

  /// No description provided for @invalidFood.
  ///
  /// In en, this message translates to:
  /// **'Invalid food'**
  String get invalidFood;

  /// No description provided for @invalidRecord.
  ///
  /// In en, this message translates to:
  /// **'Invalid record'**
  String get invalidRecord;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get per100g;

  /// No description provided for @nutritionIntake.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionIntake;

  /// No description provided for @convertResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get convertResult;

  /// No description provided for @recentlyEaten.
  ///
  /// In en, this message translates to:
  /// **'Recently eaten'**
  String get recentlyEaten;

  /// No description provided for @badgeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get badgeRecent;

  /// No description provided for @badgeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Fav'**
  String get badgeFavorite;

  /// No description provided for @mealPresets.
  ///
  /// In en, this message translates to:
  /// **'Meal presets'**
  String get mealPresets;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get saveAsPreset;

  /// No description provided for @presetSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved'**
  String get presetSaved;

  /// No description provided for @saveAsPlan.
  ///
  /// In en, this message translates to:
  /// **'Save as workout plan'**
  String get saveAsPlan;

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout plan saved'**
  String get planSaved;

  /// No description provided for @noWorkoutToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save for this day'**
  String get noWorkoutToSave;

  /// No description provided for @copyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Copy yesterday'**
  String get copyYesterday;

  /// No description provided for @backfillMeal.
  ///
  /// In en, this message translates to:
  /// **'Backfill'**
  String get backfillMeal;

  /// No description provided for @prevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prevDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @cut100Kcal.
  ///
  /// In en, this message translates to:
  /// **'Cut 100 kcal'**
  String get cut100Kcal;

  /// No description provided for @walk3000Btn.
  ///
  /// In en, this message translates to:
  /// **'+~3000 steps'**
  String get walk3000Btn;

  /// No description provided for @walk3000Snack.
  ///
  /// In en, this message translates to:
  /// **'Try ~3000 extra steps/day first.'**
  String get walk3000Snack;

  /// No description provided for @cutAdjCapReached.
  ///
  /// In en, this message translates to:
  /// **'Adjustment limit reached'**
  String get cutAdjCapReached;

  /// No description provided for @possiblePlateau.
  ///
  /// In en, this message translates to:
  /// **'Possible plateau'**
  String get possiblePlateau;

  /// No description provided for @cutPlanIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Cut plan incomplete'**
  String get cutPlanIncomplete;

  /// No description provided for @noLogsToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save for this day'**
  String get noLogsToSave;

  /// No description provided for @yesterdayNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yesterday'**
  String get yesterdayNoLogs;

  /// No description provided for @emptyMealsToday.
  ///
  /// In en, this message translates to:
  /// **'No logs yet — tap + to log'**
  String get emptyMealsToday;

  /// No description provided for @emptyMealsThatDay.
  ///
  /// In en, this message translates to:
  /// **'No logs that day (view only)'**
  String get emptyMealsThatDay;

  /// No description provided for @noMealsThatDay.
  ///
  /// In en, this message translates to:
  /// **'No meals logged that day'**
  String get noMealsThatDay;

  /// No description provided for @emptyWeightLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yet — tap + to add'**
  String get emptyWeightLogs;

  /// No description provided for @pastDayReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Past days are view-only'**
  String get pastDayReadOnly;

  /// No description provided for @chartWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get chartWeightTitle;

  /// No description provided for @chartWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weight data'**
  String get chartWeightEmpty;

  /// No description provided for @chartBfTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat (%)'**
  String get chartBfTitle;

  /// No description provided for @chartBfEmpty.
  ///
  /// In en, this message translates to:
  /// **'No body-fat logs'**
  String get chartBfEmpty;

  /// No description provided for @logWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get logWeightTitle;

  /// No description provided for @fabLogWeight.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get fabLogWeight;

  /// No description provided for @fabNewPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get fabNewPlan;

  /// No description provided for @fabWriteNote.
  ///
  /// In en, this message translates to:
  /// **'Write note'**
  String get fabWriteNote;

  /// No description provided for @segmentBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get segmentBody;

  /// No description provided for @segmentTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get segmentTrain;

  /// No description provided for @segmentNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get segmentNotes;

  /// No description provided for @customExercise.
  ///
  /// In en, this message translates to:
  /// **'Custom exercise'**
  String get customExercise;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseName;

  /// No description provided for @repsOrSeconds.
  ///
  /// In en, this message translates to:
  /// **'Reps / sec'**
  String get repsOrSeconds;

  /// No description provided for @exerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise library'**
  String get exerciseLibrary;

  /// No description provided for @noExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// No description provided for @exerciseCategoryChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get exerciseCategoryChest;

  /// No description provided for @exerciseCategoryBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get exerciseCategoryBack;

  /// No description provided for @exerciseCategoryShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get exerciseCategoryShoulders;

  /// No description provided for @exerciseCategoryArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get exerciseCategoryArms;

  /// No description provided for @exerciseCategoryLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get exerciseCategoryLegs;

  /// No description provided for @exerciseCategoryCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get exerciseCategoryCore;

  /// No description provided for @exerciseCategoryCoreTimed.
  ///
  /// In en, this message translates to:
  /// **'Core (timed)'**
  String get exerciseCategoryCoreTimed;

  /// No description provided for @exerciseCategoryCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get exerciseCategoryCardio;

  /// No description provided for @exerciseCategoryShouldersArms.
  ///
  /// In en, this message translates to:
  /// **'Shoulders & arms'**
  String get exerciseCategoryShouldersArms;

  /// No description provided for @exerciseCategoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get exerciseCategoryCustom;

  /// No description provided for @exerciseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get exerciseCategoryOther;

  /// No description provided for @workoutPlans.
  ///
  /// In en, this message translates to:
  /// **'Workout plans'**
  String get workoutPlans;

  /// No description provided for @emptyPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans yet — tap + to create'**
  String get emptyPlans;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deletePlan;

  /// No description provided for @noExercisesInPlan.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercisesInPlan;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get workoutHistory;

  /// No description provided for @stepHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily steps'**
  String get stepHistory;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @nSteps.
  ///
  /// In en, this message translates to:
  /// **'{n} steps'**
  String nSteps(int n);

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiber;

  /// No description provided for @sodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get sodium;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @saturatedFat.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat'**
  String get saturatedFat;

  /// No description provided for @calcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get calcium;

  /// No description provided for @fiberG.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get fiberG;

  /// No description provided for @sodiumMg.
  ///
  /// In en, this message translates to:
  /// **'Sodium (mg)'**
  String get sodiumMg;

  /// No description provided for @sugarG.
  ///
  /// In en, this message translates to:
  /// **'Sugar (g)'**
  String get sugarG;

  /// No description provided for @saturatedFatG.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat (g)'**
  String get saturatedFatG;

  /// No description provided for @calciumMg.
  ///
  /// In en, this message translates to:
  /// **'Calcium (mg)'**
  String get calciumMg;

  /// No description provided for @fiberGOptional.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g, optional)'**
  String get fiberGOptional;

  /// No description provided for @sodiumMgOptional.
  ///
  /// In en, this message translates to:
  /// **'Sodium (mg, optional)'**
  String get sodiumMgOptional;

  /// No description provided for @sugarGOptional.
  ///
  /// In en, this message translates to:
  /// **'Sugar (g, optional)'**
  String get sugarGOptional;

  /// No description provided for @saturatedFatGOptional.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat (g, optional)'**
  String get saturatedFatGOptional;

  /// No description provided for @calciumMgOptional.
  ///
  /// In en, this message translates to:
  /// **'Calcium (mg, optional)'**
  String get calciumMgOptional;

  /// No description provided for @stepsStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'System steps synced'**
  String get stepsStatusConnected;

  /// No description provided for @stepsStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Physical activity permission not granted'**
  String get stepsStatusDenied;

  /// No description provided for @stepsStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connected, but 0 steps read for today'**
  String get stepsStatusEmpty;

  /// No description provided for @stepsStatusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Step sync is not supported on this platform'**
  String get stepsStatusUnsupported;

  /// No description provided for @stepsStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing steps…'**
  String get stepsStatusSyncing;

  /// No description provided for @stepsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Step sync failed'**
  String get stepsStatusFailed;

  /// No description provided for @stepsStatusRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get stepsStatusRetryHint;

  /// No description provided for @stepsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Step sync'**
  String get stepsSheetTitle;

  /// No description provided for @stepsSheetSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s steps are the larger of Health Connect and the phone\'s step sensor. On OPPO, Xiaomi and similar phones the system health app does not share steps with third parties; without Health Connect data, the sensor counts from first authorization, earlier steps that day cannot be recovered, and days align automatically from the next day.'**
  String get stepsSheetSourceHint;

  /// No description provided for @stepsSheetEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'If your system health app shows steps but this is 0: allow this app to read steps in Health Connect and enable data sharing in the health app; otherwise walk a bit and come back to this page.'**
  String get stepsSheetEmptyHint;

  /// No description provided for @stepsSheetDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Grant the Physical activity permission to this app in system settings, then resync.'**
  String get stepsSheetDeniedHint;

  /// No description provided for @stepsSheetResync.
  ///
  /// In en, this message translates to:
  /// **'Resync'**
  String get stepsSheetResync;

  /// No description provided for @stepsSheetOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open health / permission settings'**
  String get stepsSheetOpenSettings;

  /// No description provided for @stepsSheetDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get stepsSheetDiagnostics;

  /// No description provided for @stepsSheetDiagnosticsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stepsSheetDiagnosticsLoading;

  /// No description provided for @stepsServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Count steps in the background'**
  String get stepsServiceTitle;

  /// No description provided for @stepsServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Shows an ongoing notification and keeps counting even when the system limits background apps — the reliable option on OPPO, Xiaomi and similar phones.'**
  String get stepsServiceHint;

  /// No description provided for @noSetLogs.
  ///
  /// In en, this message translates to:
  /// **'No set logs'**
  String get noSetLogs;

  /// No description provided for @addExercisesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add exercises on the Records page first'**
  String get addExercisesFirst;

  /// No description provided for @addExercisesFirstShort.
  ///
  /// In en, this message translates to:
  /// **'Add exercises first'**
  String get addExercisesFirstShort;

  /// No description provided for @addTodayExercise.
  ///
  /// In en, this message translates to:
  /// **'Add today\'s exercise'**
  String get addTodayExercise;

  /// No description provided for @planNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a plan name'**
  String get planNameRequired;

  /// No description provided for @selectOneExercise.
  ///
  /// In en, this message translates to:
  /// **'Select at least one exercise'**
  String get selectOneExercise;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlan;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get editPlan;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planName;

  /// No description provided for @planNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Upper-body bodyweight'**
  String get planNameHint;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Duration (sec)'**
  String get durationSeconds;

  /// No description provided for @completedSets.
  ///
  /// In en, this message translates to:
  /// **'Completed sets'**
  String get completedSets;

  /// No description provided for @notesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Log training feel, sleep, or diet deviations'**
  String get notesEmptyHint;

  /// No description provided for @notesEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Tap + to start writing'**
  String get notesEmptyCta;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s training feel, sleep, or diet…'**
  String get noteHint;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Profile has unsaved edits. What next?'**
  String get unsavedChangesBody;

  /// No description provided for @dailyWaterGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily water goal'**
  String get dailyWaterGoal;

  /// No description provided for @quotaReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily targets ready'**
  String get quotaReadyTitle;

  /// No description provided for @createProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your profile'**
  String get createProfileTitle;

  /// No description provided for @createProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your stats to generate daily calorie and macro targets.'**
  String get createProfileHint;

  /// No description provided for @calculateAndStart.
  ///
  /// In en, this message translates to:
  /// **'Calculate & start'**
  String get calculateAndStart;

  /// No description provided for @addCommonPortion.
  ///
  /// In en, this message translates to:
  /// **'Add portion'**
  String get addCommonPortion;

  /// No description provided for @portionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 bowl / 500 ml bottle'**
  String get portionNameHint;

  /// No description provided for @deleteCustomFood.
  ///
  /// In en, this message translates to:
  /// **'Delete custom food'**
  String get deleteCustomFood;

  /// No description provided for @deleteCustomFoodBody.
  ///
  /// In en, this message translates to:
  /// **'Delete? Past logs keep the name.'**
  String get deleteCustomFoodBody;

  /// No description provided for @noPortionsHint.
  ///
  /// In en, this message translates to:
  /// **'None yet — quick-pick when logging'**
  String get noPortionsHint;

  /// No description provided for @customFoodAdded.
  ///
  /// In en, this message translates to:
  /// **'Custom food added'**
  String get customFoodAdded;

  /// No description provided for @editCustomFood.
  ///
  /// In en, this message translates to:
  /// **'Edit custom food'**
  String get editCustomFood;

  /// No description provided for @addCustomFood.
  ///
  /// In en, this message translates to:
  /// **'Add custom food'**
  String get addCustomFood;

  /// No description provided for @per100gNutrition.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g nutrition'**
  String get per100gNutrition;

  /// No description provided for @kcalField.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get kcalField;

  /// No description provided for @kjField.
  ///
  /// In en, this message translates to:
  /// **'Calories (kJ)'**
  String get kjField;

  /// No description provided for @proteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinG;

  /// No description provided for @carbG.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbG;

  /// No description provided for @fatG.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatG;

  /// No description provided for @alcoholGOptional.
  ///
  /// In en, this message translates to:
  /// **'Alcohol (g, optional)'**
  String get alcoholGOptional;

  /// No description provided for @selectFoodAndGrams.
  ///
  /// In en, this message translates to:
  /// **'Select a food and grams'**
  String get selectFoodAndGrams;

  /// No description provided for @mealDateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Meals only within the past year through today'**
  String get mealDateRangeError;

  /// No description provided for @searchToLog.
  ///
  /// In en, this message translates to:
  /// **'Search a food to start logging'**
  String get searchToLog;

  /// No description provided for @confirmDeleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get confirmDeleteMeal;

  /// No description provided for @toolBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body-fat estimate'**
  String get toolBodyFat;

  /// No description provided for @toolBodyFatSub.
  ///
  /// In en, this message translates to:
  /// **'US Navy circumference method'**
  String get toolBodyFatSub;

  /// No description provided for @toolBodyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Body metrics'**
  String get toolBodyMetrics;

  /// No description provided for @toolBodyMetricsSub.
  ///
  /// In en, this message translates to:
  /// **'BMI, ideal weight, WHtR, FFMI'**
  String get toolBodyMetricsSub;

  /// No description provided for @toolFoodConvert.
  ///
  /// In en, this message translates to:
  /// **'Food convert'**
  String get toolFoodConvert;

  /// No description provided for @toolFoodConvertSub.
  ///
  /// In en, this message translates to:
  /// **'Convert macros by grams'**
  String get toolFoodConvertSub;

  /// No description provided for @toolRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get toolRestTimer;

  /// No description provided for @toolRestTimerSub.
  ///
  /// In en, this message translates to:
  /// **'Between-set timer with lock-screen alerts'**
  String get toolRestTimerSub;

  /// No description provided for @toolCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get toolCalculator;

  /// No description provided for @toolCalculatorSub.
  ///
  /// In en, this message translates to:
  /// **'Basic arithmetic'**
  String get toolCalculatorSub;

  /// No description provided for @toolEnergyConvert.
  ///
  /// In en, this message translates to:
  /// **'kcal / kJ convert'**
  String get toolEnergyConvert;

  /// No description provided for @toolEnergyConvertSub.
  ///
  /// In en, this message translates to:
  /// **'Convert energy between kcal and kJ'**
  String get toolEnergyConvertSub;

  /// No description provided for @toolsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Results are not saved to profile or meal logs by default.'**
  String get toolsDisclaimer;

  /// No description provided for @bfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'US Navy estimate — not a scale/DEXA reading.'**
  String get bfDisclaimer;

  /// No description provided for @abdomenWaist.
  ///
  /// In en, this message translates to:
  /// **'Abdomen (waist)'**
  String get abdomenWaist;

  /// No description provided for @estimatedBf.
  ///
  /// In en, this message translates to:
  /// **'Estimated body fat'**
  String get estimatedBf;

  /// No description provided for @bfCircumferenceError.
  ///
  /// In en, this message translates to:
  /// **'Check measurements: waist/abdomen must exceed neck.'**
  String get bfCircumferenceError;

  /// No description provided for @writeBfToWeight.
  ///
  /// In en, this message translates to:
  /// **'Save BF% to today\'s weight log'**
  String get writeBfToWeight;

  /// No description provided for @bfNoWeightLog.
  ///
  /// In en, this message translates to:
  /// **'No weight log today — log weight first'**
  String get bfNoWeightLog;

  /// No description provided for @metricsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local estimates only; won\'t change your profile. Tap to expand formulas.'**
  String get metricsLocalOnly;

  /// No description provided for @bodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get bodyFat;

  /// No description provided for @idealWeightDevine.
  ///
  /// In en, this message translates to:
  /// **'Ideal weight (Devine)'**
  String get idealWeightDevine;

  /// No description provided for @whtr.
  ///
  /// In en, this message translates to:
  /// **'Waist-to-height'**
  String get whtr;

  /// No description provided for @leanMass.
  ///
  /// In en, this message translates to:
  /// **'Lean mass'**
  String get leanMass;

  /// No description provided for @normalizedFfmi.
  ///
  /// In en, this message translates to:
  /// **'Normalized FFMI'**
  String get normalizedFfmi;

  /// No description provided for @normalizedFfmiUnit.
  ///
  /// In en, this message translates to:
  /// **'Adjusted to 1.8 m'**
  String get normalizedFfmiUnit;

  /// No description provided for @ffmiNeedBf.
  ///
  /// In en, this message translates to:
  /// **'FFMI: enter valid body fat (0–100%).'**
  String get ffmiNeedBf;

  /// No description provided for @bmiFormula.
  ///
  /// In en, this message translates to:
  /// **'BMI = weight(kg) ÷ height(m)²\n= {weight} ÷ {heightM}²\n= {bmi}\n\nWHO categories:\nUnderweight < 18.5 · Normal 18.5–24.9\nOverweight 25–29.9 · Obese ≥ 30'**
  String bmiFormula(String weight, String heightM, String bmi);

  /// No description provided for @idealWeightFormula.
  ///
  /// In en, this message translates to:
  /// **'Devine formula ({sex})\nHeight = {heightCm} cm ≈ {heightIn} in\nIdeal weight = {base} + 2.3 × (height inches − 60)\n= {base} + 2.3 × {inchesOver}\n= {ideal} kg\n\nBelow 5 ft (152.4 cm), use base {base} kg.'**
  String idealWeightFormula(
    String sex,
    String heightCm,
    String heightIn,
    String base,
    String inchesOver,
    String ideal,
  );

  /// No description provided for @whtrFormula.
  ///
  /// In en, this message translates to:
  /// **'WHtR = waist(cm) ÷ height(cm)\n= {waist} ÷ {heightCm}\n= {whtr}\n\nLower is generally better (within reason)\n≤ {ref}: healthier reference; clearly above: often higher abdominal-fat risk.'**
  String whtrFormula(String waist, String heightCm, String whtr, String ref);

  /// No description provided for @whtrAboveNow.
  ///
  /// In en, this message translates to:
  /// **'\n\nCurrently above the reference line.'**
  String get whtrAboveNow;

  /// No description provided for @leanMassFormula.
  ///
  /// In en, this message translates to:
  /// **'Fat-free mass FFM = weight × (1 − body fat%)\n= {weight} × (1 − {bf}%)\n= {ffm} kg'**
  String leanMassFormula(String weight, String bf, String ffm);

  /// No description provided for @ffmiFormula.
  ///
  /// In en, this message translates to:
  /// **'FFMI = FFM(kg) ÷ height(m)²\n= {ffm} ÷ {heightM}²\n= {ffmi}\n\nAdult male rough guide:\n<19 average · 19–21 trained\n22–23 advanced · ≥24 elite reference\nWomen usually ~3–5 lower; not a hard standard.'**
  String ffmiFormula(String ffm, String heightM, String ffmi);

  /// No description provided for @normalizedFfmiFormula.
  ///
  /// In en, this message translates to:
  /// **'Normalized FFMI = FFMI + 6.1 × (1.8 − height_m)\n= {ffmi} + 6.1 × (1.8 − {heightM})\n= {normFfmi}\n\nAdjusts for height away from 1.8 m for comparability.'**
  String normalizedFfmiFormula(String ffmi, String heightM, String normFfmi);

  /// No description provided for @foodConvertHint.
  ///
  /// In en, this message translates to:
  /// **'Search a food, or favorite items in the library for quick pick.'**
  String get foodConvertHint;

  /// No description provided for @restNotifyPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Without notification permission, lock-screen alerts may not fire; foreground timer still works.'**
  String get restNotifyPermissionHint;

  /// No description provided for @restDoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Rest over — next set'**
  String get restDoneSnack;

  /// No description provided for @restTimerIntro.
  ///
  /// In en, this message translates to:
  /// **'Between-set countdown. With notifications, alerts work on lock screen / background.'**
  String get restTimerIntro;

  /// No description provided for @workoutReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to train'**
  String get workoutReminderTitle;

  /// No description provided for @workoutReminderBodyNormal.
  ///
  /// In en, this message translates to:
  /// **'Log a set today and keep the streak going.'**
  String get workoutReminderBodyNormal;

  /// No description provided for @workoutReminderBodyEncourage.
  ///
  /// In en, this message translates to:
  /// **'Missed yesterday? No worries — move today and you’ll feel better.'**
  String get workoutReminderBodyEncourage;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workout, water, meals and weigh-in'**
  String get remindersSubtitle;

  /// No description provided for @workoutReminderTile.
  ///
  /// In en, this message translates to:
  /// **'Daily workout reminder'**
  String get workoutReminderTile;

  /// No description provided for @workoutReminderSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on to get a daily training nudge'**
  String get workoutReminderSubtitleOff;

  /// No description provided for @workoutReminderSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String workoutReminderSubtitleOn(String time);

  /// No description provided for @workoutReminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied; daily reminder stays off.'**
  String get workoutReminderPermissionDenied;

  /// No description provided for @reminderWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get reminderWaterTitle;

  /// No description provided for @reminderWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Time for a glass of water.'**
  String get reminderWaterBody;

  /// No description provided for @reminderMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your meals'**
  String get reminderMealTitle;

  /// No description provided for @reminderMealBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to record what you ate today.'**
  String get reminderMealBody;

  /// No description provided for @reminderWeighInTitle.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get reminderWeighInTitle;

  /// No description provided for @reminderWeighInBody.
  ///
  /// In en, this message translates to:
  /// **'Step on the scale and log your weight.'**
  String get reminderWeighInBody;

  /// No description provided for @reminderKindWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get reminderKindWorkout;

  /// No description provided for @reminderKindWater.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get reminderKindWater;

  /// No description provided for @reminderKindMeal.
  ///
  /// In en, this message translates to:
  /// **'Log meals'**
  String get reminderKindMeal;

  /// No description provided for @reminderKindWeighIn.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get reminderKindWeighIn;

  /// No description provided for @reminderKindWorkoutDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily nudge to train'**
  String get reminderKindWorkoutDesc;

  /// No description provided for @reminderKindWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'A reminder to hydrate'**
  String get reminderKindWaterDesc;

  /// No description provided for @reminderKindMealDesc.
  ///
  /// In en, this message translates to:
  /// **'A nudge to record your food'**
  String get reminderKindMealDesc;

  /// No description provided for @reminderKindWeighInDesc.
  ///
  /// In en, this message translates to:
  /// **'A morning reminder to weigh in'**
  String get reminderKindWeighInDesc;

  /// No description provided for @reminderDailyAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String reminderDailyAt(String time);

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @reminderRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeatLabel;

  /// No description provided for @reminderAlertModeRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get reminderAlertModeRing;

  /// No description provided for @reminderAlertModeVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get reminderAlertModeVibrate;

  /// No description provided for @reminderSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get reminderSoundLabel;

  /// No description provided for @reminderSoundDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get reminderSoundDefault;

  /// No description provided for @weekdayLettersMonSun.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekdayLettersMonSun;

  /// No description provided for @notificationPermissionRow.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationPermissionRow;

  /// No description provided for @notificationPermissionOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationPermissionOn;

  /// No description provided for @notificationPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so reminders are delivered.'**
  String get notificationPermissionHint;

  /// No description provided for @customDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom (0:30–10:00)'**
  String get customDuration;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Between-set rest alerts'**
  String get notifChannelDesc;

  /// No description provided for @restDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest over'**
  String get restDoneTitle;

  /// No description provided for @restDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Start next set'**
  String get restDoneBody;

  /// No description provided for @restTimerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get restTimerReady;

  /// No description provided for @restTimerRunning.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get restTimerRunning;

  /// No description provided for @restTimerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get restTimerPaused;

  /// No description provided for @restTimerFinished.
  ///
  /// In en, this message translates to:
  /// **'Rest complete'**
  String get restTimerFinished;

  /// No description provided for @restTimerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get restTimerPause;

  /// No description provided for @restTimerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get restTimerResume;

  /// No description provided for @restTimerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get restTimerDismiss;

  /// No description provided for @restTimerPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose rest duration'**
  String get restTimerPresetTitle;

  /// No description provided for @restTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String restTimerMinutes(String value);

  /// No description provided for @restTimerMinus15.
  ///
  /// In en, this message translates to:
  /// **'−15 sec'**
  String get restTimerMinus15;

  /// No description provided for @restTimerPlus15.
  ///
  /// In en, this message translates to:
  /// **'+15 sec'**
  String get restTimerPlus15;

  /// No description provided for @copiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedClipboard;

  /// No description provided for @calcHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get calcHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @calcError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get calcError;

  /// No description provided for @bmrSection.
  ///
  /// In en, this message translates to:
  /// **'1. BMR'**
  String get bmrSection;

  /// No description provided for @tdeeSection.
  ///
  /// In en, this message translates to:
  /// **'2. TDEE'**
  String get tdeeSection;

  /// No description provided for @targetIntakeSection.
  ///
  /// In en, this message translates to:
  /// **'3. Target intake'**
  String get targetIntakeSection;

  /// No description provided for @macrosSection.
  ///
  /// In en, this message translates to:
  /// **'4. Macros'**
  String get macrosSection;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @actualDeficitFormula.
  ///
  /// In en, this message translates to:
  /// **'Actual deficit = plan {planned} + remaining calories'**
  String actualDeficitFormula(String planned);

  /// No description provided for @legendColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get legendColors;

  /// No description provided for @legendPastOk.
  ///
  /// In en, this message translates to:
  /// **'Past · met'**
  String get legendPastOk;

  /// No description provided for @legendPastBad.
  ///
  /// In en, this message translates to:
  /// **'Past · missed'**
  String get legendPastBad;

  /// No description provided for @legendTodayOngoing.
  ///
  /// In en, this message translates to:
  /// **'Today · in progress'**
  String get legendTodayOngoing;

  /// No description provided for @legendStandardChange.
  ///
  /// In en, this message translates to:
  /// **'Standard change'**
  String get legendStandardChange;

  /// No description provided for @legendNewStandardLine.
  ///
  /// In en, this message translates to:
  /// **'Vertical line = new standard effective'**
  String get legendNewStandardLine;

  /// No description provided for @legendBeforeNeutral.
  ///
  /// In en, this message translates to:
  /// **'Before: neutral numbers'**
  String get legendBeforeNeutral;

  /// No description provided for @legendAfterGreenRed.
  ///
  /// In en, this message translates to:
  /// **'After: past green/red'**
  String get legendAfterGreenRed;

  /// No description provided for @waterTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap cup +250 · tap lid −250'**
  String get waterTapHint;

  /// No description provided for @noWorkoutPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'No workout plan yet'**
  String get noWorkoutPlanTitle;

  /// No description provided for @noWorkoutPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise now, or create a plan under Records → Train.'**
  String get noWorkoutPlanBody;

  /// No description provided for @replaceTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Replace today\'s workout'**
  String get replaceTodayWorkout;

  /// No description provided for @replaceTodayWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Today already has a workout; replace with this plan?'**
  String get replaceTodayWorkoutBody;

  /// No description provided for @noWorkoutTodo.
  ///
  /// In en, this message translates to:
  /// **'No workout for today'**
  String get noWorkoutTodo;

  /// No description provided for @noWorkoutThatDay.
  ///
  /// In en, this message translates to:
  /// **'No workout logged that day'**
  String get noWorkoutThatDay;

  /// No description provided for @addTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add today\'s workout'**
  String get addTodayWorkout;

  /// No description provided for @quickAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Quick-add exercise'**
  String get quickAddExercise;

  /// No description provided for @sectionThatDay.
  ///
  /// In en, this message translates to:
  /// **'That day'**
  String get sectionThatDay;

  /// No description provided for @foodsSeedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load food library'**
  String get foodsSeedLoadFailed;

  /// No description provided for @enterAnyway.
  ///
  /// In en, this message translates to:
  /// **'Enter anyway'**
  String get enterAnyway;

  /// No description provided for @toolboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat · metrics · food convert · rest timer'**
  String get toolboxSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @themeSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get themeSunrise;

  /// No description provided for @clearDataBody.
  ///
  /// In en, this message translates to:
  /// **'Clears all meals, weight, workouts, notes, favorites, and profile. Continue?'**
  String get clearDataBody;

  /// No description provided for @noInstallPackage.
  ///
  /// In en, this message translates to:
  /// **'No install package for the new version'**
  String get noInstallPackage;

  /// No description provided for @cutPlanIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Go to Me → My profile to set target weight and weekly loss.'**
  String get cutPlanIncompleteHint;

  /// No description provided for @copyYesterdayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Day already has logs; append yesterday\'s meals?'**
  String get copyYesterdayConfirm;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get activityModerate;

  /// No description provided for @activityHigh.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get activityHigh;

  /// No description provided for @activityAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get activityAthlete;

  /// No description provided for @goalCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get goalCut;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintain;

  /// No description provided for @goalBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get goalBulk;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @bmiUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiObese;

  /// No description provided for @ffmiAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get ffmiAverage;

  /// No description provided for @ffmiTrained.
  ///
  /// In en, this message translates to:
  /// **'Trained'**
  String get ffmiTrained;

  /// No description provided for @ffmiAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get ffmiAdvanced;

  /// No description provided for @ffmiElite.
  ///
  /// In en, this message translates to:
  /// **'Near elite (not a hard cut-off)'**
  String get ffmiElite;

  /// No description provided for @bmrFormulaMale.
  ///
  /// In en, this message translates to:
  /// **'Male: 10×weight + 6.25×height − 5×age + 5'**
  String get bmrFormulaMale;

  /// No description provided for @bmrFormulaFemale.
  ///
  /// In en, this message translates to:
  /// **'Female: 10×weight + 6.25×height − 5×age − 161'**
  String get bmrFormulaFemale;

  /// No description provided for @noteMissingTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'No valid target weight; estimating at 80% of maintenance. Complete it under Me, then recalculate.'**
  String get noteMissingTargetWeight;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String loadFailed(String error);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @addFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String addFailed(String error);

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(String error);

  /// No description provided for @clearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed: {error}'**
  String clearFailed(String error);

  /// No description provided for @checkUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed: {error}'**
  String checkUpdateFailed(String error);

  /// No description provided for @cannotOpenApk.
  ///
  /// In en, this message translates to:
  /// **'Cannot open package: {message}'**
  String cannotOpenApk(String message);

  /// No description provided for @workoutLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Workout load failed: {error}'**
  String workoutLoadFailed(String error);

  /// No description provided for @loadFoodsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load foods: {error}'**
  String loadFoodsFailed(String error);

  /// No description provided for @applyPresetFailed.
  ///
  /// In en, this message translates to:
  /// **'Apply failed: {error}'**
  String applyPresetFailed(String error);

  /// No description provided for @aboutNWeeks.
  ///
  /// In en, this message translates to:
  /// **'· ~{weeks} wk'**
  String aboutNWeeks(int weeks);

  /// No description provided for @macroOverG.
  ///
  /// In en, this message translates to:
  /// **'Over {g} g'**
  String macroOverG(String g);

  /// No description provided for @macroRemainG.
  ///
  /// In en, this message translates to:
  /// **'{g} g left'**
  String macroRemainG(String g);

  /// No description provided for @kcalOver.
  ///
  /// In en, this message translates to:
  /// **'Over {n}'**
  String kcalOver(String n);

  /// No description provided for @kcalRemain.
  ///
  /// In en, this message translates to:
  /// **'{n} left'**
  String kcalRemain(String n);

  /// No description provided for @plateauHint.
  ///
  /// In en, this message translates to:
  /// **'Weight barely changed in {days} days. Trim calories slightly, or add activity first.'**
  String plateauHint(int days);

  /// No description provided for @cut100Applied.
  ///
  /// In en, this message translates to:
  /// **'Cut 100 kcal; daily intake {kcal}'**
  String cut100Applied(String kcal);

  /// No description provided for @sectionCalories.
  ///
  /// In en, this message translates to:
  /// **'{prefix} calories'**
  String sectionCalories(String prefix);

  /// No description provided for @sectionLogs.
  ///
  /// In en, this message translates to:
  /// **'{prefix} logs'**
  String sectionLogs(String prefix);

  /// No description provided for @sectionWorkout.
  ///
  /// In en, this message translates to:
  /// **'{prefix} workout'**
  String sectionWorkout(String prefix);

  /// No description provided for @deficitIntakeLine.
  ///
  /// In en, this message translates to:
  /// **'Deficit {deficit} kcal · intake {intake} kcal'**
  String deficitIntakeLine(String deficit, String intake);

  /// No description provided for @alcoholExtraKcal.
  ///
  /// In en, this message translates to:
  /// **'Alcohol ≈ {kcal} kcal extra'**
  String alcoholExtraKcal(String kcal);

  /// No description provided for @skippedItems.
  ///
  /// In en, this message translates to:
  /// **', skipped {n}'**
  String skippedItems(int n);

  /// No description provided for @copiedItems.
  ///
  /// In en, this message translates to:
  /// **'Copied {n}{skip}'**
  String copiedItems(int n, String skip);

  /// No description provided for @skippedMissingFoods.
  ///
  /// In en, this message translates to:
  /// **', skipped {n} missing foods'**
  String skippedMissingFoods(int n);

  /// No description provided for @appliedPresetItems.
  ///
  /// In en, this message translates to:
  /// **'Applied {n}{skip}'**
  String appliedPresetItems(int n, String skip);

  /// No description provided for @loggedInto.
  ///
  /// In en, this message translates to:
  /// **'Logged to {day}'**
  String loggedInto(String day);

  /// No description provided for @logMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Log meal · {day}'**
  String logMealTitle(String day);

  /// No description provided for @confirmDeleteWeight.
  ///
  /// In en, this message translates to:
  /// **'Delete weight log for {date}?'**
  String confirmDeleteWeight(String date);

  /// No description provided for @bodyFatPctLine.
  ///
  /// In en, this message translates to:
  /// **'Body fat {pct}%'**
  String bodyFatPctLine(String pct);

  /// No description provided for @weightLoggedSnack.
  ///
  /// In en, this message translates to:
  /// **'Weight saved; daily intake {kcal} kcal'**
  String weightLoggedSnack(String kcal);

  /// No description provided for @confirmDeletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String confirmDeletePlan(String name);

  /// No description provided for @nSets.
  ///
  /// In en, this message translates to:
  /// **'{n} sets'**
  String nSets(int n);

  /// No description provided for @setLine.
  ///
  /// In en, this message translates to:
  /// **'{name} · set {index}'**
  String setLine(String name, int index);

  /// No description provided for @nReps.
  ///
  /// In en, this message translates to:
  /// **'{n} reps'**
  String nReps(int n);

  /// No description provided for @nSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} sec'**
  String nSeconds(int n);

  /// No description provided for @nKinds.
  ///
  /// In en, this message translates to:
  /// **'{n} items'**
  String nKinds(int n);

  /// No description provided for @editSetsHint.
  ///
  /// In en, this message translates to:
  /// **'Target {sets} sets · edit sets and {valueLabel}'**
  String editSetsHint(int sets, String valueLabel);

  /// No description provided for @confirmDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note for {title}?'**
  String confirmDeleteNote(String title);

  /// No description provided for @deleteWorkoutItem.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteWorkoutItem;

  /// No description provided for @confirmDeleteWorkoutItem.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from today\'s workout?'**
  String confirmDeleteWorkoutItem(String name);

  /// No description provided for @savedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved · {time}'**
  String savedAt(String time);

  /// No description provided for @charsUpdated.
  ///
  /// In en, this message translates to:
  /// **'{chars} chars · updated {time}'**
  String charsUpdated(int chars, String time);

  /// No description provided for @waterDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for default {ml} ml'**
  String waterDefaultHint(int ml);

  /// No description provided for @quotaReadyBody.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal\nP {p} · C {c} · F {f}\n\nDetails under Me → My profile.'**
  String quotaReadyBody(String kcal, String p, String c, String f);

  /// No description provided for @alreadyLatest.
  ///
  /// In en, this message translates to:
  /// **'Already up to date ({version})'**
  String alreadyLatest(String version);

  /// No description provided for @newVersionAsk.
  ///
  /// In en, this message translates to:
  /// **'New version {version}. Download and install?'**
  String newVersionAsk(String version);

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'New version {version}'**
  String newVersionTitle(String version);

  /// No description provided for @deficitLine.
  ///
  /// In en, this message translates to:
  /// **'Deficit {kcal} kcal'**
  String deficitLine(String kcal);

  /// No description provided for @weeklyLossLine.
  ///
  /// In en, this message translates to:
  /// **'· {kg} kg/week'**
  String weeklyLossLine(String kg);

  /// No description provided for @plateauAdjLine.
  ///
  /// In en, this message translates to:
  /// **'Plateau −{kcal} kcal'**
  String plateauAdjLine(String kcal);

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{sex} · {age} yr · {height} cm · {weight} kg · {goal}'**
  String profileSubtitle(
    String sex,
    int age,
    String height,
    String weight,
    String goal,
  );

  /// No description provided for @bfWrittenSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved {pct}% body fat to today\'s weight log'**
  String bfWrittenSnack(String pct);

  /// No description provided for @whtrAboveRef.
  ///
  /// In en, this message translates to:
  /// **'Above reference {ref}'**
  String whtrAboveRef(String ref);

  /// No description provided for @whtrRef.
  ///
  /// In en, this message translates to:
  /// **'Reference {ref}'**
  String whtrRef(String ref);

  /// No description provided for @alcoholWithKcal.
  ///
  /// In en, this message translates to:
  /// **'Alcohol {g} g (~{kcal} kcal)'**
  String alcoholWithKcal(String g, String kcal);

  /// No description provided for @macroRule.
  ///
  /// In en, this message translates to:
  /// **'Protein {p} g/kg · fat 0.8 g/kg · rest carbs'**
  String macroRule(String p);

  /// No description provided for @includesPlateauAdj.
  ///
  /// In en, this message translates to:
  /// **'Includes plateau −{kcal} kcal'**
  String includesPlateauAdj(String kcal);

  /// No description provided for @maintainLine.
  ///
  /// In en, this message translates to:
  /// **'Maintain: ≈ TDEE = {kcal} kcal'**
  String maintainLine(String kcal);

  /// No description provided for @bulkLine.
  ///
  /// In en, this message translates to:
  /// **'Bulk: TDEE × 1.1 = {kcal} kcal'**
  String bulkLine(String kcal);

  /// No description provided for @needLose.
  ///
  /// In en, this message translates to:
  /// **'(lose {kg})'**
  String needLose(String kg);

  /// No description provided for @dailyDeficitLine.
  ///
  /// In en, this message translates to:
  /// **'Daily deficit {kcal} kcal'**
  String dailyDeficitLine(String kcal);

  /// No description provided for @narrowed.
  ///
  /// In en, this message translates to:
  /// **'(narrowed)'**
  String get narrowed;

  /// No description provided for @shouldEat.
  ///
  /// In en, this message translates to:
  /// **'Eat {kcal} kcal'**
  String shouldEat(String kcal);

  /// No description provided for @tempEstimate80.
  ///
  /// In en, this message translates to:
  /// **'Temp estimate: TDEE × 80% = {kcal} kcal'**
  String tempEstimate80(String kcal);

  /// No description provided for @workoutProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Progress {done}/{total} · tap to edit · swipe to delete'**
  String workoutProgressHint(int done, int total);

  /// No description provided for @setsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} sets · target {reps} {unit}'**
  String setsProgress(int done, int total, String reps, String unit);

  /// No description provided for @noteWeeklyLossTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Over 1 kg/week is not recommended (0.3–0.8 preferred). Adjusted to {rate} kg/week.'**
  String noteWeeklyLossTooHigh(String rate);

  /// No description provided for @noteWeeklyLossTooLow.
  ///
  /// In en, this message translates to:
  /// **'Weekly loss raised to at least {rate} kg/week.'**
  String noteWeeklyLossTooLow(String rate);

  /// No description provided for @noteDeficitCap.
  ///
  /// In en, this message translates to:
  /// **'Capped at {max} kcal/day deficit. About {weekly} kg/week; ~{weeks} weeks.'**
  String noteDeficitCap(String max, String weekly, int weeks);

  /// No description provided for @noteEstimateWeeks.
  ///
  /// In en, this message translates to:
  /// **'~{kcalPerKg} kcal ≈ 1 kg fat, {weekly} kg/week. About {weeks} weeks.'**
  String noteEstimateWeeks(String kcalPerKg, String weekly, int weeks);

  /// No description provided for @noteEstimateWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'About {weeks} weeks to finish.'**
  String noteEstimateWeeksShort(int weeks);

  /// No description provided for @notePlateauAdj.
  ///
  /// In en, this message translates to:
  /// **'Plateau adjustment applied: −{adj} kcal/day.'**
  String notePlateauAdj(String adj);

  /// No description provided for @estimatedWeeksAtRate.
  ///
  /// In en, this message translates to:
  /// **'~{weeks} weeks at {rate} kg/week'**
  String estimatedWeeksAtRate(int weeks, String rate);

  /// No description provided for @untitledWorkoutGroup.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get untitledWorkoutGroup;

  /// No description provided for @removeDayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Remove this plan'**
  String get removeDayWorkout;

  /// No description provided for @confirmRemoveDayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" and all its exercises from today\'s workout?'**
  String confirmRemoveDayWorkout(String name);

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance colors'**
  String get themeSubtitle;

  /// No description provided for @themeGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get themeGraphite;

  /// No description provided for @themeFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh Green'**
  String get themeFresh;

  /// No description provided for @themeAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get themeAurora;

  /// No description provided for @themeWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm Sun'**
  String get themeWarm;

  /// No description provided for @themeFreshDesc.
  ///
  /// In en, this message translates to:
  /// **'Light background, white cards, deep green accent'**
  String get themeFreshDesc;

  /// No description provided for @themeAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep sea blue with teal highlights'**
  String get themeAuroraDesc;

  /// No description provided for @themeWarmDesc.
  ///
  /// In en, this message translates to:
  /// **'Cream background with warm orange'**
  String get themeWarmDesc;

  /// No description provided for @themeGraphiteDesc.
  ///
  /// In en, this message translates to:
  /// **'Matte dark grey with silver accents'**
  String get themeGraphiteDesc;

  /// No description provided for @themeNote.
  ///
  /// In en, this message translates to:
  /// **'All four themes share one layout and nutrient colors stay the same. Your choice is kept after restart.'**
  String get themeNote;

  /// No description provided for @expandSection.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandSection;

  /// No description provided for @collapseSection.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseSection;

  /// No description provided for @noWorkoutShort.
  ///
  /// In en, this message translates to:
  /// **'None planned'**
  String get noWorkoutShort;

  /// No description provided for @remainingWord.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingWord;

  /// No description provided for @overWord.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get overWord;

  /// No description provided for @eatenWord.
  ///
  /// In en, this message translates to:
  /// **'eaten'**
  String get eatenWord;

  /// No description provided for @eatenOfTarget.
  ///
  /// In en, this message translates to:
  /// **'Eaten {eaten} / target {target}'**
  String eatenOfTarget(String eaten, String target);

  /// No description provided for @waterAddMl.
  ///
  /// In en, this message translates to:
  /// **'Add {ml} ml water'**
  String waterAddMl(int ml);

  /// No description provided for @waterUndoMl.
  ///
  /// In en, this message translates to:
  /// **'Undo {ml} ml water'**
  String waterUndoMl(int ml);

  /// No description provided for @mealsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {kcal} kcal'**
  String mealsSummary(int count, String kcal);

  /// No description provided for @legacyTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Legacy estimate: this day predates per-day target records, so the target shown is derived from the current profile.'**
  String get legacyTargetHint;

  /// No description provided for @dietCompleteToggle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s food log is complete'**
  String get dietCompleteToggle;

  /// No description provided for @dietCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Only confirmed days count toward the taper review'**
  String get dietCompleteHint;

  /// No description provided for @weeklyAvgLine.
  ///
  /// In en, this message translates to:
  /// **'Weekly avg {kcal} kcal'**
  String weeklyAvgLine(String kcal);

  /// No description provided for @nutritionTargets.
  ///
  /// In en, this message translates to:
  /// **'Nutrition targets'**
  String get nutritionTargets;

  /// No description provided for @todaysTarget.
  ///
  /// In en, this message translates to:
  /// **'Today\'s target'**
  String get todaysTarget;

  /// No description provided for @dietStrategy.
  ///
  /// In en, this message translates to:
  /// **'Fat-loss strategy'**
  String get dietStrategy;

  /// No description provided for @noStrategyShort.
  ///
  /// In en, this message translates to:
  /// **'No strategy'**
  String get noStrategyShort;

  /// No description provided for @noStrategyYet.
  ///
  /// In en, this message translates to:
  /// **'No strategy selected. Your profile target is used as-is until you choose one.'**
  String get noStrategyYet;

  /// No description provided for @strategyOnlyForCut.
  ///
  /// In en, this message translates to:
  /// **'Strategies apply to the cut goal only. Maintain / bulk keep the profile target.'**
  String get strategyOnlyForCut;

  /// No description provided for @chooseStrategy.
  ///
  /// In en, this message translates to:
  /// **'Choose strategy'**
  String get chooseStrategy;

  /// No description provided for @changeStrategy.
  ///
  /// In en, this message translates to:
  /// **'Change strategy'**
  String get changeStrategy;

  /// No description provided for @adjustSchedule.
  ///
  /// In en, this message translates to:
  /// **'Adjust schedule'**
  String get adjustSchedule;

  /// No description provided for @stopStrategy.
  ///
  /// In en, this message translates to:
  /// **'Stop strategy'**
  String get stopStrategy;

  /// No description provided for @stopStrategyBody.
  ///
  /// In en, this message translates to:
  /// **'From today the profile target applies again. Past days keep the targets that were in effect.'**
  String get stopStrategyBody;

  /// No description provided for @strategyStopped.
  ///
  /// In en, this message translates to:
  /// **'Strategy stopped'**
  String get strategyStopped;

  /// No description provided for @strategyApplied.
  ///
  /// In en, this message translates to:
  /// **'Strategy saved'**
  String get strategyApplied;

  /// No description provided for @planStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String planStartsOn(String date);

  /// No description provided for @planActiveSince.
  ///
  /// In en, this message translates to:
  /// **'In effect since {date} · v{version}'**
  String planActiveSince(String date, int version);

  /// No description provided for @planBaselineLine.
  ///
  /// In en, this message translates to:
  /// **'Ref. weight {kg} kg · TDEE {tdee} · avg target {e0} kcal'**
  String planBaselineLine(String kg, String tdee, String e0);

  /// No description provided for @baseTargetLine.
  ///
  /// In en, this message translates to:
  /// **'Profile target {kcal} kcal'**
  String baseTargetLine(String kcal);

  /// No description provided for @strategyBasisBody.
  ///
  /// In en, this message translates to:
  /// **'TDEE is estimated with Mifflin–St Jeor × activity factor. Protein and fat are fixed per kg of reference weight; carbohydrate takes the remaining energy. Carb cycling redistributes the weekly budget across high / mid / low days with one common shrink factor so every day stays inside bounds and the weekly total is preserved. The taper lowers carbohydrate by 25 g (100 kcal) per stage only after a review you confirm.'**
  String get strategyBasisBody;

  /// No description provided for @strategyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Product defaults for generally healthy adults; not a clinical prescription and not medically validated. Consult a professional for medical conditions.'**
  String get strategyDisclaimer;

  /// No description provided for @strategyScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Switching to maintain / bulk stops the strategy automatically. No extreme low-calorie, fasting or ketogenic presets are offered.'**
  String get strategyScopeNote;

  /// No description provided for @strategyPickerIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose one primary strategy. Protein and fat stay stable in all three; they differ in how carbohydrate and energy are arranged over time.'**
  String get strategyPickerIntro;

  /// No description provided for @defaultWord.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultWord;

  /// No description provided for @currentWord.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentWord;

  /// No description provided for @strategyBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced deficit'**
  String get strategyBalanced;

  /// No description provided for @strategyCarbCycle.
  ///
  /// In en, this message translates to:
  /// **'Carb cycling'**
  String get strategyCarbCycle;

  /// No description provided for @strategyCarbTaper.
  ///
  /// In en, this message translates to:
  /// **'Carb taper'**
  String get strategyCarbTaper;

  /// No description provided for @strategyBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Same energy and macros every day. Simple and easy to follow.'**
  String get strategyBalancedDesc;

  /// No description provided for @strategyCarbCycleDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget is redistributed into high / mid / low-carb days while protein and fat stay fixed.'**
  String get strategyCarbCycleDesc;

  /// No description provided for @strategyCarbTaperDesc.
  ///
  /// In en, this message translates to:
  /// **'Start at the baseline and lower carbohydrate one small step at a time, only after each review you confirm.'**
  String get strategyCarbTaperDesc;

  /// No description provided for @carbDayHigh.
  ///
  /// In en, this message translates to:
  /// **'High-carb day'**
  String get carbDayHigh;

  /// No description provided for @carbDayMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-carb day'**
  String get carbDayMid;

  /// No description provided for @carbDayLow.
  ///
  /// In en, this message translates to:
  /// **'Low-carb day'**
  String get carbDayLow;

  /// No description provided for @carbDayHighShort.
  ///
  /// In en, this message translates to:
  /// **'H'**
  String get carbDayHighShort;

  /// No description provided for @carbDayMidShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get carbDayMidShort;

  /// No description provided for @carbDayLowShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get carbDayLowShort;

  /// No description provided for @taperStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage {n}'**
  String taperStageLabel(int n);

  /// No description provided for @targetSourceOverride.
  ///
  /// In en, this message translates to:
  /// **'Custom target'**
  String get targetSourceOverride;

  /// No description provided for @targetSourceProfileCut.
  ///
  /// In en, this message translates to:
  /// **'Cut · profile target'**
  String get targetSourceProfileCut;

  /// No description provided for @targetLegacyEstimate.
  ///
  /// In en, this message translates to:
  /// **'Legacy estimate'**
  String get targetLegacyEstimate;

  /// No description provided for @issueInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Reference weight must be a positive number.'**
  String get issueInvalidWeight;

  /// No description provided for @issueInvalidTdee.
  ///
  /// In en, this message translates to:
  /// **'TDEE is unavailable; complete your profile first.'**
  String get issueInvalidTdee;

  /// No description provided for @issueInvalidTargetEnergy.
  ///
  /// In en, this message translates to:
  /// **'Target energy must be a positive number.'**
  String get issueInvalidTargetEnergy;

  /// No description provided for @issueDeficitBelowRange.
  ///
  /// In en, this message translates to:
  /// **'Deficit is below the 10% minimum for a fat-loss strategy.'**
  String get issueDeficitBelowRange;

  /// No description provided for @issueDeficitAboveRange.
  ///
  /// In en, this message translates to:
  /// **'Deficit exceeds the 20% self-service maximum.'**
  String get issueDeficitAboveRange;

  /// No description provided for @issueEnergyBelowFloor.
  ///
  /// In en, this message translates to:
  /// **'Energy would fall below the product floor (max(0.75×TDEE, 1201 kcal, P/F + 130 g carb)).'**
  String get issueEnergyBelowFloor;

  /// No description provided for @issueEnergyAboveTdee.
  ///
  /// In en, this message translates to:
  /// **'Energy would exceed the estimated TDEE.'**
  String get issueEnergyAboveTdee;

  /// No description provided for @issueCarbBelowMinimum.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate would fall below {g} g/day; lower protein/fat per kg or reduce the deficit.'**
  String issueCarbBelowMinimum(int g);

  /// No description provided for @issueInvalidSchedule.
  ///
  /// In en, this message translates to:
  /// **'The weekly schedule is invalid.'**
  String get issueInvalidSchedule;

  /// No description provided for @issueAmplitudeNegligible.
  ///
  /// In en, this message translates to:
  /// **'After bounds the high/low difference is negligible; the balanced strategy would be equivalent.'**
  String get issueAmplitudeNegligible;

  /// No description provided for @issueUnderage.
  ///
  /// In en, this message translates to:
  /// **'Strategies are for adults ({age}+). Please seek professional guidance instead.'**
  String issueUnderage(int age);

  /// No description provided for @issueGoalNotCut.
  ///
  /// In en, this message translates to:
  /// **'Only available with the cut goal.'**
  String get issueGoalNotCut;

  /// No description provided for @strategyParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get strategyParameters;

  /// No description provided for @referenceWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Reference weight'**
  String get referenceWeightKg;

  /// No description provided for @estimatedTdee.
  ///
  /// In en, this message translates to:
  /// **'Estimated TDEE'**
  String get estimatedTdee;

  /// No description provided for @deficitFractionLabel.
  ///
  /// In en, this message translates to:
  /// **'Average deficit {pct}%'**
  String deficitFractionLabel(int pct);

  /// No description provided for @averageTargetEnergy.
  ///
  /// In en, this message translates to:
  /// **'Average target energy'**
  String get averageTargetEnergy;

  /// No description provided for @energyBoundsHint.
  ///
  /// In en, this message translates to:
  /// **'Allowed {min}–{max} kcal'**
  String energyBoundsHint(int min, int max);

  /// No description provided for @proteinPerKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein per kg'**
  String get proteinPerKgLabel;

  /// No description provided for @fatPerKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat per kg'**
  String get fatPerKgLabel;

  /// No description provided for @dailyBaselineTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily baseline'**
  String get dailyBaselineTitle;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'7-day schedule'**
  String get weeklySchedule;

  /// No description provided for @suggestFromTraining.
  ///
  /// In en, this message translates to:
  /// **'Match training'**
  String get suggestFromTraining;

  /// No description provided for @trainingSuggestionBody.
  ///
  /// In en, this message translates to:
  /// **'Based on the last 4 weeks: {high} high-carb day(s), {low} low-carb day(s). Apply only if it matches your plan.'**
  String trainingSuggestionBody(int high, int low);

  /// No description provided for @applySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applySuggestion;

  /// No description provided for @carbCycleEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to select it; tap the selected day again to cycle high → mid → low.'**
  String get carbCycleEditHint;

  /// No description provided for @weeklyBudgetLine.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget {total} kcal · daily average {avg} kcal'**
  String weeklyBudgetLine(String total, String avg);

  /// No description provided for @carbAmplitudeLine.
  ///
  /// In en, this message translates to:
  /// **'Carb amplitude ±{g} g per score step'**
  String carbAmplitudeLine(String g);

  /// No description provided for @carbAmplitudeShrunk.
  ///
  /// In en, this message translates to:
  /// **'Requested ±{g} g was shrunk uniformly so every day stays within bounds.'**
  String carbAmplitudeShrunk(String g);

  /// No description provided for @taperLadderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage ladder (preview)'**
  String get taperLadderTitle;

  /// No description provided for @taperLadderHint.
  ///
  /// In en, this message translates to:
  /// **'Each step is −25 g carbohydrate / −100 kcal and requires a review you confirm. Stages never advance automatically.'**
  String get taperLadderHint;

  /// No description provided for @taperFloorLine.
  ///
  /// In en, this message translates to:
  /// **'Floor: {kcal} kcal and {carb} g carbohydrate'**
  String taperFloorLine(int kcal, int carb);

  /// No description provided for @currentStage.
  ///
  /// In en, this message translates to:
  /// **'Current stage'**
  String get currentStage;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective date'**
  String get effectiveDate;

  /// No description provided for @startNextCycle.
  ///
  /// In en, this message translates to:
  /// **'Next cycle ({date})'**
  String startNextCycle(String date);

  /// No description provided for @startTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow ({date})'**
  String startTomorrow(String date);

  /// No description provided for @startToday.
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get startToday;

  /// No description provided for @midCycleNotice.
  ///
  /// In en, this message translates to:
  /// **'Mid-cycle start: {from}–{to} follow the plan; remaining budget for this week {kcal} kcal. Earlier days of the week are not recalculated.'**
  String midCycleNotice(String from, String to, String kcal);

  /// No description provided for @applyStrategyFrom.
  ///
  /// In en, this message translates to:
  /// **'Apply from {date}'**
  String applyStrategyFrom(String date);

  /// No description provided for @taperReview.
  ///
  /// In en, this message translates to:
  /// **'Taper review'**
  String get taperReview;

  /// No description provided for @taperNotActive.
  ///
  /// In en, this message translates to:
  /// **'The carb taper is not active.'**
  String get taperNotActive;

  /// No description provided for @observation.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get observation;

  /// No description provided for @observationProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} days observed'**
  String observationProgress(int done, int total);

  /// No description provided for @nextReviewDate.
  ///
  /// In en, this message translates to:
  /// **'Review available from {date}'**
  String nextReviewDate(String date);

  /// No description provided for @weighInDays.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in days (14 d)'**
  String get weighInDays;

  /// No description provided for @weighInDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Need ≥{n} days, ≥{half} in each 7-day half'**
  String weighInDaysHint(int n, int half);

  /// No description provided for @completeDietDays.
  ///
  /// In en, this message translates to:
  /// **'Complete food-log days (14 d)'**
  String get completeDietDays;

  /// No description provided for @completeDietDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Need ≥{n} days confirmed on the Today page'**
  String completeDietDaysHint(int n);

  /// No description provided for @weeklyRate.
  ///
  /// In en, this message translates to:
  /// **'Weekly change (7-day means)'**
  String get weeklyRate;

  /// No description provided for @weeklyRateHint.
  ///
  /// In en, this message translates to:
  /// **'Target band {low}%–{high}% of body weight per week'**
  String weeklyRateHint(String low, String high);

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @taperStatusObserving.
  ///
  /// In en, this message translates to:
  /// **'Observing'**
  String get taperStatusObserving;

  /// No description provided for @taperStatusInsufficientWeight.
  ///
  /// In en, this message translates to:
  /// **'Not enough weigh-ins'**
  String get taperStatusInsufficientWeight;

  /// No description provided for @taperStatusInsufficientDiet.
  ///
  /// In en, this message translates to:
  /// **'Not enough complete food-log days'**
  String get taperStatusInsufficientDiet;

  /// No description provided for @taperStatusHold.
  ///
  /// In en, this message translates to:
  /// **'Keep the current stage'**
  String get taperStatusHold;

  /// No description provided for @taperStatusStepDown.
  ///
  /// In en, this message translates to:
  /// **'Step-down candidate'**
  String get taperStatusStepDown;

  /// No description provided for @taperStatusFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor reached'**
  String get taperStatusFloor;

  /// No description provided for @taperStatusTooFast.
  ///
  /// In en, this message translates to:
  /// **'Losing faster than the band'**
  String get taperStatusTooFast;

  /// No description provided for @taperObservingBody.
  ///
  /// In en, this message translates to:
  /// **'{days} more day(s) of observation before a review is possible. Keep logging weight and confirming complete days.'**
  String taperObservingBody(int days);

  /// No description provided for @taperInsufficientWeightBody.
  ///
  /// In en, this message translates to:
  /// **'Weigh in on more days (both halves of the window) so the 7-day means are credible. No change is suggested.'**
  String get taperInsufficientWeightBody;

  /// No description provided for @taperInsufficientDietBody.
  ///
  /// In en, this message translates to:
  /// **'Too few days are confirmed as complete, so intake cannot be trusted. Confirm complete days on the Today page. No change is suggested.'**
  String get taperInsufficientDietBody;

  /// No description provided for @taperHoldBody.
  ///
  /// In en, this message translates to:
  /// **'Weight is changing within the target band. Keep the current stage and review again after the next window.'**
  String get taperHoldBody;

  /// No description provided for @taperStepDownBody.
  ///
  /// In en, this message translates to:
  /// **'Weight change is below the band with credible data. Candidate: {kcal} kcal · C {carb} g. Nothing changes until you confirm.'**
  String taperStepDownBody(int kcal, String carb);

  /// No description provided for @taperFloorBody.
  ///
  /// In en, this message translates to:
  /// **'The next stage would breach the energy or carbohydrate floor, so no further reduction is offered. Consider activity, adherence or a maintenance break.'**
  String get taperFloorBody;

  /// No description provided for @taperTooFastBody.
  ///
  /// In en, this message translates to:
  /// **'Weight is dropping faster than the band. Do not lower further; consider returning to the previous stage.'**
  String get taperTooFastBody;

  /// No description provided for @confirmNextStage.
  ///
  /// In en, this message translates to:
  /// **'Enter next stage?'**
  String get confirmNextStage;

  /// No description provided for @confirmNextStageBody.
  ///
  /// In en, this message translates to:
  /// **'From tomorrow the target becomes {kcal} kcal with {carb} g carbohydrate. A new observation window starts.'**
  String confirmNextStageBody(int kcal, String carb);

  /// No description provided for @enterStage.
  ///
  /// In en, this message translates to:
  /// **'Enter stage {n}'**
  String enterStage(int n);

  /// No description provided for @keepStage.
  ///
  /// In en, this message translates to:
  /// **'Keep current stage'**
  String get keepStage;

  /// No description provided for @keepStageBody.
  ///
  /// In en, this message translates to:
  /// **'The target stays the same and a new observation window starts tomorrow.'**
  String get keepStageBody;

  /// No description provided for @backOneStage.
  ///
  /// In en, this message translates to:
  /// **'Back one stage'**
  String get backOneStage;

  /// No description provided for @backOneStageBody.
  ///
  /// In en, this message translates to:
  /// **'From tomorrow the previous stage\'s higher target applies and a new observation window starts.'**
  String get backOneStageBody;

  /// No description provided for @taperStageConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Stage {n} confirmed from tomorrow'**
  String taperStageConfirmed(int n);

  /// No description provided for @taperRulesBody.
  ///
  /// In en, this message translates to:
  /// **'Rules: at least 14 days of observation (21 after carb cycling); ≥10 weigh-in days with ≥4 in each half; ≥10 confirmed complete food-log days; compare the two 7-day means; each step is −25 g carbohydrate / −100 kcal; never below the energy and 130 g carbohydrate floors.'**
  String get taperRulesBody;

  /// No description provided for @cancelScheduledStrategy.
  ///
  /// In en, this message translates to:
  /// **'Cancel scheduled change'**
  String get cancelScheduledStrategy;

  /// No description provided for @cancelScheduledStrategyBody.
  ///
  /// In en, this message translates to:
  /// **'The strategy that has not started yet is discarded. The strategy currently in effect keeps running.'**
  String get cancelScheduledStrategyBody;

  /// No description provided for @scheduledStrategyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled change cancelled'**
  String get scheduledStrategyCancelled;

  /// No description provided for @tabPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlans;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @otherPlans.
  ///
  /// In en, this message translates to:
  /// **'Other plans'**
  String get otherPlans;

  /// No description provided for @exerciseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exerciseSchedule;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @continueRecording.
  ///
  /// In en, this message translates to:
  /// **'Continue recording'**
  String get continueRecording;

  /// No description provided for @viewDayRecords.
  ///
  /// In en, this message translates to:
  /// **'View daily records'**
  String get viewDayRecords;

  /// No description provided for @viewWorkoutDetails.
  ///
  /// In en, this message translates to:
  /// **'View workout'**
  String get viewWorkoutDetails;

  /// No description provided for @dailyJournal.
  ///
  /// In en, this message translates to:
  /// **'Daily journal'**
  String get dailyJournal;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reflect on training, food and how you feel'**
  String get journalSubtitle;

  /// No description provided for @journalPrompt.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get journalPrompt;

  /// No description provided for @loadRecordsFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load records'**
  String get loadRecordsFailed;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discardChangesTitle;

  /// No description provided for @sincePreviousRecord.
  ///
  /// In en, this message translates to:
  /// **'Since previous record'**
  String get sincePreviousRecord;

  /// No description provided for @stepsPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get stepsPermissionNeeded;

  /// No description provided for @stepsNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get stepsNotSynced;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Track food, training and progress'**
  String get appTagline;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @noWorkoutPlannedTitle.
  ///
  /// In en, this message translates to:
  /// **'No workout planned yet'**
  String get noWorkoutPlannedTitle;

  /// No description provided for @noWorkoutPlannedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first workout plan'**
  String get noWorkoutPlannedHint;

  /// No description provided for @noMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet'**
  String get noMealsTitle;

  /// No description provided for @noMealsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log today\'s first meal'**
  String get noMealsHint;

  /// No description provided for @recordStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Record status'**
  String get recordStatusLabel;

  /// No description provided for @recordComplete.
  ///
  /// In en, this message translates to:
  /// **'Fully logged'**
  String get recordComplete;

  /// No description provided for @recordIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get recordIncomplete;

  /// No description provided for @mealNotLogged.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get mealNotLogged;

  /// No description provided for @mealsRecordSection.
  ///
  /// In en, this message translates to:
  /// **'Food log'**
  String get mealsRecordSection;

  /// No description provided for @noRecentFoods.
  ///
  /// In en, this message translates to:
  /// **'No recent foods yet'**
  String get noRecentFoods;

  /// No description provided for @editKeywords.
  ///
  /// In en, this message translates to:
  /// **'Edit keywords'**
  String get editKeywords;

  /// No description provided for @createFood.
  ///
  /// In en, this message translates to:
  /// **'New food'**
  String get createFood;

  /// No description provided for @charCount.
  ///
  /// In en, this message translates to:
  /// **'{n} characters'**
  String charCount(int n);

  /// No description provided for @lastNDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String lastNDays(int n);

  /// No description provided for @nExercises.
  ///
  /// In en, this message translates to:
  /// **'{n} exercises'**
  String nExercises(int n);

  /// No description provided for @planSummary.
  ///
  /// In en, this message translates to:
  /// **'{exercises} exercises · {sets} sets'**
  String planSummary(int exercises, int sets);

  /// No description provided for @viewWorkoutHistory.
  ///
  /// In en, this message translates to:
  /// **'View workout history'**
  String get viewWorkoutHistory;

  /// No description provided for @setsWithReps.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {reps}'**
  String setsWithReps(int sets, String reps);

  /// No description provided for @recentSteps.
  ///
  /// In en, this message translates to:
  /// **'Recent steps'**
  String get recentSteps;

  /// No description provided for @saveThisSet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveThisSet;

  /// No description provided for @adjustStrategy.
  ///
  /// In en, this message translates to:
  /// **'Adjust strategy'**
  String get adjustStrategy;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get weeklySummary;

  /// No description provided for @carbDayType.
  ///
  /// In en, this message translates to:
  /// **'Carb-day type'**
  String get carbDayType;

  /// No description provided for @reviewPoints.
  ///
  /// In en, this message translates to:
  /// **'Review points'**
  String get reviewPoints;

  /// No description provided for @dataPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Data pending'**
  String get dataPendingTitle;

  /// No description provided for @dataPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Keep logging your weight'**
  String get dataPendingHint;

  /// No description provided for @keepCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Keep current plan'**
  String get keepCurrentPlan;

  /// No description provided for @addRecords.
  ///
  /// In en, this message translates to:
  /// **'Add records'**
  String get addRecords;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @profileSectionBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get profileSectionBasics;

  /// No description provided for @profileSectionGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get profileSectionGoal;

  /// No description provided for @profileSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileSectionOther;

  /// No description provided for @profileSectionBasicsHint.
  ///
  /// In en, this message translates to:
  /// **'Used to estimate your metabolism and metrics.'**
  String get profileSectionBasicsHint;

  /// No description provided for @profileSectionGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Turns those numbers into your daily calorie and macro targets.'**
  String get profileSectionGoalHint;

  /// No description provided for @profileFieldSexHint.
  ///
  /// In en, this message translates to:
  /// **'Sets which BMR and body-fat formula is used.'**
  String get profileFieldSexHint;

  /// No description provided for @profileFieldAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Lowers the resting metabolic estimate as it rises.'**
  String get profileFieldAgeHint;

  /// No description provided for @profileFieldHeightHint.
  ///
  /// In en, this message translates to:
  /// **'Feeds BMI, lean body mass and ideal-weight figures.'**
  String get profileFieldHeightHint;

  /// No description provided for @profileFieldWeightHint.
  ///
  /// In en, this message translates to:
  /// **'The baseline for every calorie and macro target.'**
  String get profileFieldWeightHint;

  /// No description provided for @profileFieldActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Scales BMR into your total daily energy (TDEE).'**
  String get profileFieldActivityHint;

  /// No description provided for @profileFieldGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Chooses the calorie surplus or deficit and the protein target.'**
  String get profileFieldGoalHint;

  /// No description provided for @profileFieldTargetWeightHint.
  ///
  /// In en, this message translates to:
  /// **'The end point of the cut; used to estimate how many weeks it takes.'**
  String get profileFieldTargetWeightHint;

  /// No description provided for @profileFieldWeeklyChangeHint.
  ///
  /// In en, this message translates to:
  /// **'0.2–0.5 kg per week is sustainable; faster tends to cost muscle.'**
  String get profileFieldWeeklyChangeHint;

  /// No description provided for @profileFieldWaterHint.
  ///
  /// In en, this message translates to:
  /// **'The goal the water cup on the Today screen fills toward.'**
  String get profileFieldWaterHint;

  /// No description provided for @basalMetabolicRate.
  ///
  /// In en, this message translates to:
  /// **'Basal metabolic rate (BMR)'**
  String get basalMetabolicRate;

  /// No description provided for @totalDailyEnergy.
  ///
  /// In en, this message translates to:
  /// **'Total daily energy (TDEE)'**
  String get totalDailyEnergy;

  /// No description provided for @bmrMethodMifflin.
  ///
  /// In en, this message translates to:
  /// **'Mifflin-St Jeor'**
  String get bmrMethodMifflin;

  /// No description provided for @bmrMethodKatch.
  ///
  /// In en, this message translates to:
  /// **'Katch-McArdle · uses body fat'**
  String get bmrMethodKatch;

  /// No description provided for @bmrKatchFormula.
  ///
  /// In en, this message translates to:
  /// **'370 + 21.6 × {lbm} kg lean mass = {bmr} kcal'**
  String bmrKatchFormula(String lbm, String bmr);

  /// No description provided for @bmrMifflinFormula.
  ///
  /// In en, this message translates to:
  /// **'10·{w} + 6.25·{h} − 5·{age} {sexTerm} = {bmr} kcal'**
  String bmrMifflinFormula(
    String w,
    String h,
    int age,
    String sexTerm,
    String bmr,
  );

  /// No description provided for @tdeeFormula.
  ///
  /// In en, this message translates to:
  /// **'{bmr} kcal × {factor} ({activity}) = {tdee} kcal'**
  String tdeeFormula(String bmr, String factor, String activity, String tdee);

  /// No description provided for @metricsFromProfile.
  ///
  /// In en, this message translates to:
  /// **'From your profile · {sex} · {age} yr · {activity}'**
  String metricsFromProfile(String sex, int age, String activity);

  /// No description provided for @metricsFromProfileShort.
  ///
  /// In en, this message translates to:
  /// **'From your profile · {sex} · {age} yr'**
  String metricsFromProfileShort(String sex, int age);

  /// No description provided for @toolboxTagline.
  ///
  /// In en, this message translates to:
  /// **'Handy tools for your healthy routine'**
  String get toolboxTagline;

  /// No description provided for @onboardingWelcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingWelcomeCta;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get onboardingFinish;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'{step}/{total}'**
  String onboardingStep(int step, int total);

  /// No description provided for @onboardingDataUseNote.
  ///
  /// In en, this message translates to:
  /// **'We only use this to personalise your food and training plan — nothing else.'**
  String get onboardingDataUseNote;

  /// No description provided for @onboardingBasicTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your info'**
  String get onboardingBasicTitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your fitness goal'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Log your food'**
  String get onboardingFeature1Title;

  /// No description provided for @onboardingFeature1Sub.
  ///
  /// In en, this message translates to:
  /// **'Track intake meal by meal'**
  String get onboardingFeature1Sub;

  /// No description provided for @onboardingFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Plan your training'**
  String get onboardingFeature2Title;

  /// No description provided for @onboardingFeature2Sub.
  ///
  /// In en, this message translates to:
  /// **'Build plans, stay consistent'**
  String get onboardingFeature2Sub;

  /// No description provided for @onboardingFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'See your progress'**
  String get onboardingFeature3Title;

  /// No description provided for @onboardingFeature3Sub.
  ///
  /// In en, this message translates to:
  /// **'Keep logging, watch it change'**
  String get onboardingFeature3Sub;

  /// No description provided for @goalCutDesc.
  ///
  /// In en, this message translates to:
  /// **'Lose body fat for a leaner shape'**
  String get goalCutDesc;

  /// No description provided for @goalMaintainDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold your current weight and shape'**
  String get goalMaintainDesc;

  /// No description provided for @goalBulkDesc.
  ///
  /// In en, this message translates to:
  /// **'Add muscle, build strength'**
  String get goalBulkDesc;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'Keep going — a better you is coming'**
  String get profileTagline;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersionLabel(String version);

  /// No description provided for @weekdayColumn.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get weekdayColumn;

  /// No description provided for @targetKcalColumn.
  ///
  /// In en, this message translates to:
  /// **'Target kcal'**
  String get targetKcalColumn;

  /// No description provided for @weekTotalKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly kcal'**
  String get weekTotalKcalLabel;

  /// No description provided for @dailyAvgKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily avg'**
  String get dailyAvgKcalLabel;

  /// No description provided for @hmlDayCountLabel.
  ///
  /// In en, this message translates to:
  /// **'H / M / L days'**
  String get hmlDayCountLabel;

  /// No description provided for @servingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get servingSize;

  /// No description provided for @nutritionResult.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionResult;

  /// No description provided for @mealAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String mealAddedTo(String meal);

  /// No description provided for @mealLoggedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {meal}'**
  String mealLoggedTo(String meal);

  /// No description provided for @addMealNamed.
  ///
  /// In en, this message translates to:
  /// **'Add {meal}'**
  String addMealNamed(String meal);

  /// No description provided for @cultivationPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cultivation'**
  String get cultivationPageTitle;

  /// No description provided for @cultivationHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'My Realm'**
  String get cultivationHeroLabel;

  /// No description provided for @cultivationLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cultivation not yet unlocked'**
  String get cultivationLockedTitle;

  /// No description provided for @cultivationLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Cultivation only tracks progress under the \"Cut\" goal — every 7,700 kcal deficit becomes a step on your path. Switch to a cut goal to begin.'**
  String get cultivationLockedBody;

  /// No description provided for @cultivationLockedCta.
  ///
  /// In en, this message translates to:
  /// **'Switch to cut goal'**
  String get cultivationLockedCta;

  /// No description provided for @cultivationMaxCaption.
  ///
  /// In en, this message translates to:
  /// **'Divine Transformation · Perfected'**
  String get cultivationMaxCaption;

  /// No description provided for @cultivationMaxSubcaption.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg lost or more · highest realm'**
  String cultivationMaxSubcaption(String kg);

  /// No description provided for @cultivationNextLayerCaption.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal to the next layer'**
  String cultivationNextLayerCaption(String kcal);

  /// No description provided for @cultivationNextRealmCaption.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal to {realm}'**
  String cultivationNextRealmCaption(String kcal, String realm);

  /// No description provided for @cultivationLostCaption.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg lost'**
  String cultivationLostCaption(String kg);

  /// No description provided for @cultivationStepsContribution.
  ///
  /// In en, this message translates to:
  /// **'Steps +{kcal} kcal'**
  String cultivationStepsContribution(String kcal);

  /// No description provided for @cultivationDietContribution.
  ///
  /// In en, this message translates to:
  /// **'Diet surplus +{kcal} kcal'**
  String cultivationDietContribution(String kcal);

  /// No description provided for @cultivationLayerBadge.
  ///
  /// In en, this message translates to:
  /// **'{realm} · Layer {layer}'**
  String cultivationLayerBadge(String realm, String layer);

  /// No description provided for @cultivationRealmQiRefining.
  ///
  /// In en, this message translates to:
  /// **'Qi Refining'**
  String get cultivationRealmQiRefining;

  /// No description provided for @cultivationRealmFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get cultivationRealmFoundation;

  /// No description provided for @cultivationRealmCoreFormation.
  ///
  /// In en, this message translates to:
  /// **'Core Formation'**
  String get cultivationRealmCoreFormation;

  /// No description provided for @cultivationRealmNascentSoul.
  ///
  /// In en, this message translates to:
  /// **'Nascent Soul'**
  String get cultivationRealmNascentSoul;

  /// No description provided for @cultivationRealmDivineTransformation.
  ///
  /// In en, this message translates to:
  /// **'Divine Transformation'**
  String get cultivationRealmDivineTransformation;

  /// No description provided for @cultivationSideHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get cultivationSideHistory;

  /// No description provided for @cultivationSideRealmGuide.
  ///
  /// In en, this message translates to:
  /// **'Realm guide'**
  String get cultivationSideRealmGuide;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfileTitle;

  /// No description provided for @realmGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Realm system'**
  String get realmGuideTitle;

  /// No description provided for @realmGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Every 7,700 kcal deficit ≈ 1 kg lost. Reach the cumulative weight-loss threshold shown for each realm to break through to the next — each realm is further divided into 9 layers.'**
  String get realmGuideIntro;

  /// No description provided for @realmGuideRangeLine.
  ///
  /// In en, this message translates to:
  /// **'{floor}–{ceil} kg · {kcal} kcal per layer'**
  String realmGuideRangeLine(String floor, String ceil, String kcal);

  /// No description provided for @realmGuideMaxRangeLine.
  ///
  /// In en, this message translates to:
  /// **'≥ {floor} kg · Fulfilled — no further breakthrough'**
  String realmGuideMaxRangeLine(String floor);

  /// No description provided for @realmGuideNextThresh.
  ///
  /// In en, this message translates to:
  /// **'→ {realm} {kg}kg'**
  String realmGuideNextThresh(String realm, String kg);

  /// No description provided for @realmGuideTagDone.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get realmGuideTagDone;

  /// No description provided for @realmGuideTagCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current · Layer {layer}'**
  String realmGuideTagCurrent(String layer);

  /// No description provided for @realmGuideTagLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get realmGuideTagLocked;

  /// No description provided for @realmGuideTagLockedMax.
  ///
  /// In en, this message translates to:
  /// **'Locked · Highest realm'**
  String get realmGuideTagLockedMax;

  /// No description provided for @realmGuideFootnoteTitle.
  ///
  /// In en, this message translates to:
  /// **'kcal sources:'**
  String get realmGuideFootnoteTitle;

  /// No description provided for @realmGuideFootnoteBody.
  ///
  /// In en, this message translates to:
  /// **'① Steps × 0.04 kcal/step; ② daily calorie surplus, counted only when at least 2 distinct meal types are logged that day (breakfast/lunch/dinner/snack).'**
  String get realmGuideFootnoteBody;

  /// No description provided for @realmGuideFootnoteNote.
  ///
  /// In en, this message translates to:
  /// **'This feature is currently only available to users on the \"Cut\" goal.'**
  String get realmGuideFootnoteNote;

  /// No description provided for @cultivationHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Cultivation log'**
  String get cultivationHistoryTitle;

  /// No description provided for @cultivationHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get cultivationHistoryEmpty;

  /// No description provided for @cultivationHistoryTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get cultivationHistoryTodayLabel;

  /// No description provided for @cultivationHistoryStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get cultivationHistoryStepsLabel;

  /// No description provided for @cultivationHistoryDietLabel.
  ///
  /// In en, this message translates to:
  /// **'Diet surplus'**
  String get cultivationHistoryDietLabel;

  /// No description provided for @cultivationHistoryTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cultivationHistoryTotalLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
