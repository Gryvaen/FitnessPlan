import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';

/// Large inline page heading used at the top of a tab-root body (replaces the
/// AppBar title in the V2 "open list" layout). Optional [subtitle] and a
/// trailing [action] (usually a text button or plain "+").
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.listPage,
      8,
      AppSpacing.listPage,
      AppSpacing.section,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Underlined text navigation; wraps at large text sizes instead of clipping.
class SportTabs<T> extends StatelessWidget {
  const SportTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });
  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      children: [
        for (final entry in items.entries)
          Semantics(
            selected: entry.key == selected,
            button: true,
            child: InkWell(
              onTap: () => onSelected(entry.key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 3,
                      color: entry.key == selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: entry.key == selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SportEmptyState extends StatelessWidget {
  const SportEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.iconWidget,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? iconWidget;

  /// Primary call to action, rendered as a [FilledButton].
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional lower-emphasis action, rendered as a [TextButton] below the primary.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      // Full width regardless of the parent's crossAxisAlignment (many
      // callers sit in a `start`-aligned Column), so the icon/text/actions
      // below center on the row instead of hugging the left edge.
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.55,
                  ),
                ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The shared illustrated mark used by the app's primary empty states.
///
/// Keeps the ink glyph and its lower-right seal aligned consistently across
/// Today and Records surfaces.
class StampedInkEmptyIcon extends StatelessWidget {
  const StampedInkEmptyIcon({
    super.key,
    required this.glyph,
    required this.seal,
  });

  final InkGlyph glyph;
  final String seal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      key: ValueKey('stamped-empty-icon-$seal'),
      clipBehavior: Clip.none,
      children: [
        InkIcon(
          glyph,
          size: 52,
          color: scheme.onSurfaceVariant.withValues(alpha: .62),
          strokeWidth: 1.6,
        ),
        Positioned(right: -8, bottom: -3, child: InkSeal(seal, size: 19)),
      ],
    );
  }
}

class SportLoadError extends StatelessWidget {
  const SportLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => SportEmptyState(
    title: context.l10n.loadRecordsFailed,
    iconWidget: InkIcon(
      InkGlyph.error,
      size: 48,
      color: Theme.of(context).colorScheme.error,
    ),
    actionLabel: context.l10n.retry,
    onAction: onRetry,
  );
}

/// Tab-root scaffold: flat themed surface with a transparent AppBar.
class AppChromeScaffold extends StatelessWidget {
  const AppChromeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

BoxDecoration _cardDecoration(
  AppThemeVisuals v, {
  Color? color,
  double radius = AppRadius.card,
  bool shadow = true,
}) {
  return BoxDecoration(
    color: color ?? v.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: v.cardBorder),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: v.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : null,
  );
}

/// Main summary card (Today calories, Profile quota).
class SportHeroCard extends StatelessWidget {
  const SportHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(v, color: v.heroCard),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            if (v.heroGlow.a > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.9, -0.9),
                      radius: 1.1,
                      colors: [v.heroGlow, v.heroGlow.withValues(alpha: 0)],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: v.onHero),
                child: IconTheme.merge(
                  data: IconThemeData(color: v.onHero),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ordinary card (menus, warnings, sections).
class SportSurfaceCard extends StatelessWidget {
  const SportSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.tint,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Optional semantic tint (warning / info) blended into the card.
  final Color? tint;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    final color = tint == null
        ? v.card
        : Color.alphaBlend(tint!.withValues(alpha: 0.10), v.card);
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: tint == null ? Colors.transparent : color,
        border: Border(bottom: BorderSide(color: v.divider)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// List row rendered as a small card.
class SportListTile extends StatelessWidget {
  const SportListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.dense,
    this.enabled = true,
    this.isThreeLine = false,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  final bool enabled;
  final bool isThreeLine;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    return Material(
      color: Colors.transparent,
      shape: Border(bottom: BorderSide(color: v.divider)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: enabled,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        dense: dense,
        isThreeLine: isThreeLine,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}

/// Thin accent progress bar.
class SportProgressBar extends StatelessWidget {
  const SportProgressBar({
    super.key,
    required this.value,
    this.minHeight = 4,
    this.borderRadius = 3,
    this.color,
  });

  final double value;
  final double minHeight;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: minHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: v.track),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: clamped,
              child: ColoredBox(color: color ?? v.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A progress mark rendered from a real, generated dry-brush texture.
class InkBrushProgressBar extends StatelessWidget {
  const InkBrushProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final activeInk = color ?? Theme.of(context).colorScheme.onSurface;
    final direction = Directionality.of(context);

    return Semantics(
      label: '${(clamped * 100).round()}%',
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BrushTexture(
              color: visuals.track.withValues(alpha: .72),
              flipHorizontally: direction == TextDirection.rtl,
            ),
            if (clamped > 0)
              FractionallySizedBox(
                alignment: direction == TextDirection.rtl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                widthFactor: clamped,
                child: _BrushTexture(
                  color: activeInk,
                  flipHorizontally: direction == TextDirection.rtl,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrushTexture extends StatelessWidget {
  const _BrushTexture({required this.color, this.flipHorizontally = false});

  final Color color;
  final bool flipHorizontally;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      'assets/ink/workout_progress_brush.png',
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
    if (flipHorizontally) {
      image = Transform.flip(flipX: true, child: image);
    }
    return image;
  }
}

/// Floating pill nav shell.
class SportPillShell extends StatelessWidget {
  const SportPillShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: v.navShell,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: v.navBorder),
        boxShadow: [
          BoxShadow(
            color: v.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

/// Flat section container (card without shadow) for secondary blocks.
class SportSectionBand extends StatelessWidget {
  const SportSectionBand({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.showBottomRule = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showBottomRule;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: showBottomRule
            ? Border(bottom: BorderSide(color: v.divider))
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Flat list row without card chrome.
class SportInkRow extends StatelessWidget {
  const SportInkRow({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.enabled = true,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        enabled: enabled,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }
}

/// Section title (plain text; spacing handled by callers).
class SportSectionTitle extends StatelessWidget {
  const SportSectionTitle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Icon-only action without any background, border or shadow, but with a
/// full-size tap target and a semantic label.
class PlainIconAction extends StatelessWidget {
  const PlainIconAction({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onPressed,
    this.size = 24,
    this.color,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = color ?? AppThemeVisuals.of(context).accent;
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Tooltip(
        message: label,
        // The outer Semantics already carries the label.
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: kMinTapTarget / 2,
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          child: SizedBox(
            width: kMinTapTarget,
            height: kMinTapTarget,
            child: Center(
              child:
                  iconWidget ??
                  Icon(
                    icon,
                    size: size,
                    color: enabled ? fg : fg.withValues(alpha: 0.35),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted leading icon for hub / menu entry rows — color only, no circle
/// badge behind it.
///
/// Use for **category & entry** icons (profile, tools, reminders). Keep
/// chrome actions (add / delete / chevron / more) in muted grey — coloring
/// those too makes the page noisy.
class MenuIconBadge extends StatelessWidget {
  const MenuIconBadge({
    super.key,
    this.icon,
    this.child,
    required this.color,
    this.size = 24,
  });

  final IconData? icon;
  final Widget? child;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return child ?? Icon(icon, color: color, size: size);
  }
}

/// Small rounded label chip (e.g. strategy tag on the Today card).
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.color,
    this.foreground,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? foreground;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    final theme = Theme.of(context);
    final bg = color ?? v.accentSoft;
    final fg =
        foreground ?? (selected ? v.accent : theme.colorScheme.onSurface);
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null && onLongPress == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          onLongPress: onLongPress,
          child: chip,
        ),
      ),
    );
  }
}
