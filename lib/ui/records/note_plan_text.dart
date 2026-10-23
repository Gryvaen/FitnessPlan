import 'package:flutter/services.dart';

final _number = RegExp(r'^\d+\.[ \t]?', multiLine: true);

/// Old plans stored one item per line. Numbered plans retain all their spacing.
String displayPlan(String text) {
  if (text.trim().isEmpty) return '1. ';
  if (RegExp(r'^\d+\.\s').hasMatch(text)) return text;
  final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
  var index = 0;
  return lines.map((line) => '${++index}. $line').join('\n\n');
}

String planContent(String text) =>
    text.replaceAll(_number, '').trim().isEmpty ? '' : text;

/// Only a single inserted newline is eligible; paste and composing edits pass
/// through unchanged. Numbering is repaired only when creating a new item.
class PlanNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed ||
        !oldValue.composing.isCollapsed ||
        !oldValue.selection.isCollapsed ||
        !newValue.selection.isCollapsed) {
      return newValue;
    }
    final offset = oldValue.selection.start;
    if (offset < 0 ||
        newValue.text != oldValue.text.replaceRange(offset, offset, '\n') ||
        newValue.selection.start != offset + 1) {
      return newValue;
    }
    final end = offset + 1;
    final before = newValue.text.substring(0, end);
    if (!before.endsWith('\n\n')) return newValue;
    final matches = _number.allMatches(before).toList();
    if (matches.isEmpty) return newValue;
    final current = matches.last;
    if (before.substring(current.end).trim().isEmpty) return newValue;
    final prefix = '${matches.length + 1}. ';
    var text = newValue.text.replaceRange(end, end, prefix);
    var index = 0;
    text = text.replaceAllMapped(_number, (_) => '${++index}. ');
    // Prefix repair before the cursor may change its width (e.g. 9 -> 10).
    final cursor = _number.allMatches(text).elementAt(matches.length).end;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
