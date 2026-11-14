import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/cultivation_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/profile/cut_round_stats_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CutRoundStatsPage(),
      ),
    ),
  );
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
  test('cultivation statistics use their dedicated ink glyph', () {
    expect(InkGlyph.cultivationStats.assetName, 'cultivation-stats');
  });

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('shows the cut round in progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final today = CalendarDay.todayLocal();
    await CultivationRepository(await SharedPreferences.getInstance()).save(
      CutCultivationState(
        segments: [
          CutCultivationSegment(start: CalendarDay.addDays(today, -2)),
        ],
      ),
    );
    await _pump(tester, db);
    expect(find.text('本轮统计'), findsOneWidget);
    expect(find.text('第 3 天'), findsOneWidget);
    expect(find.text('统计说明'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('says so outside a cut round', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, db);
    expect(find.text('当前不在减脂轮内'), findsOneWidget);
  });
}
