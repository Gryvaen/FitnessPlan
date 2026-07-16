import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet/ui/theme/app_theme.dart';

void main() {
  testWidgets('listBottomInset includes view padding and FAB room', (tester) async {
    late double insetWithFab;
    late double insetNoFab;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: Builder(
          builder: (context) {
            insetWithFab = listBottomInset(context);
            insetNoFab = listBottomInset(context, hasFab: false);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(insetWithFab, 72 + 60 + 24);
    expect(insetNoFab, 16 + 60 + 24);
  });

  testWidgets('floating pill icon bar builds at 360 and 1.3 text scale',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const ColoredBox(color: Color(0xFFF7F9F7)),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      for (final icon in const [
                        Icons.today,
                        Icons.restaurant,
                        Icons.fitness_center,
                        Icons.person,
                      ])
                        Expanded(
                          child: Center(child: Icon(icon, size: 24)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.today), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
