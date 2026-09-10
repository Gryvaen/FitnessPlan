import 'package:flutter/material.dart';

/// Nutrient semantic colors; identical across all themes so that protein /
/// carbs / fat / water always read the same.
abstract final class AppColors {
  static const protein = Color(0xFFE0605A);
  static const carb = Color(0xFF4C8BE0);
  static const fat = Color(0xFFE4B94B);
  static const water = Color(0xFF3FB8C6);
}

/// Layout spacing tokens.
abstract final class AppSpacing {
  static const listPage = 20.0;
  static const formPage = 20.0;
  static const card = 16.0;
  static const section = 24.0;
  static const field = 12.0;
  static const compact = 8.0;
}

/// Corner radius tokens.
abstract final class AppRadius {
  static const card = 16.0;
  static const tile = 14.0;
  static const chip = 999.0;
  static const control = 12.0;
}

/// Minimum tap target for icon-only controls.
const double kMinTapTarget = 44.0;

/// Scroll padding so list content clears the floating pill nav / FAB.
double listBottomInset(BuildContext context, {bool hasFab = true}) {
  final pad = MediaQuery.viewPaddingOf(context).bottom;
  // FAB(~56) + gap + compact icon-only floating pill (~52 bar + outer padding).
  return (hasFab ? 72.0 : 16.0) + 60.0 + pad;
}

/// Semantic text roles on top of Material 3.
extension AppTextStyles on TextTheme {
  TextStyle? get fieldLabel => labelMedium;
  TextStyle? get meta => bodySmall;
  TextStyle? get statValue => headlineSmall?.copyWith(
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );
  TextStyle? get statUnit => titleSmall?.copyWith(fontWeight: FontWeight.w500);
}

/// Per-theme surface / accent tokens shared by every page.
///
/// Pages must not hard-code colors; they read these tokens (or the Material
/// [ColorScheme]) so that all four themes share one layout.
class AppThemeVisuals extends ThemeExtension<AppThemeVisuals> {
  const AppThemeVisuals({
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.heroCard,
    required this.heroGlow,
    required this.onHero,
    required this.onHeroMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.divider,
    required this.track,
    required this.navShell,
    required this.navBorder,
    required this.navIndicator,
    required this.onNavIndicator,
    required this.waterFill,
    required this.waterFillDeep,
    required this.waterStroke,
    required this.cupGlass,
    required this.previewColors,
  });

  /// Ordinary card / list row background.
  final Color card;
  final Color cardBorder;
  final Color cardShadow;

  /// Main summary card (Today calories, Profile quota).
  final Color heroCard;

  /// Soft radial glow drawn on the hero card (transparent when unused).
  final Color heroGlow;
  final Color onHero;
  final Color onHeroMuted;

  /// Primary accent (buttons, rings, selected nav).
  final Color accent;
  final Color onAccent;

  /// Tinted accent surface (chips, selected states).
  final Color accentSoft;
  final Color divider;

  /// Progress track behind bars / rings.
  final Color track;

  /// Floating pill nav.
  final Color navShell;
  final Color navBorder;
  final Color navIndicator;
  final Color onNavIndicator;

  /// Water cup liquid (translucent) and its deeper tone near the bottom.
  final Color waterFill;
  final Color waterFillDeep;

  /// Cup outline stroke.
  final Color waterStroke;

  /// Glass body tint.
  final Color cupGlass;

  /// Swatches for the theme picker preview.
  final List<Color> previewColors;

  /// Safe lookup with default-theme fallback for tests / bootstrap.
  static AppThemeVisuals of(BuildContext context) {
    return Theme.of(context).extension<AppThemeVisuals>() ??
        AppTheme.visualsFor(AppThemeId.fresh);
  }

