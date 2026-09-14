import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/calculator_engine.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

/// App-themed calculator with expression line, memory, and history.
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  final _engine = CalculatorEngine();
  List<CalcHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _history = ref.read(calculatorHistoryRepositoryProvider).load();
  }

  void _bump(VoidCallback fn) => setState(fn);

  Future<void> _onEquals() async {
    HapticFeedback.mediumImpact();
    CalcHistoryEntry? entry;
    _bump(() => entry = _engine.equals());
    final e = entry;
    if (e == null) return;
    final next = await ref.read(calculatorHistoryRepositoryProvider).add(e);
    if (!mounted) return;
    setState(() => _history = next);
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    final expr = _engine.expression.trim();
    final display = _engine.error ? l10n.calcError : _engine.input;
    final text = expr.isEmpty
        ? display
        : (expr.endsWith('=') ? '$expr $display' : '$expr\n$display');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.copiedClipboard)));
  }

  Future<void> _openHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return _HistorySheet(
              entries: _history,
              scrollController: scrollController,
              onPick: (e) {
                Navigator.pop(ctx);
                _bump(() => _engine.loadResult(e.result));
              },
              onClear: () async {
                await ref.read(calculatorHistoryRepositoryProvider).clear();
                if (!mounted) return;
                setState(() => _history = []);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  void _tapDigit(String d) {
    HapticFeedback.selectionClick();
    _bump(() => _engine.digit(d));
  }

  void _tapOp(String o) {
    HapticFeedback.lightImpact();
    _bump(() => _engine.op(o));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final eng = _engine;
    final displayInput = eng.error ? l10n.calcError : eng.input;
    final clearLabel = eng.showsAllClear ? 'AC' : 'C';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.toolCalculator),
        actions: [
          IconButton(
            tooltip: l10n.history,
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: l10n.copy,
            onPressed: _copy,
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.formPage,
            AppSpacing.compact,
            AppSpacing.formPage,
            AppSpacing.formPage,
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _DisplayPanel(
                  expression: eng.expression,
                  value: displayInput,
                  hasMemory: eng.hasMemory,
                ),
              ),
              const SizedBox(height: AppSpacing.field),
              // Memory strip — compact, not square keys.
              _MemoryRow(
                onMc: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryClear);
                },
                onMr: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryRecall);
                },
                onMPlus: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryAdd);
                },
                onMMinus: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memorySub);
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Expanded(
                      child: _row([
                        _KeySpec(
                          clearLabel,
                          kind: _KeyKind.fn,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _bump(
                              eng.showsAllClear
                                  ? _engine.clear
                                  : _engine.clearEntry,
                            );
                          },
                        ),
                        _KeySpec(
                          '⌫',
                          kind: _KeyKind.fn,
                          icon: Icons.backspace_outlined,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _bump(_engine.backspace);
                          },
                        ),
                        _KeySpec(
                          '%',
                          kind: _KeyKind.fn,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _bump(_engine.percent);
                          },
                        ),
                        _KeySpec(
                          '÷',
                          kind: _KeyKind.op,
                          onTap: () => _tapOp('÷'),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: _row([
                        _KeySpec('7', onTap: () => _tapDigit('7')),
                        _KeySpec('8', onTap: () => _tapDigit('8')),
                        _KeySpec('9', onTap: () => _tapDigit('9')),
                        _KeySpec(
                          '×',
                          kind: _KeyKind.op,
                          onTap: () => _tapOp('×'),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: _row([
                        _KeySpec('4', onTap: () => _tapDigit('4')),
                        _KeySpec('5', onTap: () => _tapDigit('5')),
                        _KeySpec('6', onTap: () => _tapDigit('6')),
                        _KeySpec(
                          '−',
                          kind: _KeyKind.op,
                          onTap: () => _tapOp('−'),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: _row([
                        _KeySpec('1', onTap: () => _tapDigit('1')),
                        _KeySpec('2', onTap: () => _tapDigit('2')),
                        _KeySpec('3', onTap: () => _tapDigit('3')),
                        _KeySpec(
                          '+',
                          kind: _KeyKind.op,
                          onTap: () => _tapOp('+'),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: _row([
                        _KeySpec(
                          '+/−',
                          kind: _KeyKind.fn,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _bump(_engine.negate);
                          },
                        ),
                        _KeySpec('0', onTap: () => _tapDigit('0')),
                        _KeySpec(
                          '.',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _bump(_engine.dot);
                          },
                        ),
                        _KeySpec(
                          '=',
                          kind: _KeyKind.equals,
                          onTap: _onEquals,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<_KeySpec> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CalcButton(
                label: keys[i].label,
                icon: keys[i].icon,
                kind: keys[i].kind,
                selected:
                    keys[i].kind == _KeyKind.op &&
                    _engine.pendingOp == keys[i].label &&
                    _engine.fresh &&
                    !_engine.error,
                onTap: keys[i].onTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({
    required this.onMc,
    required this.onMr,
    required this.onMPlus,
    required this.onMMinus,
  });

  final VoidCallback onMc;
  final VoidCallback onMr;
  final VoidCallback onMPlus;
  final VoidCallback onMMinus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('MC', onMc),
        const SizedBox(width: 8),
        chip('MR', onMr),
        const SizedBox(width: 8),
        chip('M+', onMPlus),
        const SizedBox(width: 8),
        chip('M−', onMMinus),
      ],
    );
  }
}

class _DisplayPanel extends StatelessWidget {
  const _DisplayPanel({
    required this.expression,
    required this.value,
    required this.hasMemory,
  });

  final String expression;
  final String value;
  final bool hasMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasMemory ? 'M' : ' ',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: hasMemory ? scheme.primary : Colors.transparent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            if (expression.isNotEmpty)
              Text(
                expression,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w300,
                  height: 1.05,
                  letterSpacing: -1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({
    required this.entries,
    required this.scrollController,
    required this.onPick,
    required this.onClear,
  });

  final List<CalcHistoryEntry> entries;
  final ScrollController scrollController;
  final ValueChanged<CalcHistoryEntry> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final timeFmt = DateFormat('MM-dd HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
          child: Row(
            children: [
              Text(l10n.calcHistory, style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: entries.isEmpty ? null : onClear,
                child: Text(l10n.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text(l10n.noHistory, style: theme.textTheme.meta))
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(
                        e.expression,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(
                        e.result,
                        style: theme.textTheme.titleLarge,
                      ),
                      trailing: Text(
                        timeFmt.format(e.at.toLocal()),
                        style: theme.textTheme.meta,
                      ),
                      onTap: () => onPick(e),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

enum _KeyKind { num, fn, op, equals }

class _KeySpec {
  const _KeySpec(
    this.label, {
    required this.onTap,
    this.kind = _KeyKind.num,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final _KeyKind kind;
  final IconData? icon;
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.kind,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final _KeyKind kind;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = AppThemeVisuals.of(context);
    late final Color bg;
    late final Color fg;
    switch (kind) {
      case _KeyKind.fn:
        bg = scheme.surfaceContainerHigh;
        fg = label == 'AC' || label == 'C'
            ? AppColors.warning
            : scheme.onSurface;
      case _KeyKind.op:
        bg = selected ? scheme.surface : visuals.accent;
        fg = selected ? visuals.accent : visuals.onAccent;
      case _KeyKind.equals:
        bg = visuals.accent;
        fg = visuals.onAccent;
      case _KeyKind.num:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurface;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: kind == _KeyKind.op && selected
          ? BorderSide(color: visuals.accent, width: 1.5)
          : BorderSide.none,
    );

    final fontSize = switch (kind) {
      _KeyKind.fn => 22.0,
      _KeyKind.op || _KeyKind.equals => 28.0,
      _KeyKind.num => 28.0,
    };

    return Material(
      color: bg,
      elevation: 0,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Center(
          child: icon != null
              ? Icon(icon, color: fg, size: 26)
              : Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ),
    );
  }
}
