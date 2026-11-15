import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A search box that rests as its search icon and slides open to the right.
///
/// The box is always laid out at full width and only revealed by an
/// animated, clipped width, so its text never reflows mid-animation; the
/// box's own leading search icon is what shows while collapsed. Expanding
/// does not focus the box — the keyboard comes up only when the user taps
/// the text area — so callers decide focus.
class ExpandingSearch extends StatelessWidget {
  const ExpandingSearch({
    super.key,
    required this.expanded,
    required this.openKey,
    required this.tooltip,
    required this.onExpand,
    required this.child,
  });

  static const collapsedWidth = 48.0;

  final bool expanded;
  final Key openKey;
  final String tooltip;
  final VoidCallback onExpand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: still ? Duration.zero : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: expanded ? full : collapsedWidth,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Stack(
              children: [
                UnconstrainedBox(
                  alignment: Alignment.centerLeft,
                  constrainedAxis: Axis.vertical,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: full,
                    child: IgnorePointer(
                      ignoring: !expanded,
                      child: ExcludeFocus(excluding: !expanded, child: child),
                    ),
                  ),
                ),
                if (!expanded)
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        key: openKey,
                        onTap: onExpand,
                        child: Tooltip(
                          message: tooltip,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
