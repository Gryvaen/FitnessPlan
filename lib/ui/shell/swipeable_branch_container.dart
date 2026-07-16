import 'package:flutter/material.dart';

/// Hosts StatefulShellRoute branch navigators in a [PageView] so tabs can be
/// switched by horizontal swipe, while staying in sync with bottom-nav taps.
class SwipeableBranchContainer extends StatefulWidget {
  const SwipeableBranchContainer({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.children,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> children;

  @override
  State<SwipeableBranchContainer> createState() =>
      _SwipeableBranchContainerState();
}

class _SwipeableBranchContainerState extends State<SwipeableBranchContainer> {
  late final PageController _controller;
  bool _animatingFromNav = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant SwipeableBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;
    if (!_controller.hasClients) return;
    final page = _controller.page?.round() ?? _controller.initialPage;
    if (page == widget.currentIndex) return;
    _animatingFromNav = true;
    _controller
        .animateToPage(
          widget.currentIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
      if (mounted) _animatingFromNav = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_animatingFromNav) return;
    if (index == widget.currentIndex) return;
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const ClampingScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: widget.children,
    );
  }
}
