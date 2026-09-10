import 'package:flutter/material.dart';

/// Exposes the bottom-nav branch switch to descendants so the outermost tab
/// pager can hand a swipe off once it runs out of tabs to page through.
class ShellSwipe extends InheritedWidget {
  const ShellSwipe({
    super.key,
    required this.currentBranch,
    required this.branchCount,
    required this.onNudge,
    required super.child,
  });

  final int currentBranch;
  final int branchCount;

  /// Move [delta] branches (±1). Returns whether a switch actually happened.
  final bool Function(int delta) onNudge;

  bool nudge(int delta) => onNudge(delta);

  static ShellSwipe? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellSwipe>();

  @override
  bool updateShouldNotify(ShellSwipe oldWidget) =>
      currentBranch != oldWidget.currentBranch ||
      branchCount != oldWidget.branchCount;
}

/// Published by every [SwipeTabView] so a nested one can hand a swipe off to its
/// enclosing pager once it hits its own first / last tab.
class _TabHandoff extends InheritedWidget {
  const _TabHandoff({required this.step, required super.child});

  /// Ask the enclosing pager to move by [delta]; it pages itself, or forwards
  /// the hand-off further out. Returns whether anything moved.
  final bool Function(int delta) step;

  static _TabHandoff? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_TabHandoff>();

  @override
  bool updateShouldNotify(_TabHandoff oldWidget) => false;
}

/// A swipeable set of tab panels that chains outward: a horizontal drag pages
/// through the panels here first, and only once dragged past the first / last
/// panel does it hand off — to an enclosing [SwipeTabView] if there is one,
/// otherwise to the bottom-nav branches via [ShellSwipe]. Fast or slow, a drag
/// moves exactly one step and never skips a level. Each pager keeps whatever
/// tab it was last on; a hand-off never resets it.
///
/// Pass [branchIndex] for the pager that fills a bottom-nav branch so it can
/// hand off to [ShellSwipe]; nested pagers hand off to their parent instead.
class SwipeTabView extends StatefulWidget {
  const SwipeTabView({
    super.key,
    this.branchIndex,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  });

  final int? branchIndex;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> children;

  @override
  State<SwipeTabView> createState() => _SwipeTabViewState();
}

class _SwipeTabViewState extends State<SwipeTabView> {
  late final PageController _controller;

  /// True while the controller is driven programmatically so the resulting
  /// [onPageChanged] is not echoed back out.
  bool _syncing = false;

  /// The page actually shown, tracked so [_stepSelf] works off the settled
  /// position even mid-animation.
  late int _settledPage;

  double _overscroll = 0;
  bool _handedOff = false;

  static const _handoffThreshold = 44.0;
  static const _physics = PageScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
  );

  @override
  void initState() {
    super.initState();
    _settledPage = widget.index;
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void didUpdateWidget(covariant SwipeTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_syncing ||
        widget.index == oldWidget.index ||
        !_controller.hasClients ||
        _settledPage == widget.index) {
      return;
    }
    _syncing = true;
    _controller
        .animateToPage(
          widget.index,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) setState(() => _syncing = false);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _settledPage = page);
    if (_syncing || page == widget.index) return;
    widget.onIndexChanged(page);
  }

  /// Try to page this view by [delta]; forward the hand-off out if we can't.
  bool _stepSelf(int delta) {
    final target = _settledPage + delta;
    if (target < 0 || target >= widget.children.length) {
      return _handoffUp(delta);
    }
    _syncing = true;
    _controller
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (!mounted) return;
          widget.onIndexChanged(target);
          setState(() => _syncing = false);
        });
    return true;
  }

  bool _handoffUp(int delta) {
    final parent = _TabHandoff.read(context);
    if (parent != null) return parent.step(delta);
    if (widget.branchIndex != null) {
      return ShellSwipe.read(context)?.nudge(delta) ?? false;
    }
    return false;
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
        if (_handoffUp(_overscroll > 0 ? 1 : -1)) _handedOff = true;
      }
    } else if (n is ScrollEndNotification) {
      _overscroll = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _TabHandoff(
      step: _stepSelf,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: PageView.builder(
          controller: _controller,
          physics: _physics,
          onPageChanged: _onPageChanged,
          itemCount: widget.children.length,
          itemBuilder: (_, i) => widget.children[i],
        ),
      ),
    );
  }
}
