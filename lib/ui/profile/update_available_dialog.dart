import 'package:flutter/material.dart';

import '../../data/repositories/app_update_repository.dart';
import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../strategy/strategy_fold_section.dart';
import '../theme/app_theme.dart';

/// Shows the "new version" dialog: rendered release notes plus a folded
/// download-source picker. Returns the chosen source, or null for 稍后.
Future<UpdateSource?> showUpdateAvailableDialog(
  BuildContext context, {
  required LatestRelease release,
  required ReleaseAsset asset,
  required String localVersion,
  required UpdateSource initialSource,
}) {
  return showDialog<UpdateSource>(
    context: context,
    builder: (_) => UpdateAvailableDialog(
      release: release,
      asset: asset,
      localVersion: localVersion,
      initialSource: initialSource,
    ),
  );
}

class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.release,
    required this.asset,
    required this.localVersion,
    required this.initialSource,
  });

  final LatestRelease release;
  final ReleaseAsset asset;
  final String localVersion;
  final UpdateSource initialSource;

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  late UpdateSource _source = widget.initialSource;
  bool _sourceExpanded = false;

  String _sourceName(UpdateSource source) => switch (source) {
    UpdateSource.auto => context.l10n.updateSourceAuto,
    UpdateSource.gitee => 'Gitee',
    UpdateSource.github => 'GitHub',
  };

  String _sourceHint(UpdateSource source) => switch (source) {
    UpdateSource.auto => context.l10n.updateSourceAutoHint,
    UpdateSource.gitee => context.l10n.updateSourceGiteeHint,
    UpdateSource.github => context.l10n.updateSourceGithubHint,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurfaceVariant;
    final release = widget.release;
    final sizeMb = (widget.asset.size / (1024 * 1024)).toStringAsFixed(1);
    final maxNotesHeight = MediaQuery.sizeOf(context).height * 0.45;

    return AlertDialog(
      title: Text(l10n.newVersionTitle(release.version)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.updateVersionMeta(widget.localVersion, '$sizeMb MB'),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.field),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxNotesHeight),
                child: SingleChildScrollView(
                  child: release.body.isEmpty
                      ? Text(l10n.newVersionAsk(release.version))
                      : ReleaseNotesView(markdown: release.body),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            StrategyFoldSection(
              title: l10n.updateSourceLabel,
              summary: _sourceName(_source),
              expanded: _sourceExpanded,
              onTap: () => setState(() => _sourceExpanded = !_sourceExpanded),
              child: Column(
                children: [
                  for (final source in UpdateSource.values)
                    _SourceOption(
                      name: _sourceName(source),
                      hint: _sourceHint(source),
                      selected: source == _source,
                      onTap: () => setState(() {
                        _source = source;
                        _sourceExpanded = false;
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.later),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _source),
          child: Text(l10n.downloadInstall),
        ),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.name,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppThemeVisuals.of(context).accent;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? accent : null,
                      ),
                    ),
                    Text(
                      hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) InkIcon(InkGlyph.check, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the small Markdown subset used in release notes: `#` headings,
/// `-`/`*` bullets, `**bold**` and `` `code` `` (shown without backticks).
class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({super.key, required this.markdown});

  final String markdown;

  static final _heading = RegExp(r'^#{1,6}\s+');
  static final _bullet = RegExp(r'^[-*+]\s+');
  static final _inline = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final children = <Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: AppSpacing.compact));
        }
      } else if (_heading.hasMatch(line)) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: AppSpacing.compact));
        }
        children.add(
          Text.rich(
            _spans(line.replaceFirst(_heading, ''), theme.textTheme.titleSmall),
          ),
        );
        children.add(const SizedBox(height: 4));
      } else if (_bullet.hasMatch(line)) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: body),
                Expanded(
                  child: Text.rich(
                    _spans(line.replaceFirst(_bullet, ''), body),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(_spans(line, body)),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  TextSpan _spans(String text, TextStyle? style) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      spans.add(
        m.group(1) != null
            ? TextSpan(
                text: m.group(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : TextSpan(text: m.group(2)),
      );
      start = m.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(style: style, children: spans);
  }
}
