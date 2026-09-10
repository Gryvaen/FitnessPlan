import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'swipe_tab_view.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(stepsSyncProvider);
    }
  }

  /// `1` forward, `-1` back, `0` after a tap or once settled. Tells the branch
  /// we're moving to which edge tab to continue from.
  int _enterEdge = 0;

  void _onTap(int index) {
    if (_enterEdge != 0) setState(() => _enterEdge = 0);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool _nudge(int delta) {
    final target = widget.navigationShell.currentIndex + delta;
    if (target < 0 || target >= 4) return false;
    setState(() => _enterEdge = delta > 0 ? 1 : -1);
    widget.navigationShell.goBranch(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _enterEdge != 0) setState(() => _enterEdge = 0);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(stepsSyncProvider);
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final selected = widget.navigationShell.currentIndex;

    final items = <({IconData icon, IconData selectedIcon, String label})>[
      (
        icon: Icons.today_outlined,
        selectedIcon: Icons.today,
        label: l10n.today,
      ),
      (
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        label: l10n.foods,
      ),
      (
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        label: l10n.records,
      ),
      (icon: Icons.person_outline, selectedIcon: Icons.person, label: l10n.me),
    ];

    return ShellSwipe(
      currentBranch: selected,
      branchCount: items.length,
      enterEdge: _enterEdge,
      onNudge: _nudge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Theme.of(context).colorScheme.surface),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.navigationShell,
            bottomNavigationBar: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8 + bottomInset),
              child: SportPillShell(
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _PillNavItem(
                            selected: selected == i,
                            icon: items[i].icon,
                            selectedIcon: items[i].selectedIcon,
                            tooltip: items[i].label,
                            onTap: () => _onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppThemeVisuals.of(context).accent;
    const pillRadius = BorderRadius.all(Radius.circular(18));

    return Tooltip(
      message: tooltip,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: pillRadius,
            customBorder: const RoundedRectangleBorder(
              borderRadius: pillRadius,
            ),
            child: SizedBox(
              width: 56,
              height: 36,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey(selected),
                    size: 24,
                    color: selected ? accent : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
