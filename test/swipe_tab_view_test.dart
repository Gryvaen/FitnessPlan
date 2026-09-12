import 'package:diet/ui/shell/swipe_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final speed in [100.0, 2000.0, 6000.0]) {
    for (final direction in [-1.0, 1.0]) {
      testWidgets('edge swipe at $speed px/s in direction $direction', (
        tester,
      ) async {
        var selected = direction < 0 ? 0 : 1;
        final target = speed < 400 ? selected : 1 - selected;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SwipeTabView(
                    keepPagesAlive: true,
                    index: selected,
                    onIndexChanged: (i) => setState(() => selected = i),
                    children: const [
                      _RememberingGroup(name: 'Body'),
                      _RememberingGroup(name: 'Train'),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (direction < 0) {
          await tester.tap(find.text('Body tab 2'));
          await tester.pumpAndSettle();
        }
        await tester.flingFrom(
          const Offset(400, 350),
          Offset(40 * direction, 0),
          speed,
        );
        await tester.pumpAndSettle();
        expect(selected, target);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('returning to a group restores its last selected child', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        TextButton(
                          onPressed: () => setState(() => selected = i),
                          child: Text('Group $i'),
                        ),
                    ],
                  ),
                  Expanded(
                    child: SwipeTabView(
                      keepPagesAlive: true,
                      index: selected,
                      onIndexChanged: (i) => setState(() => selected = i),
                      children: const [
                        _RememberingGroup(name: 'Body'),
                        _RememberingGroup(name: 'Train'),
                        Center(child: Text('Notes')),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body tab 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Train tab 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group 0'));
    await tester.pumpAndSettle();
    expect(find.text('Body page 2').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Group 1'));
    await tester.pumpAndSettle();
    expect(find.text('Train page 1').hitTestable(), findsOneWidget);

    // A hard fling must page within the group without also leaving it.
    await tester.flingFrom(const Offset(100, 350), const Offset(1000, 0), 6000);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Train page 0').hitTestable(), findsOneWidget);

    // The next edge flick returns directly to Body's remembered last page.
    await tester.flingFrom(const Offset(400, 350), const Offset(40, 0), 2000);
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(find.text('Body page 2').hitTestable(), findsOneWidget);
    await tester.flingFrom(const Offset(400, 350), const Offset(-40, 0), 2000);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Train page 0').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
                    keepPagesAlive: true,
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

class _RememberingGroup extends StatefulWidget {
  const _RememberingGroup({required this.name});
  final String name;
  @override
  State<_RememberingGroup> createState() => _RememberingGroupState();
}

class _RememberingGroupState extends State<_RememberingGroup> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            TextButton(
              onPressed: () => setState(() => selected = i),
              child: Text('${widget.name} tab $i'),
            ),
        ],
      ),
      Expanded(
        child: SwipeTabView(
          keepPagesAlive: true,
          index: selected,
          onIndexChanged: (i) => setState(() => selected = i),
          children: [
            for (var i = 0; i < 3; i++)
              Center(child: Text('${widget.name} page $i')),
          ],
        ),
      ),
    ],
  );
}
