import 'package:diet/features/loading/swordsman_animation.dart';
import 'package:diet/features/loading/swordsman_loading_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timeline shows ink slash only during the strike window', () {
    expect(SwordsmanFrame.at(.67, reduceMotion: false).slashOpacity, 0);
    expect(SwordsmanFrame.at(.72, reduceMotion: false).slashOpacity, 1);
    expect(SwordsmanFrame.at(.77, reduceMotion: false).slashOpacity, 0);
  });

  test('flying sword follows its path tangent', () {
    final entering = SwordsmanFrame.at(.25, reduceMotion: false);
    final passing = SwordsmanFrame.at(.60, reduceMotion: false);
    expect(entering.swordOpacity, greaterThan(0));
    expect(passing.swordOpacity, greaterThan(0));
    expect(entering.swordRotation, isNot(equals(passing.swordRotation)));
  });

  testWidgets('scene lays out on narrow and tall phones', (tester) async {
    for (final size in [const Size(360, 640), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwordsmanLoadingScene(
              animation: AlwaysStoppedAnimation(.72),
              reduceMotion: false,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNWidgets(3));
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
