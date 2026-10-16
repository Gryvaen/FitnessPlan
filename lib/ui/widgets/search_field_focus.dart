import 'package:flutter/widgets.dart';

/// Blocks a search [FocusNode] from reclaiming focus while [action] runs
/// (and for a couple of frames after). Flutter restores the previous focus
/// when a pushed route / sheet is dismissed, which would otherwise pop the
/// IME even though the user never tapped the field.
Future<T> withoutSearchFocus<T>({
  required FocusNode focus,
  required Future<T> Function() action,
}) async {
  focus.unfocus();
  focus.canRequestFocus = false;
  try {
    return await action();
  } finally {
    focus.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    focus.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    focus.unfocus();
    focus.canRequestFocus = true;
  }
}

/// Stops a [TextField] on a newly opened page/dialog from auto-claiming
/// focus (and raising the IME) before the user taps it.
void suppressInitialTextFocus(FocusNode focus) {
  focus.canRequestFocus = false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    focus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      focus.canRequestFocus = true;
    });
  });
}

/// Alias kept for existing search-field call sites.
void suppressInitialSearchFocus(FocusNode focus) =>
    suppressInitialTextFocus(focus);

/// Drops any current text focus / IME before navigating away.
void unfocusForNavigation() {
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Drops [focusNode] when the soft keyboard is dismissed (back key / IME
/// hide button) so the field doesn't keep a blinking caret and re-raise the
/// IME on the next focus restore.
class UnfocusOnKeyboardHide extends StatefulWidget {
  const UnfocusOnKeyboardHide({
    super.key,
    required this.focusNode,
    required this.child,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  State<UnfocusOnKeyboardHide> createState() => _UnfocusOnKeyboardHideState();
}

class _UnfocusOnKeyboardHideState extends State<UnfocusOnKeyboardHide>
    with WidgetsBindingObserver {
  double _lastInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Read the raw view: Scaffold strips the bottom inset from its body's
    // MediaQuery when it resizes for the keyboard.
    final inset = View.of(context).viewInsets.bottom;
    if (_lastInset > 0 && inset == 0 && widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
    }
    _lastInset = inset;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
