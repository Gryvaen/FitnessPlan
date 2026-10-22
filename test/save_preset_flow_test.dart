import 'dart:async';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/meals/save_preset_flow.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PresetRepository extends MealPresetRepository {
  _PresetRepository(AppDatabase db) : super(db, MealRepository(db));

  final existingNames = <String>{};
  final saves = <({String name, bool replaceExisting})>[];
  bool failQuery = false;
  bool failSave = false;
  Completer<MealPreset?>? pendingQuery;
  Completer<int>? pendingSave;

  @override
  Future<MealPreset?> presetByName(String name) async {
    if (failQuery) throw StateError('query failed');
    if (pendingQuery != null) return pendingQuery!.future;
    return existingNames.contains(name.trim())
        ? MealPreset(id: 1, name: name.trim(), createdAt: DateTime(2026))
        : null;
  }

  @override
  Future<int> createFromEntries({
    required String name,
    required List<MealEntry> entries,
    bool replaceExisting = false,
  }) async {
    if (failSave) throw StateError('save failed');
    saves.add((name: name, replaceExisting: replaceExisting));
    if (pendingSave != null) return pendingSave!.future;
    return 1;
  }
}

final _entry = MealEntry(
  id: 1,
  date: DateTime(2026),
  mealType: 'breakfast',
  foodId: 1,
  foodName: '燕麦',
  grams: 100,
  calories: 380,
  proteinG: 12,
  carbG: 65,
  fatG: 7,
  alcoholG: 0,
  fiberG: 0,
  sodiumMg: 0,
  sugarG: 0,
  saturatedFatG: 0,
  calciumMg: 0,
);

void main() {
  late AppDatabase db;
  late _PresetRepository repository;
  var presetListLoads = 0;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = _PresetRepository(db);
    presetListLoads = 0;
  });
  tearDown(() => db.close());

  Future<void> openFlow(WidgetTester tester, {bool empty = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealPresetRepositoryProvider.overrideWithValue(repository),
          mealPresetsProvider.overrideWith((ref) async {
            presetListLoads++;
            return <MealPreset>[];
          }),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(mealPresetsProvider);
                return TextButton(
                  onPressed: () => saveMealPresetFromEntries(
                    context: context,
                    ref: ref,
                    initialName: '早餐',
                    entries: empty ? [] : [_entry],
                  ),
                  child: const Text('开始'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'creates a preset and reports success without initial text focus',
    (tester) async {
      await openFlow(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isFalse,
      );
      await tap(tester, '保存');
      expect(repository.saves.single, (name: '早餐', replaceExisting: false));
      expect(find.text('套餐已保存'), findsOneWidget);
      expect(presetListLoads, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('conflicting name can be changed before saving', (tester) async {
    repository.existingNames.add('早餐');
    await openFlow(tester);
    await tap(tester, '保存');
    await tap(tester, '修改名称');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '早餐',
    );
    await tester.enterText(find.byType(TextField), '午餐');
    await tap(tester, '保存');
    expect(repository.saves.single, (name: '午餐', replaceExisting: false));
  });

  testWidgets('overwrite requires explicit confirmation', (tester) async {
    repository.existingNames.add('早餐');
    await openFlow(tester);
    await tap(tester, '保存');
    expect(repository.saves, isEmpty);
    await tap(tester, '覆盖');
    expect(repository.saves.single, (name: '早餐', replaceExisting: true));
  });

  for (final conflict in [false, true]) {
    testWidgets('cancel does not write (conflict: $conflict)', (tester) async {
      if (conflict) repository.existingNames.add('早餐');
      await openFlow(tester);
      if (conflict) await tap(tester, '保存');
      await tap(tester, '取消');
      expect(repository.saves, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final query in [true, false]) {
    testWidgets('reports ${query ? 'query' : 'save'} failure', (tester) async {
      repository.failQuery = query;
      repository.failSave = !query;
      await openFlow(tester);
      await tap(tester, '保存');
      expect(
        find.textContaining(query ? 'query failed' : 'save failed'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty entries do not open a name dialog', (tester) async {
    await openFlow(tester, empty: true);
    expect(find.byType(TextField), findsNothing);
    expect(repository.saves, isEmpty);
  });

  for (final query in [true, false]) {
    testWidgets('unmount during ${query ? 'query' : 'save'} is safe', (
      tester,
    ) async {
      if (query) {
        repository.pendingQuery = Completer<MealPreset?>();
      } else {
        repository.pendingSave = Completer<int>();
      }
      await openFlow(tester);
      await tap(tester, '保存');
      await tester.pumpWidget(const SizedBox.shrink());
      if (query) {
        repository.pendingQuery!.complete(null);
      } else {
        repository.pendingSave!.complete(1);
      }
      await tester.pumpAndSettle();
      if (query) expect(repository.saves, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unmount with name dialog open disposes its resources safely', (
    tester,
  ) async {
    await openFlow(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(repository.saves, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
