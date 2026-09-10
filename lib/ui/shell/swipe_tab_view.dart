import 'package:flutter/material.dart';

/// Exposes the bottom-nav branch switch to descendants so an inner tab pager
/// can hand off a horizontal swipe once it runs out of tabs to page through.
class ShellSwipe extends InheritedWidget {
  const ShellSwipe({
    super.key,
    required this.currentBranch,
    required this.branchCount,
    required this.goToBranch,
    required super.child,
  });

  final int currentBranch;
  final int branchCount;
  final ValueChanged<int> goToBranch;

  /// Move [delta] branches from the current one, clamped to the valid range.
  /// Returns whether a switch actually happened.
  bool nudge(int delta) {
    final target = currentBranch + delta;
    if (target < 0 || target >= branchCount || target == currentBranch) {
      return false;
    }
    goToBranch(target);
    return true;
  }

  static ShellSwipe? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellSwipe>();

  @override
  bool updateShouldNotify(ShellSwipe oldWidget) =>
      currentBranch != oldWidget.currentBranch ||
      branchCount != oldWidget.branchCount;
}

/// A horizontally swipeable set of tab panels that chains into the bottom-nav
/// branches: swiping past the first / last panel switches to the previous /
/// next branch via [ShellSwipe].
///
/// [index] is the externally-owned selected tab (kept in sync with the tab
/// strip and deep links); [onIndexChanged] fires when a swipe changes it.
class SwipeTabView extends StatefulWidget {
  const SwipeTabView({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  });

  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> children;

  @override
  State<SwipeTabView> createState() => _SwipeTabViewState();
}

class _SwipeTabViewState extends State<SwipeTabView> {
  late final PageController _controller;

  /// True while we drive the controller programmatically (tab tap / external
  /// index change) so the resulting [onPageChanged] is not echoed back.
  bool _syncing = false;

  /// Accumulated horizontal overscroll for the current drag gesture.
  double _overscroll = 0;
  bool _handedOff = false;

  static const _handoffThreshold = 48.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void didUpdateWidget(covariant SwipeTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index || !_controller.hasClients) return;
    final current = _controller.page?.round() ?? _controller.initialPage;
    if (current == widget.index) return;
    _syncing = true;
    _controller
        .animateToPage(
          widget.index,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) _syncing = false;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (_syncing || page == widget.index) return;
    widget.onIndexChanged(page);
  }

  bool _onScroll(ScrollNotification n) {
    // Only the PageView's own scroll activity (depth 0, horizontal). Ignore
    // nested horizontal scrollers inside a panel, e.g. a chip row.
    if (n.depth != 0 || n.metrics.axis != Axis.horizontal) return false;
    if (n is ScrollStartNotification) {
      _overscroll = 0;
      _handedOff = false;
    } else if (n is OverscrollNotification && n.dragDetails != null) {
      _overscroll += n.overscroll;
      if (!_handedOff && _overscroll.abs() >= _handoffThreshold) {
        final shell = ShellSwipe.maybeOf(context);
        if (shell != null && shell.nudge(_overscroll > 0 ? 1 : -1)) {
          _handedOff = true;
        }
      }
    } else if (n is ScrollEndNotification) {
      _overscroll = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView.builder(
        controller: _controller,
        // Page snapping, but a hard (non-bouncing) edge so a drag past the
        // first / last panel reports overscroll we can hand to the shell.
        physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
        onPageChanged: _onPageChanged,
        itemCount: widget.children.length,
        itemBuilder: (_, i) => widget.children[i],
      ),
    );
  }
}
