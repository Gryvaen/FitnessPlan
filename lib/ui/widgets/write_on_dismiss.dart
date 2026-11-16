import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';

/// Runs a swipe's write before the row would be dismissed and returns false:
/// the row then leaves through the data stream instead of as a dismissed
/// Dismissible still in the list, and a failure (e.g. the page was left open
/// past midnight, so the day is no longer editable) is reported, not lost.
Future<bool> writeOnDismiss(
  BuildContext context,
  Future<void> Function() write,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    await write();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$e'))));
  }
  return false;
}
