/// One completed calculation for history.
class CalcHistoryEntry {
  const CalcHistoryEntry({
    required this.expression,
    required this.result,
    required this.at,
  });

  final String expression;
  final String result;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'at': at.toIso8601String(),
      };

  factory CalcHistoryEntry.fromJson(Map<String, dynamic> json) =>
      CalcHistoryEntry(
        expression: json['expression'] as String,
        result: json['result'] as String,
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Left-associative chain calculator with expression line + memory.
class CalculatorEngine {
  String expression = '';
  String input = '0';
  double? _acc;
  String? _op;
  bool fresh = true;
  bool error = false;
  double? memory;

  bool get hasMemory => memory != null;

  /// Current pending operator (for UI highlight), or null.
  String? get pendingOp => _op;

  void digit(String d) {
    if (error) clear();
    if (fresh) {
      if (expression.endsWith(' =')) expression = '';
      input = d;
      fresh = false;
    } else {
      if (input == '0') {
        input = d;
      } else if (input.length < 14) {
        input += d;
      }
    }
    _syncExpressionTrailing();
  }

  void dot() {
    if (error) clear();
    if (fresh) {
      if (expression.endsWith(' =')) expression = '';
      input = '0.';
      fresh = false;
    } else if (!input.contains('.') && input.length < 14) {
      input += '.';
    }
    _syncExpressionTrailing();
  }

  void op(String operator) {
    if (error) clear();
    final cur = double.tryParse(input);
    if (cur == null) {
      _setError();
      return;
    }

    if (_acc != null && _op != null && !fresh) {
      final r = _apply(_acc!, _op!, cur);
      if (r == null) {
        _setError();
        return;
      }
      _acc = r;
      input = format(r);
    } else {
      _acc = cur;
    }
    _op = operator;
    fresh = true;
    expression = '${format(_acc!)} $operator';
  }

  /// Returns a history entry when a full `a op b =` succeeds.
  CalcHistoryEntry? equals() {
    if (error || _acc == null || _op == null) return null;
    final cur = double.tryParse(input);
    if (cur == null) {
      _setError();
      return null;
    }
    final r = _apply(_acc!, _op!, cur);
    if (r == null) {
      _setError();
      return null;
    }
    final left = format(_acc!);
    final right = format(cur);
    final exprLine = '$left $_op $right =';
    final resultStr = format(r);
    expression = exprLine;
    input = resultStr;
    _acc = r;
    _op = null;
    fresh = true;
    return CalcHistoryEntry(
      expression: exprLine,
      result: resultStr,
      at: DateTime.now(),
    );
  }

  void clear() {
    expression = '';
    input = '0';
    _acc = null;
    _op = null;
    fresh = true;
    error = false;
  }

  void backspace() {
    if (error) {
      clear();
      return;
    }
    if (fresh) return;
    if (input.length <= 1 || (input.length == 2 && input.startsWith('-'))) {
      input = '0';
      fresh = true;
    } else {
      input = input.substring(0, input.length - 1);
    }
    _syncExpressionTrailing();
  }

  void negate() {
    if (error) return;
    if (input == '0' || input == '0.') return;
    if (input.startsWith('-')) {
      input = input.substring(1);
    } else {
      input = '-$input';
    }
    fresh = false;
    _syncExpressionTrailing();
  }

  void percent() {
    if (error) return;
    final cur = double.tryParse(input);
    if (cur == null) return;
    input = format(cur / 100);
    fresh = true;
    _syncExpressionTrailing();
  }

  void memoryClear() => memory = null;

  void memoryRecall() {
    if (memory == null) return;
    if (error) clear();
    input = format(memory!);
    fresh = true;
    _syncExpressionTrailing();
  }

  void memoryAdd() {
    final cur = double.tryParse(input);
    if (cur == null || error) return;
    memory = (memory ?? 0) + cur;
  }

  void memorySub() {
    final cur = double.tryParse(input);
    if (cur == null || error) return;
    memory = (memory ?? 0) - cur;
  }

  /// Load a past result into the input line (clears pending expression).
  void loadResult(String result) {
    clear();
    input = result;
    fresh = true;
  }

  void _syncExpressionTrailing() {
    if (_op == null || _acc == null) {
      if (expression.endsWith(' =')) {
        // Keep completed expression until next op/digit clears via fresh path.
      }
      return;
    }
    if (fresh) {
      expression = '${format(_acc!)} $_op';
    } else {
      expression = '${format(_acc!)} $_op $input';
    }
  }

  void _setError() {
    error = true;
    expression = '';
    input = 'Error';
    _acc = null;
    _op = null;
    fresh = true;
  }

  static double? _apply(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return null;
        return a / b;
      default:
        return null;
    }
  }

  static String format(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == v.roundToDouble() && v.abs() < 1e12) {
      return v.round().toString();
    }
    var s = v.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    if (s.length > 14) {
      s = v.toStringAsExponential(5);
    }
    return s;
  }
}
