import 'package:diet/domain/cultivation.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/profile/cultivation_labels.dart';
import 'package:diet/ui/profile/cultivation_page.dart';
import 'package:diet/ui/profile/profile_page.dart';
import 'package:diet/ui/profile/realm_guide_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CutProfile extends ProfileNotifier {
  @override
  UserProfile? build() => const UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 175,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.cut,
    tdee: 2400,
    targets: MacroTargets(calories: 1900, proteinG: 120, carbG: 220, fatG: 60),
  );
}

Widget _app(Widget home, {double kgLost = 0, bool disableAnimations = false}) =>
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(_CutProfile.new),
        cultivationProgressProvider.overrideWithValue(
          computeCultivationProgress(kgLost),
        ),
        cultivationStepsTodayProvider.overrideWithValue(0),
        cultivationDietKcalTodayProvider.overrideWithValue(0),
        cultivationCheatPenaltyTodayProvider.overrideWithValue(0),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: home,
      ),
    );

Finder _image(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName ==
          'assets/cultivation/realms/$name',
);

void main() {
  testWidgets('every realm layer has bundled art for its current mode', (
    tester,
  ) async {
    const prefixes = {
      CultivationRealm.qiRefining: 'lianqi',
      CultivationRealm.foundation: 'zhuji',
      CultivationRealm.coreFormation: 'jiedan',
      CultivationRealm.nascentSoul: 'yuanying',
      CultivationRealm.divineTransformation: 'huashen',
    };
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    final scenes = <String>{};

    for (final entry in prefixes.entries) {
      for (var layer = 1; layer <= kCultivationLayers; layer++) {
        final name = entry.key.isMax ? entry.value : '${entry.value}_$layer';
        final stem = 'assets/cultivation/realms/$name';
        final still = entry.key.artAsset(layer);
        final animation = entry.key.artAsset(layer, animated: true);
        expect(still, '$stem.jpg');
        expect(assets, contains(still));
        if (kAnimatedRealmArt.contains(name)) {
          expect(animation, '$stem.webp');
          expect(assets, contains(animation));
        } else {
          expect(animation, still);
        }
        scenes.add(name);
      }
    }
    expect(scenes, hasLength(37));
    // Every listed animation must name a real scene.
    expect(scenes, containsAll(kAnimatedRealmArt));
  });

  testWidgets('hero and detail show the current realm art', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String expected(CultivationRealm realm, int layer) => realm
        .artAsset(layer, animated: true)
        .replaceFirst('assets/cultivation/realms/', '');

    await tester.pumpWidget(_app(const Scaffold(body: CultivationHeroCard())));
    expect(
      tester
          .widget<Image>(_image(expected(CultivationRealm.qiRefining, 1)))
          .fit,
      BoxFit.cover,
    );

    for (final page in [
      const Scaffold(body: CultivationHeroCard()),
      const CultivationPage(),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(page, kgLost: 20));
      expect(
        tester
            .widget<Image>(_image(expected(CultivationRealm.nascentSoul, 1)))
            .fit,
        BoxFit.cover,
      );
    }
  });

  testWidgets('reduced motion and the guide use static realm art', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(const CultivationPage(), disableAnimations: true),
    );
    expect(_image('lianqi_1.jpg'), findsOneWidget);
    expect(_image('lianqi_1.webp'), findsNothing);

    await tester.pumpWidget(
      _app(
        const Scaffold(body: CultivationHeroCard()),
        disableAnimations: true,
      ),
    );
    expect(_image('lianqi_1.jpg'), findsOneWidget);
    expect(_image('lianqi_1.webp'), findsNothing);

    await tester.pumpWidget(_app(const RealmGuidePage()));
    expect(_image('lianqi_9.jpg'), findsOneWidget);
    expect(_image('lianqi_9.webp'), findsNothing);
  });
}
