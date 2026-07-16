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

  static const _opOrange = Color(0xFFFF9F0A);
  static const _numDark = Color(0xFF3D3D3D);
  static const _fnLight = Color(0xFFD4D4D4);

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
        : (expr.endsWith('=')
            ? '$expr $display'
            : '$expr\n$display');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedClipboard)),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final eng = _engine;
    final displayInput = eng.error ? l10n.calcError : eng.input;

    return Scaffold(
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
            AppSpacing.field,
            AppSpacing.formPage,
            AppSpacing.formPage,
          ),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Stack(
                    children: [
                      if (eng.hasMemory)
                        Positioned(
                          top: 12,
                          left: 16,
                          child: Text(
                            'M',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.card),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            if (eng.expression.isNotEmpty)
                              Text(
                                eng.expression,
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                displayInput,
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w300,
                                  height: 1.05,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _row([
                _KeySpec('MC', kind: _KeyKind.mem, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryClear);
                }),
                _KeySpec('MR', kind: _KeyKind.mem, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryRecall);
                }),
                _KeySpec('M+', kind: _KeyKind.mem, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memoryAdd);
                }),
                _KeySpec('M−', kind: _KeyKind.mem, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.memorySub);
                }),
                _KeySpec('⌫', kind: _KeyKind.fn, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.backspace);
                }),
              ]),
              _row([
                _KeySpec('AC', kind: _KeyKind.fn, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.clear);
                }),
                _KeySpec('+/−', kind: _KeyKind.fn, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.negate);
                }),
                _KeySpec('%', kind: _KeyKind.fn, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.percent);
                }),
                _KeySpec('÷', kind: _KeyKind.op, onTap: () {
                  HapticFeedback.lightImpact();
                  _bump(() => _engine.op('÷'));
                }),
              ]),
              _row([
                _KeySpec('7', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('7'));
                }),
                _KeySpec('8', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('8'));
                }),
                _KeySpec('9', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('9'));
                }),
                _KeySpec('×', kind: _KeyKind.op, onTap: () {
                  HapticFeedback.lightImpact();
                  _bump(() => _engine.op('×'));
                }),
              ]),
              _row([
                _KeySpec('4', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('4'));
                }),
                _KeySpec('5', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('5'));
                }),
                _KeySpec('6', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('6'));
                }),
                _KeySpec('−', kind: _KeyKind.op, onTap: () {
                  HapticFeedback.lightImpact();
                  _bump(() => _engine.op('−'));
                }),
              ]),
              _row([
                _KeySpec('1', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('1'));
                }),
                _KeySpec('2', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('2'));
                }),
                _KeySpec('3', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('3'));
                }),
                _KeySpec('+', kind: _KeyKind.op, onTap: () {
                  HapticFeedback.lightImpact();
                  _bump(() => _engine.op('+'));
                }),
              ]),
              _row([
                _KeySpec('0', wide: true, onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(() => _engine.digit('0'));
                }),
                _KeySpec('.', onTap: () {
                  HapticFeedback.selectionClick();
                  _bump(_engine.dot);
                }),
                _KeySpec('=', kind: _KeyKind.op, onTap: _onEquals),
              ]),
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
              flex: keys[i].wide ? 2 : 1,
              child: _CalcButton(
                label: keys[i].label,
                kind: keys[i].kind,
                selected: keys[i].kind == _KeyKind.op &&
                    _engine.pendingOp == keys[i].label &&
                    _engine.fresh &&
                    !_engine.error,
                wide: keys[i].wide,
                onTap: keys[i].onTap,
              ),
            ),
          ],
        ],
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
              ? Center(
                  child: Text(l10n.noHistory, style: theme.textTheme.meta),
                )
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

enum _KeyKind { num, fn, op, mem }

class _KeySpec {
  const _KeySpec(
    this.label, {
    required this.onTap,
    this.kind = _KeyKind.num,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final _KeyKind kind;
  final bool wide;
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.kind,
    required this.onTap,
    this.selected = false,
    this.wide = false,
  });

  final String label;
  final _KeyKind kind;
  final VoidCallback onTap;
  final bool selected;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (kind) {
      case _KeyKind.fn:
        bg = _CalculatorPageState._fnLight;
        fg = const Color(0xFF1C1C1C);
      case _KeyKind.mem:
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
        fg = Theme.of(context).colorScheme.onSurface;
      case _KeyKind.op:
        bg = selected ? Colors.white : _CalculatorPageState._opOrange;
        fg = selected ? _CalculatorPageState._opOrange : Colors.white;
      case _KeyKind.num:
        bg = _CalculatorPageState._numDark;
        fg = Colors.white;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: kind == _KeyKind.op && selected
          ? const BorderSide(color: _CalculatorPageState._opOrange, width: 1.5)
          : BorderSide.none,
    );

    final fontSize = switch (kind) {
      _KeyKind.mem => 15.0,
      _KeyKind.fn || _KeyKind.op => 26.0,
      _KeyKind.num => 30.0,
    };

    return AspectRatio(
      aspectRatio: wide ? 2.15 : 1,
      child: Material(
        color: bg,
        elevation: 0,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Align(
            alignment: wide ? Alignment.centerLeft : Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(left: wide ? 24 : 0),
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
