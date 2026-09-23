import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home flow contains no platform icon implementations', () {
    const roots = [
      'lib/ui/today',
      'lib/ui/meals',
      'lib/ui/foods',
      'lib/ui/records',
      'lib/ui/strategy',
      'lib/ui/widgets',
    ];
    final violations = <String>[];
    final banned = <String, RegExp>{
      'Material icon': RegExp(r'\bIcons\.'),
      'Cupertino icon': RegExp(r'\bCupertinoIcons\.'),
      'native checkbox': RegExp(r'\bCheckbox\s*\('),
      'native radio': RegExp(r'\bRadio(?:ListTile)?(?:<[^>]+>)?\s*\('),
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

  test('implicit app bar actions use ink PNG glyphs', () {
    final theme = File('lib/ui/theme/app_theme.dart').readAsStringSync();
    expect(theme, contains('backButtonIconBuilder'));
    expect(theme, contains('InkGlyph.chevronLeft'));
    expect(theme, contains('closeButtonIconBuilder'));
    expect(theme, contains('InkGlyph.close'));
  });

  test('log meal custom action has its dedicated ink brush glyph', () {
    final page = File('lib/ui/meals/log_meal_page.dart').readAsStringSync();
    expect(page, contains('tooltip: l10n.addCustomFood'));
    expect(page, contains('InkIcon(InkGlyph.autoFix, size: 29)'));
  });
}
