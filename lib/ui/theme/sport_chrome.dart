import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Tab-root scaffold with sporty top wash and transparent AppBar chrome.
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
    final visuals = AppThemeVisuals.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: visuals.scaffoldWash),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        ),
      ],
    );
  }
}

/// Gradient hero surface for core summary cards.
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
    final visuals = AppThemeVisuals.of(context);
    final on = visuals.heroOnGradient;
    final heroColors = visuals.hero.colors;
    final glowA = heroColors.length > 1
        ? heroColors[heroColors.length - 2]
        : heroColors.last;
    final glowB = heroColors.last;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on.withValues(alpha: 0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowB.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: visuals.hero),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.75),
                    radius: 1.15,
                    colors: [
                      glowB.withValues(alpha: 0.4),
                      glowA.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: on),
                child: IconTheme.merge(
                  data: IconThemeData(color: on),
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

/// Neon-edged surface for ordinary cards (warnings, menus, workout shell).
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
  final Color? tint;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);
    final stroke = visuals.strokeGlow;

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: stroke.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: visuals.surfaceGlow),
              ),
            ),
            if (tint != null)
              Positioned.fill(
                child: ColoredBox(color: tint!.withValues(alpha: 0.28)),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      stroke.withValues(alpha: 0.55),
                      stroke.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.08],
                  ),
                ),
              ),
            ),
            if (padding != null)
              Padding(padding: padding!, child: child)
            else
              child,
          ],
        ),
      ),
    );
  }
}

/// List row with surface glow and left neon bar.
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
    final visuals = AppThemeVisuals.of(context);
    final stroke = visuals.strokeGlow;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.field),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: visuals.surfaceGlow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stroke.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.9, -0.85),
                          radius: 0.95,
                          colors: [
                            visuals.glowSpot.withValues(alpha: 0.22),
                            visuals.glowSpot.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            gradient: visuals.rail,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            enabled: enabled,
                            leading: leading,
                            title: title,
                            subtitle: subtitle,
                            trailing: trailing,
                            onTap: null,
                            dense: dense,
                            isThreeLine: isThreeLine,
                            contentPadding: contentPadding ??
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-color progress bar using theme [AppThemeVisuals.progress].
class SportProgressBar extends StatelessWidget {
  const SportProgressBar({
    super.key,
    required this.value,
    this.minHeight = 10,
    this.borderRadius = 6,
  });

  final double value;
  final double minHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);
    final v = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: minHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: visuals.strokeGlow.withValues(alpha: 0.16),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: visuals.progress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom nav pill outer shell with neon gradient.
class SportPillShell extends StatelessWidget {
  const SportPillShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);
    final stroke = visuals.strokeGlow;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: visuals.pillShell,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: stroke.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, -0.85),
                    radius: 1.0,
                    colors: [
                      visuals.glowSpot.withValues(alpha: 0.2),
                      visuals.glowSpot.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              elevation: 0,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat neon section (no card chrome): wash + left rail + optional bottom line.
class SportSectionBand extends StatelessWidget {
  const SportSectionBand({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.showBottomRule = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showBottomRule;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(gradient: visuals.rail),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: visuals.sectionWash),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.95, -0.9),
                            radius: 1.05,
                            colors: [
                              visuals.glowSpot.withValues(alpha: 0.18),
                              visuals.glowSpot.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: padding, child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showBottomRule)
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(gradient: visuals.progress),
          ),
      ],
    );
  }
}

/// Flat list row: rail + light wash, no border/shadow.
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
    final visuals = AppThemeVisuals.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(gradient: visuals.sectionWash),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(gradient: visuals.rail),
                ),
                Expanded(
                  child: ListTile(
                    enabled: enabled,
                    leading: leading,
                    title: title,
                    subtitle: subtitle,
                    trailing: trailing,
                    onTap: null,
                    contentPadding: contentPadding ??
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title with a short neon underline.
class SportSectionTitle extends StatelessWidget {
  const SportSectionTitle({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visuals = AppThemeVisuals.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          height: 8,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 0,
                top: 2.5,
                child: Container(
                  width: 56,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: visuals.progress,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: 50,
                top: 0.5,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: visuals.highlight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: visuals.highlight.withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
