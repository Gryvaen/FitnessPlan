import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/experience_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/records/experience_page.dart';
import 'package:diet/ui/records/notes_records_tab.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpNotes(WidgetTester tester, AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
  );
  // Dispose the providers (and their drift streams) before the database
  // closes; tear-downs run last-registered first.
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/records',
    routes: [
      GoRoute(
        path: '/records',
        builder: (_, _) => const Scaffold(body: NotesRecordsTab()),
        routes: [
          GoRoute(
            path: 'experience',
            builder: (_, _) => const ExperiencePage(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('counts numbered items that have text', () {
    expect(experienceItemCount('1. '), 0);
    expect(experienceItemCount('1. 少吃夜宵'), 1);
    expect(experienceItemCount('1. 少吃夜宵\n补充\n\n2. '), 1);
    expect(experienceItemCount('1. 少吃夜宵\n\n2. 训练前吃香蕉'), 2);
  });

  testWidgets(
    'seal opens 经验之谈; Enter twice numbers the next item',
    timeout: const Timeout(Duration(seconds: 30)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = ExperienceRepository(db);
      await _pumpNotes(tester, db);

      // The header is just the 验 seal and +, no title or subtitle text.
      expect(find.text('每日笔记'), findsNothing);
      expect(find.text('记录训练、饮食与身体感受'), findsNothing);
      final seal = find.byKey(const ValueKey('experience-entry'));
      expect(find.descendant(of: seal, matching: find.text('验')), findsOne);

      await tester.tap(seal);
      await tester.pumpAndSettle();
      expect(find.text('经验之谈'), findsOneWidget);
      final input = find.byKey(const ValueKey('experience-text'));
      TextEditingController ctrl() =>
          tester.widget<TextField>(input).controller!;
      expect(ctrl().text, '1. ');

      await tester.enterText(input, '1. 少吃夜宵\n');
      await tester.enterText(input, '1. 少吃夜宵\n\n');
      expect(ctrl().text, '1. 少吃夜宵\n\n2. ');
      await tester.enterText(input, '1. 少吃夜宵\n\n2. 训练前吃香蕉');
      await tester.pump();
      expect(find.text('共 2 条'), findsOneWidget);

      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('experience-entry')), findsOneWidget);
      expect(await repo.load(), '1. 少吃夜宵\n\n2. 训练前吃香蕉');

      // Reopening restores the text.
      await tester.tap(find.byKey(const ValueKey('experience-entry')));
      await tester.pumpAndSettle();
      expect(ctrl().text, '1. 少吃夜宵\n\n2. 训练前吃香蕉');
      expect(find.text('共 2 条'), findsOneWidget);
    },
  );
}
