import 'dart:io';

import 'package:diet/ui/ink/ink_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new profile and tools PNG variants retain an alpha channel', () {
    const names = [
      'target',
      'notification',
      'tools',
      'folder',
      'share',
      'language',
      'moon',
      'sun',
      'download',
      'upload',
      'meditation',
      'chart',
      'trophy',
      'lock',
      'body-fat',
      'weight',
      'timer',
      'swap-vertical',
      'pause',
      'replay',
      'history',
      'backspace',
      'alarm',
      'schedule',
      'music',
      'vibration',
      'battery-alert',
      'notifications-off',
      'toggle-on',
      'toggle-off',
    ];
    for (final variant in const ['light', 'dark']) {
      for (final name in names) {
        final path = 'assets/ink/icons/$variant/$name-v1.png';
        final bytes = File(path).readAsBytesSync();
        final colorType = bytes[25];
        final hasTransparencyChunk = String.fromCharCodes(
          bytes,
        ).contains('tRNS');
        expect(
          colorType == 4 ||
              colorType == 6 ||
              (colorType == 3 && hasTransparencyChunk),
          isTrue,
          reason: '$path must use PNG alpha',
        );
      }
    }
  });

  test('profile and tools flows contain no platform icon implementations', () {
    const roots = ['lib/ui/profile', 'lib/ui/tools'];
    final violations = <String>[];
    final banned = <String, RegExp>{
      'Material icon': RegExp(r'\bIcons\.'),
      'Cupertino icon': RegExp(r'\bCupertinoIcons\.'),
      'native switch': RegExp(r'\bSwitch(?:ListTile)?\s*\('),
      'IconData plumbing': RegExp(r'\bIconData\b'),
    };

    for (final root in roots) {
      for (final entry in Directory(root).listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        final source = entry.readAsStringSync();
        for (final candidate in banned.entries) {
          if (candidate.value.hasMatch(source)) {
            violations.add('${entry.path}: ${candidate.key}');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  testWidgets('InkToggle exposes state and toggles from its full tap target', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: InkToggle(
              value: value,
              semanticLabel: '训练提醒',
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('训练提醒'), findsOneWidget);
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'asset',
        contains('toggle-off-v1.png'),
      ),
    );

    await tester.tap(find.byType(InkToggle));
    await tester.pump();
    expect(value, isTrue);
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'asset',
        contains('toggle-on-v1.png'),
      ),
    );
  });

  testWidgets('disabled InkToggle does not change state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InkToggle(value: true, semanticLabel: '饮水提醒', onChanged: null),
        ),
      ),
    );

    await tester.tap(find.byType(InkToggle));
    await tester.pump();
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'asset',
        contains('toggle-on-v1.png'),
      ),
    );
  });
}
