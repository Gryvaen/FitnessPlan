import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final selected = navigationShell.currentIndex;

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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 8 + bottomInset),
        child: Material(
          elevation: 2,
          color: scheme.surfaceContainerLowest,
          shadowColor: scheme.shadow.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
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
                          color: scheme.primaryContainer,
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
                    color:
                        selected ? scheme.onSurface : scheme.onSurfaceVariant,
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