  @override
  AppThemeVisuals copyWith({
    Color? card,
    Color? cardBorder,
    Color? cardShadow,
    Color? heroCard,
    Color? heroGlow,
    Color? onHero,
    Color? onHeroMuted,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? divider,
    Color? track,
    Color? navShell,
    Color? navBorder,
    Color? navIndicator,
    Color? onNavIndicator,
    Color? waterFill,
    Color? waterFillDeep,
    Color? waterStroke,
    Color? cupGlass,
    List<Color>? previewColors,
  }) {
    return AppThemeVisuals(
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      heroCard: heroCard ?? this.heroCard,
      heroGlow: heroGlow ?? this.heroGlow,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      divider: divider ?? this.divider,
      track: track ?? this.track,
      navShell: navShell ?? this.navShell,
      navBorder: navBorder ?? this.navBorder,
      navIndicator: navIndicator ?? this.navIndicator,
      onNavIndicator: onNavIndicator ?? this.onNavIndicator,
      waterFill: waterFill ?? this.waterFill,
      waterFillDeep: waterFillDeep ?? this.waterFillDeep,
      waterStroke: waterStroke ?? this.waterStroke,
      cupGlass: cupGlass ?? this.cupGlass,
      previewColors: previewColors ?? this.previewColors,
    );
  }

  @override
  AppThemeVisuals lerp(ThemeExtension<AppThemeVisuals>? other, double t) {
    if (other is! AppThemeVisuals) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppThemeVisuals(
      card: c(card, other.card),
      cardBorder: c(cardBorder, other.cardBorder),
      cardShadow: c(cardShadow, other.cardShadow),
      heroCard: c(heroCard, other.heroCard),
      heroGlow: c(heroGlow, other.heroGlow),
      onHero: c(onHero, other.onHero),
      onHeroMuted: c(onHeroMuted, other.onHeroMuted),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentSoft: c(accentSoft, other.accentSoft),
      divider: c(divider, other.divider),
      track: c(track, other.track),
      navShell: c(navShell, other.navShell),
      navBorder: c(navBorder, other.navBorder),
      navIndicator: c(navIndicator, other.navIndicator),
      onNavIndicator: c(onNavIndicator, other.onNavIndicator),
      waterFill: c(waterFill, other.waterFill),
      waterFillDeep: c(waterFillDeep, other.waterFillDeep),
      waterStroke: c(waterStroke, other.waterStroke),
      cupGlass: c(cupGlass, other.cupGlass),
      previewColors: [
        for (var i = 0; i < previewColors.length; i++)
          c(
            previewColors[i],
            other.previewColors[i.clamp(0, other.previewColors.length - 1)],
          ),
      ],
    );
  }
}

/// The four selectable themes. Storage keeps the enum name; legacy ids from
/// earlier releases are mapped in [fromStorage] so existing users keep a
/// theme close to what they had chosen.
enum AppThemeId {
  /// 清新绿 — default for new users.
  fresh,

  /// 极光 — deep sea blue with teal accents.
  aurora,

  /// 暖阳 — cream with warm orange.
  warm,

  /// 石墨 — matte dark grey with silver accents.
  graphite;

  static const defaultId = fresh;

  /// Presets shown on the Theme page, in display order.
  static const presets = [fresh, aurora, warm, graphite];

  /// Legacy ids → current themes (kept for users who already picked one).
  static const legacyMap = <String, AppThemeId>{
    'day': fresh,
    'forest': fresh,
    'night': graphite,
    'graphite': graphite,
    'midnight': aurora,
    'sunrise': warm,
  };

  static AppThemeId fromStorage(String? raw) {
    if (raw == null) return defaultId;
    for (final e in values) {
      if (e.name == raw) return e;
    }
    return legacyMap[raw] ?? defaultId;
  }

  bool get isDark => this == aurora || this == graphite;

  /// Light ↔ dark counterpart used by the quick day/night toggle.
  AppThemeId get toggled => switch (this) {
    fresh => graphite,
    graphite => fresh,
    warm => aurora,
    aurora => warm,
  };

  /// Primary swatch for simple previews.
  Color get previewColor => AppTheme.visualsFor(this).accent;

  List<Color> get previewColors => AppTheme.visualsFor(this).previewColors;
}

class AppTheme {
  const AppTheme._();

  /// Display / loading-page typeface (霞鹜文楷 Lite Medium).
  static const displayFontFamily = 'LXGWWenKai';

