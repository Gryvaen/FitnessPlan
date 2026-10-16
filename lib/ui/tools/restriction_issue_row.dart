import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';

/// One missing permission or failed alarm setup, with the action that fixes
/// it. Shared by the reminders status sheet and the rest-timer settings.
class RestrictionIssue {
  const RestrictionIssue({
    required this.glyph,
    required this.title,
    required this.detail,
    required this.action,
    required this.onAction,
    this.blocking = false,
  });

  final InkGlyph glyph;
  final String title;
  final String detail;
  final String action;
  final Future<void> Function() onAction;
  final bool blocking;
}

/// A [RestrictionIssue] as a [ListTile]: warning glyph on the left, title
/// in the middle, the fixing action on the right — the same row shape as the
/// alert-mode options it sits next to. The detail is folded by default; tap
/// the row to read it.
class RestrictionIssueRow extends StatefulWidget {
  const RestrictionIssueRow({
    super.key,
    required this.issue,
    required this.onAction,
    this.contentPadding,
  });

  final RestrictionIssue issue;
  final VoidCallback onAction;

  /// Null follows the ListTile theme; sheets that already pad their content
  /// pass [EdgeInsets.zero] so the glyph lines up with their heading.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<RestrictionIssueRow> createState() => _RestrictionIssueRowState();
}

class _RestrictionIssueRowState extends State<RestrictionIssueRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurfaceVariant;
    final issue = widget.issue;
    return Semantics(
      expanded: _expanded,
      hint: _expanded ? l10n.collapseSection : l10n.expandSection,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: ListTile(
          contentPadding: widget.contentPadding,
          onTap: () => setState(() => _expanded = !_expanded),
          leading: InkIcon(issue.glyph, color: AppColors.warning),
          title: Row(
            children: [
              Flexible(child: Text(issue.title)),
              const SizedBox(width: 4),
              InkIcon(
                _expanded ? InkGlyph.collapse : InkGlyph.expand,
                size: 18,
                color: muted,
              ),
            ],
          ),
          // Null when folded keeps the one-line height of the rows around it.
          subtitle: _expanded
              ? Text(
                  issue.detail,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                )
              : null,
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: TextButton(
              onPressed: widget.onAction,
              child: Text(
                issue.action,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
