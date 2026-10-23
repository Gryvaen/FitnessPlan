import 'package:diet/ui/records/note_plan_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  final formatter = PlanNumberFormatter();
  TextEditingValue enter(String text, [int? cursor]) {
    final at = cursor ?? text.length;
    return formatter.formatEditUpdate(
      value(text, at),
      value(text.replaceRange(at, at, '\n'), at + 1),
    );
  }

  test('legacy plans, numbered plans and empty content', () {
    expect(displayPlan(''), '1. ');
    expect(displayPlan('跑步\n拉伸'), '1. 跑步\n\n2. 拉伸');
    expect(displayPlan('1. 跑步\n补充\n\n2. 拉伸'), '1. 跑步\n补充\n\n2. 拉伸');
    expect(planContent('1. \n\n2. '), '');
    expect(planContent('1. 跑步'), '1. 跑步');
  });
  test('single enter continues; double enter numbers next item', () {
    expect(enter('1. 跑步').text, '1. 跑步\n');
    final next = enter('1. 跑步\n');
    expect(next.text, '1. 跑步\n\n2. ');
    expect(next.selection.start, next.text.length);
    expect(enter('1. 跑步\n\n2. 拉伸\n').text, '1. 跑步\n\n2. 拉伸\n\n3. ');
    expect(enter('1. \n').text, '1. \n\n');
  });
  test('middle insertion renumbers following items and keeps cursor', () {
    final result = enter('1. 跑步\n\n2. 拉伸', 6);
    expect(result.text, '1. 跑步\n\n2. \n3. 拉伸');
    expect(result.selection.start, '1. 跑步\n\n2. '.length);
  });
  test('paste and composing input pass through unchanged', () {
    final pasted = value('1. 跑步\n\n粘贴');
    expect(formatter.formatEditUpdate(value('1. 跑步'), pasted), pasted);
    final composing = value(
      '1. 跑步\n\n',
    ).copyWith(composing: const TextRange(start: 3, end: 5));
    expect(formatter.formatEditUpdate(value('1. 跑步\n'), composing), composing);
  });
}
