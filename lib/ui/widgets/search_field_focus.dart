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