  /// Soft rainbow wash used only by the loading-page ink bloom animation.
  static const oilRainbowWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE8E8B4B8), // rose
      Color(0xE8F5D0A9), // peach
      Color(0xE8F5E6A3), // cream yellow
      Color(0xE8B8D4C8), // sage
      Color(0xE8A8C8E8), // sky
      Color(0xE8C9B8E8), // lavender
      Color(0xE8E8C4D8), // soft magenta
    ],
    stops: [0.0, 0.16, 0.32, 0.48, 0.64, 0.8, 1.0],
  );

  /// Default light theme (清新绿); used by bootstrap / tests.
  static ThemeData get light => ofId(AppThemeId.fresh);

  static ThemeData ofId(AppThemeId id) {
    final scheme = schemeFor(id);
    final visuals = visualsFor(id);
    return _buildTheme(scheme, visuals);
  }

  static ColorScheme schemeFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.fresh => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF246B50),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFDCEDE4),
        onPrimaryContainer: Color(0xFF12382A),
        secondary: Color(0xFF3E8E6E),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE4F0EA),
        onSecondaryContainer: Color(0xFF12382A),
        tertiary: Color(0xFF3E8E6E),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFE4F0EA),
        onTertiaryContainer: Color(0xFF12382A),
        error: Color(0xFFC2413B),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFBE0DD),
        onErrorContainer: Color(0xFF5A1612),
        surface: Color(0xFFF6F8F5),
        onSurface: Color(0xFF1B2A24),
        onSurfaceVariant: Color(0xFF5C6B65),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF1F4F1),
        surfaceContainer: Color(0xFFECF1EE),
        surfaceContainerHigh: Color(0xFFE6ECE8),
        surfaceContainerHighest: Color(0xFFE0E7E2),
        outline: Color(0xFFC9D3CD),
        outlineVariant: Color(0xFFE3E8E4),
        inverseSurface: Color(0xFF2E3A35),
        onInverseSurface: Color(0xFFF1F4F1),
        inversePrimary: Color(0xFF8ED0B6),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0xFF246B50),
      ),
      AppThemeId.aurora => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF34D3C2),
        onPrimary: Color(0xFF05261F),
        primaryContainer: Color(0xFF16404A),
        onPrimaryContainer: Color(0xFFBFF3EC),
        secondary: Color(0xFF62B6E9),
        onSecondary: Color(0xFF07253A),
        secondaryContainer: Color(0xFF173A55),
        onSecondaryContainer: Color(0xFFCFE9FA),
        tertiary: Color(0xFF9DE0D6),
        onTertiary: Color(0xFF05261F),
        tertiaryContainer: Color(0xFF16404A),
        onTertiaryContainer: Color(0xFFBFF3EC),
        error: Color(0xFFFF8A80),
        onError: Color(0xFF3B0000),
        errorContainer: Color(0xFF5C1F1B),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF0A1A2B),
        onSurface: Color(0xFFE8F3F6),
        onSurfaceVariant: Color(0xFFA3B7C1),
        surfaceContainerLowest: Color(0xFF0F2439),
        surfaceContainerLow: Color(0xFF122A41),
        surfaceContainer: Color(0xFF16304A),
        surfaceContainerHigh: Color(0xFF1B3752),
        surfaceContainerHighest: Color(0xFF213E5B),
        outline: Color(0xFF3B5670),
        outlineVariant: Color(0xFF22384F),
        inverseSurface: Color(0xFFE8F3F6),
        onInverseSurface: Color(0xFF0A1A2B),
        inversePrimary: Color(0xFF1C7F74),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0xFF34D3C2),
      ),
      AppThemeId.warm => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFFD96F2E),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFCE3D0),
        onPrimaryContainer: Color(0xFF5A2E12),
        secondary: Color(0xFFC9932F),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFFBEBD2),
        onSecondaryContainer: Color(0xFF5A2E12),
        tertiary: Color(0xFFB8552A),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFFCE3D0),
        onTertiaryContainer: Color(0xFF5A2E12),
        error: Color(0xFFC24A3B),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFBE0DD),
        onErrorContainer: Color(0xFF5A1612),
        surface: Color(0xFFFBF5EC),
        onSurface: Color(0xFF3B2A1F),
        onSurfaceVariant: Color(0xFF7C6A5D),
        surfaceContainerLowest: Color(0xFFFFFDF9),
        surfaceContainerLow: Color(0xFFF8F0E5),
        surfaceContainer: Color(0xFFF4EADF),
        surfaceContainerHigh: Color(0xFFF0E4D6),
        surfaceContainerHighest: Color(0xFFEBDDCD),
        outline: Color(0xFFDCCDBE),
        outlineVariant: Color(0xFFEFE3D6),
        inverseSurface: Color(0xFF3B2A1F),
        onInverseSurface: Color(0xFFFBF5EC),
        inversePrimary: Color(0xFFF7B48E),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0xFFD96F2E),
      ),
      AppThemeId.graphite => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFC7CED6),
        onPrimary: Color(0xFF14181D),
        primaryContainer: Color(0xFF3A414A),
        onPrimaryContainer: Color(0xFFEEF2F6),
        secondary: Color(0xFF8FB6D6),
        onSecondary: Color(0xFF0F1B26),
        secondaryContainer: Color(0xFF2E3A47),
        onSecondaryContainer: Color(0xFFDCE9F5),
        tertiary: Color(0xFFA9B4C0),
        onTertiary: Color(0xFF14181D),
        tertiaryContainer: Color(0xFF3A414A),
        onTertiaryContainer: Color(0xFFEEF2F6),
        error: Color(0xFFFF8A80),
        onError: Color(0xFF3B0000),
        errorContainer: Color(0xFF5C1F1B),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF1B1E22),
        onSurface: Color(0xFFECEFF2),
        onSurfaceVariant: Color(0xFFA6AEB8),
        surfaceContainerLowest: Color(0xFF24282E),
        surfaceContainerLow: Color(0xFF272B31),
        surfaceContainer: Color(0xFF2C3138),
        surfaceContainerHigh: Color(0xFF31373E),
        surfaceContainerHighest: Color(0xFF373E46),
        outline: Color(0xFF4A525B),
        outlineVariant: Color(0xFF30363D),
        inverseSurface: Color(0xFFECEFF2),
        onInverseSurface: Color(0xFF1B1E22),
        inversePrimary: Color(0xFF5B646E),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0xFFC7CED6),
      ),
    };
  }

  static AppThemeVisuals visualsFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.fresh => const AppThemeVisuals(
        card: Color(0xFFFFFFFF),
        cardBorder: Color(0xFFE3E8E4),
        cardShadow: Color(0x14203A2E),
        heroCard: Color(0xFFFFFFFF),
        heroGlow: Color(0x00000000),
        onHero: Color(0xFF1B2A24),
        onHeroMuted: Color(0xFF5C6B65),
        accent: Color(0xFF246B50),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFE4F0EA),
        divider: Color(0xFFE3E8E4),
        track: Color(0xFFE6ECE8),
        navShell: Color(0xFFFFFFFF),
        navBorder: Color(0xFFE3E8E4),
        navIndicator: Color(0xFF246B50),
        onNavIndicator: Color(0xFFFFFFFF),
        waterFill: Color(0x9977CBB0),
        waterFillDeep: Color(0xCC4FB894),
        waterStroke: Color(0xFF246B50),
        cupGlass: Color(0x14246B50),
        previewColors: [
          Color(0xFF246B50),
          Color(0xFFF6F8F5),
          Color(0xFF77CBB0),
        ],
      ),
      AppThemeId.aurora => const AppThemeVisuals(
        card: Color(0xFF0F2439),
        cardBorder: Color(0xFF22384F),
        cardShadow: Color(0x33000000),
        heroCard: Color(0xFF0D2237),
        heroGlow: Color(0x5534D3C2),
        onHero: Color(0xFFE8F3F6),
        onHeroMuted: Color(0xFFA3B7C1),
        accent: Color(0xFF34D3C2),
        onAccent: Color(0xFF05261F),
        accentSoft: Color(0xFF16404A),
        divider: Color(0xFF22384F),
        track: Color(0xFF1B3752),
        navShell: Color(0xFF0F2439),
        navBorder: Color(0xFF22384F),
        navIndicator: Color(0xFF34D3C2),
        onNavIndicator: Color(0xFF05261F),
        waterFill: Color(0xA634D3C2),
        waterFillDeep: Color(0xD91FB3A6),
        waterStroke: Color(0xFF9DE0D6),
        cupGlass: Color(0x1A9DE0D6),
        previewColors: [
          Color(0xFF0A1A2B),
          Color(0xFF34D3C2),
          Color(0xFF62B6E9),
        ],
      ),
      AppThemeId.warm => const AppThemeVisuals(
        card: Color(0xFFFFFDF9),
        cardBorder: Color(0xFFEFE3D6),
        cardShadow: Color(0x143B2A1F),
        heroCard: Color(0xFFFFFDF9),
        heroGlow: Color(0x00000000),
        onHero: Color(0xFF3B2A1F),
        onHeroMuted: Color(0xFF7C6A5D),
        accent: Color(0xFFD96F2E),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFFCE3D0),
        divider: Color(0xFFEFE3D6),
        track: Color(0xFFF0E4D6),
        navShell: Color(0xFFFFFDF9),
        navBorder: Color(0xFFEFE3D6),
        navIndicator: Color(0xFFD96F2E),
        onNavIndicator: Color(0xFFFFFFFF),
        waterFill: Color(0x99F2A968),
        waterFillDeep: Color(0xCCE38A3E),
        waterStroke: Color(0xFFB8552A),
        cupGlass: Color(0x14D96F2E),
        previewColors: [
          Color(0xFFD96F2E),
          Color(0xFFFBF5EC),
          Color(0xFFF2A968),
        ],
      ),
      AppThemeId.graphite => const AppThemeVisuals(
        card: Color(0xFF24282E),
        cardBorder: Color(0xFF30363D),
        cardShadow: Color(0x33000000),
        heroCard: Color(0xFF24282E),
        heroGlow: Color(0x00000000),
        onHero: Color(0xFFECEFF2),
        onHeroMuted: Color(0xFFA6AEB8),
        accent: Color(0xFFC7CED6),
        onAccent: Color(0xFF14181D),
        accentSoft: Color(0xFF3A414A),
        divider: Color(0xFF30363D),
        track: Color(0xFF31373E),
        navShell: Color(0xFF24282E),
        navBorder: Color(0xFF30363D),
        navIndicator: Color(0xFFC7CED6),
        onNavIndicator: Color(0xFF14181D),
        waterFill: Color(0xA67FB3D5),
        waterFillDeep: Color(0xD95C98C2),
        waterStroke: Color(0xFFC7CED6),
        cupGlass: Color(0x1AC7CED6),
        previewColors: [
          Color(0xFF1B1E22),
          Color(0xFFC7CED6),
          Color(0xFF7FB3D5),
        ],
      ),
    };
  }

  static ThemeData _buildTheme(ColorScheme scheme, AppThemeVisuals visuals) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );

    final accent = visuals.accent;
    final border = visuals.cardBorder;

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: visuals.divider,
      dividerTheme: DividerThemeData(
        color: visuals.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        selectedColor: scheme.onSurface,
        selectedTileColor: visuals.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        checkColor: WidgetStatePropertyAll(visuals.onAccent),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? visuals.onAccent
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : scheme.surfaceContainerHighest,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: visuals.track,
        circularTrackColor: visuals.track,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: accent,
        checkmarkColor: visuals.onAccent,
        showCheckmark: false,
        side: BorderSide.none,
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: visuals.onAccent),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return visuals.accentSoft;
            }
            return visuals.card;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSurface;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: visuals.onAccent,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          textStyle: text.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: visuals.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: visuals.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: visuals.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          side: BorderSide(color: border),
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 52,
        backgroundColor: Colors.transparent,
        indicatorColor: visuals.navIndicator,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? visuals.onNavIndicator
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: accent,
        foregroundColor: visuals.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      extensions: [visuals],
    );
  }
}
