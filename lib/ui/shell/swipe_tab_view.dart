import 'package:flutter/material.dart';

/// Exposes the bottom-nav branch switch to descendants so an inner tab pager
/// can hand off a horizontal swipe once it runs out of tabs to page through.
class ShellSwipe extends InheritedWidget {
  const ShellSwipe({
    super.key,
    required this.currentBranch,
    required this.branchCount,
    required this.enterEdge,
    required this.onNudge,
    required super.child,
  });

  final int currentBranch;
  final int branchCount;

  /// How the current branch was last entered: `1` = by swiping forward (land on
  /// its first tab), `-1` = by swiping back (land on its last tab), `0` = a tap
  /// or a settled state (keep whatever tab it was on).
  final int enterEdge;

  /// Move [delta] branches (±1) from the current one. Returns whether a switch
  /// actually happened (false at the ends).
  final bool Function(int delta) onNudge;

  bool nudge(int delta) => onNudge(delta);

  static ShellSwipe? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellSwipe>();

  @override
  bool updateShouldNotify(ShellSwipe oldWidget) =>
      currentBranch != oldWidget.currentBranch ||
      branchCount != oldWidget.branchCount ||
      enterEdge != oldWidget.enterEdge;
}

/// The swipeable panel host for one bottom-nav branch.
///
/// Branches with sub-tabs (Records, Foods) pass every tab as a child; branches
/// without (Today, Me) pass a single child. Either way a horizontal drag is
/// owned here — never by an ancestor PageView — so one continuous left/right
/// motion always steps through the inner tabs first and only then, past the
/// first / last tab, hands off to the previous / next branch. Fast or slow, a
/// drag never skips a step.
class SwipeTabView extends StatefulWidget {
  const SwipeTabView({
    super.key,
    required this.branchIndex,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  });

  /// This branch's bottom-nav index, matched against [ShellSwipe.currentBranch]
  /// so only the freshly-entered branch reacts to [ShellSwipe.enterEdge].
  final int branchIndex;
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

  static const _handoffThreshold = 44.0;

  /// Always accept the drag (so a single-child pager still reports overscroll)
  /// and clamp hard at the edges (no bounce) so that overscroll is ours to read.
  static const _physics = PageScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
  );

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
    // Only this pager's own scroll activity (depth 0, horizontal). Ignore
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
    // Just landed on this branch by swiping — continue from its entry edge.
    final shell = ShellSwipe.maybeOf(context);
    if (shell != null &&
        shell.enterEdge != 0 &&
        shell.currentBranch == widget.branchIndex &&
        widget.children.length > 1) {
      final target = shell.enterEdge > 0 ? 0 : widget.children.length - 1;
      if (widget.index != target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.index != target) widget.onIndexChanged(target);
        });
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView.builder(
        controller: _controller,
        physics: _physics,
        onPageChanged: _onPageChanged,
        itemCount: widget.children.length,
        itemBuilder: (_, i) => widget.children[i],
      ),
    );
  }
}
