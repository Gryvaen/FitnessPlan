import 'package:flutter/material.dart';
import '../theme/sport_chrome.dart';

/// Open section heading. Add and overflow remain independent actions.
class TodaySectionHeader extends StatelessWidget {
  const TodaySectionHeader({
    super.key,
    required this.title,
    this.summary,
    this.addLabel,
    this.onAdd,
    this.trailing = const [],
  });
  final String title;
  final String? summary;
  final String? addLabel;
  final VoidCallback? onAdd;
  final List<Widget> trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (summary != null && summary!.isNotEmpty)
                Text(summary!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      if (addLabel != null)
        PlainIconAction(icon: Icons.add, label: addLabel!, onPressed: onAdd),
      ...trailing,
    ],
  );
}
