import 'package:diet/ui/shell/swipe_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final notesFirst in [false, true]) {
    testWidgets(
      'notes can swipe ${notesFirst ? 'left' : 'right'} into training and back',
      (tester) async {
        final notesIndex = notesFirst ? 0 : 1;
        final trainingIndex = 1 - notesIndex;
        var selected = notesIndex;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                final training = SwipeTabView(
                  index: 0,
                  onIndexChanged: (_) {},
                  children: const [Center(child: Text('Training'))],
                );
                const notes = Center(child: Text('Notes'));
                return Scaffold(
                  body: SwipeTabView(
                    index: selected,
                    onIndexChanged: (i) => setState(() => selected = i),
                    children: notesFirst
                        ? [notes, training]
                        : [training, notes],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final direction = notesFirst ? -1.0 : 1.0;
        final gesture = await tester.startGesture(
          Offset(notesFirst ? 650 : 150, 300),
        );
        // Pump between moves so the incoming nested pager mounts while the
        // outer pager still owns the drag (the original regression).
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(Offset(70 * direction, 0));
          await tester.pump(const Duration(milliseconds: 40));
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(selected, trainingIndex);
        expect(tester.getCenter(find.text('Training')).dx, closeTo(400, 1));

        // The nested pager must still hand an edge swipe back to its parent.
        await tester.drag(find.text('Training'), Offset(-300 * direction, 0));
        await tester.pumpAndSettle();
        expect(selected, notesIndex);
        expect(tester.getCenter(find.text('Notes')).dx, closeTo(400, 1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
