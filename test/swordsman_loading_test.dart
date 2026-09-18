import 'package:diet/features/loading/swordsman_animation.dart';
import 'package:diet/features/loading/swordsman_loading_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timeline dissolves the landscape from bottom to top', () {
    final beginning = SwordsmanFrame.at(.05, reduceMotion: false);
    final middle = SwordsmanFrame.at(.45, reduceMotion: false);
    final ending = SwordsmanFrame.at(.9, reduceMotion: false);
    expect(beginning.revealProgress, lessThan(middle.revealProgress));
    expect(middle.revealProgress, lessThan(ending.revealProgress));
    expect(ending.revealProgress, 1);
  });

  test('sword travels upward and fades before the final frame', () {
    final entering = SwordsmanFrame.at(.15, reduceMotion: false);
    final passing = SwordsmanFrame.at(.60, reduceMotion: false);
    final exited = SwordsmanFrame.at(.84, reduceMotion: false);
    final finished = SwordsmanFrame.at(1, reduceMotion: false);
    expect(entering.swordY, greaterThan(passing.swordY));
    expect(entering.swordOpacity, greaterThan(0));
    expect(passing.swordOpacity, greaterThan(0));
    expect(exited.swordY, lessThan(-.35));
    expect(exited.swordOpacity, 1);
    expect(finished.swordOpacity, 0);
    expect(finished.revealProgress, 1);
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
      expect(find.byType(Image), findsAtLeastNWidgets(2));
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
