import 'package:flutter/material.dart';

/// Exposes the bottom-nav branch switch to descendants so the outermost tab
/// pager can hand a swipe off once it runs out of tabs to page through.
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
  /// or a settled state.
  final int enterEdge;

  /// Move [delta] branches (±1). Returns whether a switch actually happened.
  final bool Function(int delta) onNudge;

  bool nudge(int delta) => onNudge(delta);

  static ShellSwipe? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellSwipe>();

  static ShellSwipe? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellSwipe>();

  @override
  bool updateShouldNotify(ShellSwipe oldWidget) =>
      currentBranch != oldWidget.currentBranch ||
      branchCount != oldWidget.branchCount ||
      enterEdge != oldWidget.enterEdge;
}

/// Published by every [SwipeTabView] to its subtree so a nested [SwipeTabView]
/// can hand a swipe off to its parent pager once it hits its own first / last
/// tab, and so the parent can tell a freshly-entered child which edge to
/// continue from.
class _TabHandoff extends InheritedWidget {
  const _TabHandoff({
    required this.step,
    required this.activePage,
    required this.childEnterEdge,
    required this.consumeChildEdge,
    required super.child,
  });

  /// Ask the parent pager to move by [delta]; it pages itself, or forwards the
  /// hand-off further up. Returns whether anything moved.
  final bool Function(int delta) step;

  /// The parent pager's settled page — a child checks this against its own slot
  /// so only the freshly-entered child reacts to [childEnterEdge].
  final int activePage;
  final int childEnterEdge;
  final VoidCallback consumeChildEdge;

  static _TabHandoff? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TabHandoff>();

  static _TabHandoff? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_TabHandoff>();

  @override
  bool updateShouldNotify(_TabHandoff oldWidget) =>
      activePage != oldWidget.activePage ||
      childEnterEdge != oldWidget.childEnterEdge;
}

/// A swipeable set of tab panels that chains outward: a horizontal drag pages
/// through the panels here first, and only once dragged past the first / last
/// panel does it hand off — to an enclosing [SwipeTabView] if there is one,
/// otherwise to the bottom-nav branches via [ShellSwipe]. Fast or slow, a drag
/// moves exactly one step and never skips a level.
///
/// Pass [branchIndex] for the pager that fills a bottom-nav branch, or
/// [tabIndex] for one nested inside another pager (its slot in the parent).
class SwipeTabView extends StatefulWidget {
  const SwipeTabView({
    super.key,
    this.branchIndex,
    this.tabIndex,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  });

  final int? branchIndex;
  final int? tabIndex;
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

  /// Set when this pager was just entered by a hand-off, so the now-active child
  /// panel knows to reset to its own first tab too.
  int _childEdge = 0;

  double _overscroll = 0;
  bool _handedOff = false;

  /// The page that is actually shown, tracked so [_TabHandoff.activePage] stays
  /// correct after a programmatic page animation settles.
  late int _settledPage;

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
        !_controller.hasClients) {
      return;
    }
    if (_settledPage == widget.index) return;
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

  /// Try to page this view by [delta]; forward the hand-off up if we can't.
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
          setState(() {
            _syncing = false;
            _childEdge = 1;
          });
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

  /// The edge this view was just entered from, or 0.
  int _incomingEdge() {
    final parent = _TabHandoff.of(context);
    if (parent != null) {
      return (widget.tabIndex != null && parent.activePage == widget.tabIndex)
          ? parent.childEnterEdge
          : 0;
    }
    final shell = ShellSwipe.of(context);
    if (shell != null &&
        widget.branchIndex != null &&
        shell.currentBranch == widget.branchIndex) {
      return shell.enterEdge;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _incomingEdge();
    if (incoming != 0 && widget.children.length > 1) {
      // Entering a tab group always lands on its first tab; forward paging
      // still walks through every tab one step at a time.
      const target = 0;
      if (widget.index != target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.index != target) widget.onIndexChanged(target);
        });
      }
      if (_childEdge == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _childEdge = 1);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _TabHandoff.read(context)?.consumeChildEdge();
      });
    }

    return _TabHandoff(
      step: _stepSelf,
      activePage: _settledPage,
      childEnterEdge: _childEdge,
      consumeChildEdge: () {
        if (mounted && _childEdge != 0) setState(() => _childEdge = 0);
      },
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
