import 'package:flutter_test/flutter_test.dart';
import 'package:diet/domain/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('chain add then equals', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('2');
      e.op('+');
      expect(e.expression, '12 +');
      e.digit('3');
      e.digit('4');
      // Expression stays as pending op; current entry is only in [input].
      expect(e.expression, '12 +');
      expect(e.input, '34');
      final h = e.equals();
      expect(h, isNotNull);
      expect(h!.expression, '12 + 34 =');
      expect(h.result, '46');
      expect(e.input, '46');
      expect(e.expression, '12 + 34 =');
    });

    test('left-associative chain', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('0');
      e.op('−');
      e.digit('3');
      e.op('×');
      expect(e.input, '7');
      e.digit('2');
      final h = e.equals();
      expect(h!.result, '14');
      expect(h.expression, '7 × 2 =');
    });

    test('divide by zero errors', () {
      final e = CalculatorEngine();
      e.digit('8');
      e.op('÷');
      e.digit('0');
      expect(e.equals(), isNull);
      expect(e.error, isTrue);
      expect(e.input, 'Error');
    });

    test('backspace', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('2');
      e.digit('3');
      e.backspace();
      expect(e.input, '12');
      e.backspace();
      e.backspace();
      expect(e.input, '0');
      expect(e.fresh, isTrue);
    });

    test('backspace undoes pending operator', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('2');
      e.op('+');
      expect(e.expression, '12 +');
      expect(e.fresh, isTrue);
      e.backspace();
      expect(e.pendingOp, isNull);
      expect(e.expression, isEmpty);
      expect(e.input, '12');
      expect(e.fresh, isFalse);
      e.backspace();
      expect(e.input, '1');
    });

    test('backspace while typing right operand', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('2');
      e.op('+');
      e.digit('3');
      e.digit('4');
      expect(e.input, '34');
      expect(e.expression, '12 +');
      e.backspace();
      expect(e.input, '3');
      expect(e.expression, '12 +');
      e.backspace();
      expect(e.input, '0');
      e.backspace();
      expect(e.pendingOp, isNull);
      expect(e.input, '12');
    });

    test('backspace edits result after equals', () {
      final e = CalculatorEngine();
      e.digit('1');
      e.digit('2');
      e.op('+');
      e.digit('3');
      e.equals();
      expect(e.input, '15');
      e.backspace();
      expect(e.expression, isEmpty);
      expect(e.input, '1');
    });

    test('C clears entry; AC clears all', () {
      final e = CalculatorEngine();
      e.digit('9');
      e.op('+');
      expect(e.showsAllClear, isFalse);
      e.clearEntry();
      expect(e.input, '0');
      expect(e.pendingOp, '+');
      expect(e.expression, '9 +');
      expect(e.showsAllClear, isTrue);
      e.clear();
      expect(e.pendingOp, isNull);
      expect(e.expression, isEmpty);
    });

    test('repeat equals reapplies last operand', () {
      final e = CalculatorEngine();
      e.digit('5');
      e.op('+');
      e.digit('3');
      expect(e.equals()!.result, '8');
      expect(e.equals()!.result, '11');
      expect(e.equals()!.result, '14');
    });

    test('percent of accumulator with pending op', () {
      final e = CalculatorEngine();
      e.digit('2');
      e.digit('0');
      e.digit('0');
      e.op('+');
      e.digit('1');
      e.digit('0');
      e.percent();
      expect(e.input, '20');
      expect(e.equals()!.result, '220');
    });

    test('memory add recall clear', () {
      final e = CalculatorEngine();
      e.digit('5');
      e.memoryAdd();
      expect(e.hasMemory, isTrue);
      e.clear();
      e.digit('3');
      e.memoryAdd();
      e.memoryRecall();
      expect(e.input, '8');
      e.memorySub();
      e.clear();
      e.memoryRecall();
      expect(e.input, '0');
      e.memoryClear();
      expect(e.hasMemory, isFalse);
    });

    test('loadResult from history', () {
      final e = CalculatorEngine();
      e.digit('9');
      e.op('+');
      e.loadResult('42');
      expect(e.input, '42');
      expect(e.expression, isEmpty);
      expect(e.pendingOp, isNull);
    });
  });
}
