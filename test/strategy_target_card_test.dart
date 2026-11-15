import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/strategy/strategy_target_card.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {AppThemeId theme = AppThemeId.fresh}) =>
    MaterialApp(
      theme: AppTheme.ofId(theme),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: ListView(padding: const EdgeInsets.all(20), children: [child]),
      ),
    );

void main() {
  group('MacroSplitBar.shares', () {
    test('splits by energy (4 / 4 / 9 kcal per gram)', () {
      final s = MacroSplitBar.shares(proteinG: 100, carbG: 100, fatG: 0);
      expect(s[0], closeTo(0.5, 1e-9));
      expect(s[1], closeTo(0.5, 1e-9));
      expect(s[2], 0);

      final f = MacroSplitBar.shares(proteinG: 0, carbG: 0, fatG: 10);
      expect(f, [0, 0, 1]);

      final mixed = MacroSplitBar.shares(proteinG: 150, carbG: 200, fatG: 60);
      // 600 + 800 + 540 = 1940 kcal.
      expect(mixed[0], closeTo(600 / 1940, 1e-9));
      expect(mixed[1], closeTo(800 / 1940, 1e-9));
      expect(mixed[2], closeTo(540 / 1940, 1e-9));
    });

    test('empty or invalid input yields no share', () {
      expect(MacroSplitBar.shares(proteinG: 0, carbG: 0, fatG: 0), [0, 0, 0]);
      expect(MacroSplitBar.shares(proteinG: -5, carbG: double.nan, fatG: 0), [
        0,
        0,
        0,
      ]);
    });
  });

  for (final theme in [AppThemeId.fresh, AppThemeId.graphite]) {
    testWidgets('card shows kcal, caption, macros and fits 360px '
        '(${theme.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          const StrategyTargetCard(
            title: 'Carb cycling · v3',
            status: 'Active',
            kcal: 2149.6,
            kcalCaption: 'Today · High-carb day with a long caption',
            proteinG: 144,
            carbG: 260.4,
            fatG: 52,
            footnote: 'Daily avg 1850 kcal · since 11/02',
          ),
          theme: theme,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('2150'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Carb cycling · v3'), findsOneWidget);
      expect(find.textContaining('Today · High-carb'), findsOneWidget);
      expect(find.textContaining('144g', findRichText: true), findsOneWidget);
      expect(find.textContaining('260g', findRichText: true), findsOneWidget);
      expect(find.textContaining('52g', findRichText: true), findsOneWidget);
      expect(find.byType(MacroSplitBar), findsOneWidget);
    });
  }

  testWidgets('fact row wraps long values instead of overflowing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        const StrategyFactRow(
          label: 'This plan’s baseline',
          value: 'Balanced deficit · 1920 → 1880',
          unit: 'kcal',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
