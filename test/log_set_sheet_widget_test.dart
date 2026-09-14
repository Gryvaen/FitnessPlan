import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/records/log_set_sheet.dart';
import 'package:diet/ui/widgets/form_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openSheet(
  WidgetTester tester, {
  ExerciseUnit unit = ExerciseUnit.reps,
  int target = 4,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showLogSetSheet(
                context: context,
                ref: ref,
                day: DateTime.now(),
                exerciseName: '哑铃卧推',
                unit: unit,
                dayWorkoutItemId: 1,
                completedSets: 3,
                targetSets: target,
                perSetValue: 12,
                initialActualWeightKg: 20,
                initialNote: '原有备注',
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'optional fields collapse without losing edits and weights convert both ways',
    (tester) async {
      await openSheet(tester);
      expect(find.byType(AppOptionalDropdown<double>), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('重量'));
      await tester.pumpAndSettle();
      var fields = tester
          .widgetList<AppOptionalDropdown<double>>(
            find.byType(AppOptionalDropdown<double>),
          )
          .toList();
      expect(fields[0].value, 20);
      expect(fields[1].value, closeTo(FormOptions.kgToLbs(20), .01));
      fields[1].onChanged(65);
      await tester.pumpAndSettle();
      fields = tester
          .widgetList<AppOptionalDropdown<double>>(
            find.byType(AppOptionalDropdown<double>),
          )
          .toList();
      expect(fields[0].value, closeTo(FormOptions.lbsToKg(65), .01));
      expect(fields[1].value, 65);
      fields[0].onChanged(30);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重量'));
      await tester.pumpAndSettle();
      expect(find.byType(AppOptionalDropdown<double>), findsNothing);
      await tester.tap(find.text('重量'));
      await tester.pumpAndSettle();
      fields = tester
          .widgetList<AppOptionalDropdown<double>>(
            find.byType(AppOptionalDropdown<double>),
          )
          .toList();
      expect(fields[0].value, 30);
      expect(fields[1].value, closeTo(FormOptions.kgToLbs(30), .01));
      fields[0].onChanged(null);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<AppOptionalDropdown<double>>(
              find.byType(AppOptionalDropdown<double>),
            )
            .every((f) => f.value == null),
        isTrue,
      );
      await tester.tap(find.text('重量'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加备注'));
      await tester.pumpAndSettle();
      expect(find.text('原有备注'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '更新备注');
      await tester.tap(find.text('添加备注'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加备注'));
      await tester.pumpAndSettle();
      expect(find.text('更新备注'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small screen with keyboard keeps save accessible and allows scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await openSheet(tester, unit: ExerciseUnit.seconds, target: 20);
      expect(find.text('每组时长（秒）'), findsOneWidget);
      await tester.tap(find.text('添加备注'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, '保存训练记录');
      expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(360));
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
