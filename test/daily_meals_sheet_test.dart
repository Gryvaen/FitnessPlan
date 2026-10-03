import 'package:diet/data/db.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/meals/daily_meals_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('daily records open as a sheet and keep date navigation', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final today = DateTime.now();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push(dailyMealsPath(today)),
                child: const Text('Open records'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/day-meals',
          pageBuilder: (_, state) => DailyMealsSheetPage(
            key: state.pageKey,
            date: DateTime.parse(state.uri.queryParameters['date']!),
          ),
        ),
        GoRoute(
          path: '/log-meal',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Return from log'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open records'));
    await tester.pumpAndSettle();

    final sheetContext = tester.element(find.byType(DailyMealsPage));
    final sheetRoute =
        ModalRoute.of(sheetContext) as ModalBottomSheetRoute<void>;
    expect(sheetRoute, isA<ModalBottomSheetRoute<void>>());
    expect(sheetRoute.showDragHandle, isTrue);
    expect(sheetRoute.isScrollControlled, isTrue);
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.byTooltip('记一笔'), findsWidgets);
    expect(find.byTooltip('后一天'), findsNothing);
    expect(find.byTooltip('回到今日'), findsNothing);

    await tester.tap(find.byTooltip('前一天'));
    await tester.pumpAndSettle();
    expect(
      DateUtils.isSameDay(
        tester.widget<DailyMealsPage>(find.byType(DailyMealsPage)).date,
        today.subtract(const Duration(days: 1)),
      ),
      isTrue,
    );
    expect(find.byTooltip('记一笔'), findsNothing);
    expect(
      ModalRoute.of(tester.element(find.byType(DailyMealsPage))),
      isA<ModalBottomSheetRoute<void>>(),
    );

    await tester.longPress(find.byTooltip('回到今日'));
    await tester.pumpAndSettle();
    expect(
      DateUtils.isSameDay(
        tester.widget<DailyMealsPage>(find.byType(DailyMealsPage)).date,
        today,
      ),
      isTrue,
    );
    expect(find.byTooltip('后一天'), findsNothing);

    await tester.tap(find.byTooltip('前一天'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('后一天'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('记一笔').first);
    await tester.pumpAndSettle();
    expect(find.text('Return from log'), findsOneWidget);
    await tester.tap(find.text('Return from log'));
    await tester.pumpAndSettle();
    expect(
      ModalRoute.of(tester.element(find.byType(DailyMealsPage))),
      isA<ModalBottomSheetRoute<void>>(),
    );

    expect(find.byTooltip('完成'), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(DailyMealsPage), findsNothing);
    expect(find.text('Open records'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1));
  });
}
