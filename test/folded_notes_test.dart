import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/widgets/folded_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FoldedNotes hides its notes until the title is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FoldedNotes(title: 'How it works', notes: ['first', 'second']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsNothing);

    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
  });
}
