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
      expect(e.expression, '12 + 34');
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
      expect(e.input, '错误');
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
