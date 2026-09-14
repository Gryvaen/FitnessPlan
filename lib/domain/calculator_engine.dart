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
///
/// Display contract:
/// - [expression] shows the pending op (`12 +`) or a finished line (`12 + 3 =`)
/// - [input] is always the large current value — never duplicated into
///   [expression] while typing the right-hand operand
class CalculatorEngine {
  String expression = '';
  String input = '0';
  double? _acc;
  String? _op;
  bool fresh = true;
  bool error = false;
  double? memory;

  /// For repeating `=` (e.g. `5 + 3 = =` → 11).
  String? _lastOp;
  double? _lastRhs;

  bool get hasMemory => memory != null;

  /// Current pending operator (for UI highlight), or null.
  String? get pendingOp => _op;

  /// iOS-style: show AC when idle at zero; otherwise C to clear the entry.
  bool get showsAllClear {
    if (error) return true;
    if (!fresh) return false;
    if (input != '0' && input != '0.') return false;
    return true;
  }

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
    _refreshPendingExpression();
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
    _refreshPendingExpression();
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
    _lastOp = null;
    _lastRhs = null;
    fresh = true;
    expression = '${format(_acc!)} $operator';
  }

  /// Returns a history entry when a calculation succeeds.
  CalcHistoryEntry? equals() {
    if (error) return null;

    // Repeat last operation: `5 + 3 = =` → 11.
    if ((_acc == null || _op == null) &&
        _lastOp != null &&
        _lastRhs != null) {
      final cur = double.tryParse(input);
      if (cur == null) {
        _setError();
        return null;
      }
      final r = _apply(cur, _lastOp!, _lastRhs!);
      if (r == null) {
        _setError();
        return null;
      }
      final left = format(cur);
      final right = format(_lastRhs!);
      final exprLine = '$left $_lastOp $right =';
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

    if (_acc == null || _op == null) return null;
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
    _lastOp = _op;
    _lastRhs = cur;
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
    _lastOp = null;
    _lastRhs = null;
    fresh = true;
    error = false;
  }

  /// Clear current entry only; keep pending operator when present.
  void clearEntry() {
    if (error) {
      clear();
      return;
    }
    input = '0';
    fresh = true;
    if (_op == null) {
      expression = '';
      _acc = null;
      _lastOp = null;
      _lastRhs = null;
    } else {
      _refreshPendingExpression();
    }
  }

  void backspace() {
    if (error) {
      clear();
      return;
    }

    // After an operator: undo the operator and restore the left operand.
    if (fresh && _op != null && _acc != null) {
      input = format(_acc!);
      _acc = null;
      _op = null;
      expression = '';
      fresh = false;
      return;
    }

    // After equals: drop the finished expression, then delete digits.
    if (fresh && expression.endsWith(' =')) {
      expression = '';
      _acc = null;
      _op = null;
      _lastOp = null;
      _lastRhs = null;
    }

    if (fresh) {
      if (input == '0' || input == '0.') return;
      fresh = false;
    }

    if (input.length <= 1 || (input.length == 2 && input.startsWith('-'))) {
      input = '0';
      fresh = true;
    } else {
      input = input.substring(0, input.length - 1);
      if (input == '-' || input.isEmpty) {
        input = '0';
        fresh = true;
      }
    }
    _refreshPendingExpression();
  }

  void negate() {
    if (error) return;
    if (input == '0' || input == '0.') return;
    if (input.startsWith('-')) {
      input = input.substring(1);
    } else {
      input = '-$input';
    }
    // Negating a fresh result starts a new editable entry.
    fresh = false;
    if (expression.endsWith(' =')) expression = '';
    _refreshPendingExpression();
  }

  /// Percent: with a pending op, use `acc * (input/100)` (e.g. `200 + 10%` → 20).
  /// Otherwise divide the current value by 100.
  void percent() {
    if (error) return;
    final cur = double.tryParse(input);
    if (cur == null) return;
    if (_acc != null && _op != null) {
      input = format(_acc! * (cur / 100));
    } else {
      input = format(cur / 100);
    }
    fresh = true;
    _refreshPendingExpression();
  }

  void memoryClear() => memory = null;

  void memoryRecall() {
    if (memory == null) return;
    if (error) clear();
    if (expression.endsWith(' =')) expression = '';
    input = format(memory!);
    fresh = false;
    _refreshPendingExpression();
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

  /// Keep expression as `acc op` only — never append the live input.
  void _refreshPendingExpression() {
    if (_op == null || _acc == null) return;
    if (expression.endsWith(' =')) return;
    expression = '${format(_acc!)} $_op';
  }

  void _setError() {
    error = true;
    expression = '';
    input = 'Error';
    _acc = null;
    _op = null;
    _lastOp = null;
    _lastRhs = null;
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
