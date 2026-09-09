import 'package:flutter/material.dart';

import 'app_theme.dart';

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
      decoration: _cardDecoration(v, color: color),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.compact),
      child: Material(
        color: v.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          side: BorderSide(color: v.cardBorder),
        ),
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
      ),
    );
  }
}

/// Thin accent progress bar.
class SportProgressBar extends StatelessWidget {
  const SportProgressBar({
    super.key,
    required this.value,
    this.minHeight = 6,
    this.borderRadius = 4,
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
      decoration: _cardDecoration(v, shadow: false),
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
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 24,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final fg = color ?? scheme.onSurface;
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
              child: Icon(
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

/// Small rounded label chip (e.g. strategy tag on the Today card).
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.foreground,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final v = AppThemeVisuals.of(context);
    final theme = Theme.of(context);
    final bg = color ?? v.accentSoft;
    final fg = foreground ?? theme.colorScheme.onSurface;
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
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 14, color: fg),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: chip,
        ),
      ),
    );
  }
}
