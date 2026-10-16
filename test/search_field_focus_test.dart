import 'package:diet/ui/widgets/search_field_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UnfocusOnKeyboardHide drops focus when the IME closes', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnfocusOnKeyboardHide(
            focusNode: focus,
            child: TextField(focusNode: focus),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    tester.view.resetViewInsets();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
