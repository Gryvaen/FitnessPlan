import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSteps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSteps();
    }
  }

  void _syncSteps() {
    ref.invalidate(stepsSyncProvider);
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(stepsSyncProvider);
    final l10n = context.l10n;
    final visuals = AppThemeVisuals.of(context);
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
      (
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.me,
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).colorScheme.surface),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: visuals.scaffoldWash),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: widget.navigationShell,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8 + bottomInset),
            child: SportPillShell(
              child: SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    // Shared indicator sliding between the equally divided slots.
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                        items.length == 1
                            ? 0
                            : -1 + selected * 2 / (items.length - 1),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / items.length,
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: visuals.accent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    final visuals = AppThemeVisuals.of(context);
    const pillRadius = BorderRadius.all(Radius.circular(18));

    return Tooltip(
      message: tooltip,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: pillRadius,
            customBorder: const RoundedRectangleBorder(borderRadius: pillRadius),
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
                    color: selected
                        ? visuals.heroOnGradient
                        : scheme.onSurfaceVariant,
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
