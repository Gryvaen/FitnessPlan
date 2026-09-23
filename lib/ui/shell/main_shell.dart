import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
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
    _checkForUpdateSilently();
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
      _checkForUpdateSilently();
    }
  }

  /// Throttled background check so the update icon's red dot can show up
  /// without the user having to remember to tap "check for update"
  /// themselves — see [AppUpdateNotifier.silentCheckForUpdate].
  Future<void> _checkForUpdateSilently() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    ref
        .read(appUpdateProvider.notifier)
        .silentCheckForUpdate(info.version, info.buildNumber);
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool _nudge(int delta) {
    final target = widget.navigationShell.currentIndex + delta;
    if (target < 0 || target >= 4) return false;
    widget.navigationShell.goBranch(target);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(stepsSyncProvider);
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final selected = widget.navigationShell.currentIndex;

    final items = <({InkGlyph glyph, String label})>[
      (glyph: InkGlyph.calendar, label: l10n.today),
      (glyph: InkGlyph.food, label: l10n.foods),
      (glyph: InkGlyph.training, label: l10n.records),
      (glyph: InkGlyph.profile, label: l10n.me),
    ];

    return ShellSwipe(
      currentBranch: selected,
      branchCount: items.length,
      onNudge: _nudge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Theme.of(context).colorScheme.surface),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.navigationShell,
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: .7,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _PillNavItem(
                            selected: selected == i,
                            glyph: items[i].glyph,
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
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final InkGlyph glyph;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppThemeVisuals.of(context).accent;

    return Tooltip(
      message: tooltip,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 58,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(selected),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkIcon(
                        glyph,
                        size: 24,
                        color: selected ? accent : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tooltip,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected ? accent : scheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      InkStrokeUnderline(
                        selected: selected,
                        color: accent,
                        width: 34,
                      ),
                    ],
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
