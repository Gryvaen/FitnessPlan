import 'package:diet/domain/cultivation.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/profile/profile_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cultivation entry is a custom ink card without stock controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cultivationEligibleProvider.overrideWithValue(true),
          cultivationProgressProvider.overrideWithValue(
            const CultivationProgress(
              kgLost: 4,
              realm: CultivationRealm.foundation,
              layer: 3,
              layerProgress: .4,
              kcalToNextLayer: 1000,
              kcalToNextRealm: 46000,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: CultivationHeroCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final card = find.byKey(const ValueKey('cultivation-ink-card'));
    expect(card, findsOneWidget);
    expect(tester.getSize(card).height, 138);
    expect(
      find.descendant(of: card, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byType(Card)),
      findsNothing,
    );
    final seal = tester.widget<InkSeal>(
      find.descendant(of: card, matching: find.byType(InkSeal)),
    );
    expect(seal.character, '境');
    expect(
      find.byKey(const ValueKey('cultivation-layer-marks')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
