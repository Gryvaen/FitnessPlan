import 'package:diet/ui/loading/discipline_freedom_loading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not enter home while the entrance animation is playing', (
    tester,
  ) async {
    var finished = false;
    var prewarmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DisciplineFreedomLoadingPage(
          onInitialize: () async {},
          onPrewarm: () => prewarmed = true,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump();

    // Startup taps must not bypass a partially displayed loading animation.
    await tester.tap(find.byType(DisciplineFreedomLoadingPage));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, isFalse);
    expect(prewarmed, isFalse);
  });

  test('entrance keeps the intended 1.4 second duration', () {
    expect(
      DisciplineFreedomLoadingPage.entranceDuration,
      const Duration(milliseconds: 1400),
    );
  });
}
