import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/note_repository.dart';
import 'package:diet/l10n/app_localizations_ext.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/records/note_edit_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'plan starts unfocused, switches without duplication and saves on back',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = NoteRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NoteEditPage(),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<String>), findsNothing);
      await tester.tap(find.byKey(const ValueKey('note-mode-toggle')));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '1. ');
      expect(field.focusNode!.hasFocus, isFalse);
      await tester.enterText(find.byType(TextField), '1. 跑步\n补充说明\n\n2. 拉伸');
      await tester.tap(find.byKey(const ValueKey('note-mode-toggle')));
      await tester.pump();
      expect(field.controller!.text, '');
      await tester.enterText(find.byType(TextField), '今天状态很好');
      await tester.tap(find.byKey(const ValueKey('note-mode-toggle')));
      await tester.pump();
      expect(field.controller!.text, '1. 跑步\n补充说明\n\n2. 拉伸');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final note = await repo.getByDate(AppDates.todayLocal(), mode: 'plan');
      expect((await repo.getByDate(AppDates.todayLocal()))!.content, '今天状态很好');
      expect(note!.mode, 'plan');
      expect(note.content, '1. 跑步\n补充说明\n\n2. 拉伸');
      expect(find.text('打开'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );
}
