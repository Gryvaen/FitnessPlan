import 'package:flutter/material.dart';

/// Macro nutrient accent colors shared across Today / meals / charts.
abstract final class AppColors {
  static const protein = Color(0xFFD62828);
  static const carb = Color(0xFF457B9D);
  static const fat = Color(0xFFE9C46A);
}

/// Layout spacing tokens.
abstract final class AppSpacing {
  static const listPage = 16.0;
  static const formPage = 20.0;
  static const card = 16.0;
  static const section = 16.0;
  static const field = 12.0;
}

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
  TextStyle? get statUnit => titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      );
}

/// Sporty gradient / dual-tone tokens per named theme.
class AppThemeVisuals extends ThemeExtension<AppThemeVisuals> {
  const AppThemeVisuals({
    required this.scaffoldWash,
    required this.accent,
    required this.hero,
    required this.heroOnGradient,
    required this.previewColors,
    required this.surfaceGlow,
    required this.strokeGlow,
    required this.progress,
    required this.pillShell,
    required this.chipSelected,
    required this.sectionWash,
    required this.rail,
    required this.highlight,
    required this.glowSpot,
  });

  /// Soft top-of-page atmosphere (light wash or dark glow).
  final LinearGradient scaffoldWash;

  /// Nav indicator / strong accents.
  final LinearGradient accent;

  /// Core hero cards (Today calories, Profile quota).
  final LinearGradient hero;

  /// Primary text/icon color on [hero].
  final Color heroOnGradient;

  /// Dual swatch colors for theme picker preview.
  final List<Color> previewColors;

  /// Ordinary cards / list rows (stronger than wash, weaker than hero).
  final LinearGradient surfaceGlow;

  /// Neon stroke / accent bar color.
  final Color strokeGlow;

  /// Progress bars / water liquid.
  final LinearGradient progress;

  /// Bottom pill nav shell.
  final LinearGradient pillShell;

  /// Segmented / chip selected fill.
  final LinearGradient chipSelected;

  /// Flat section band wash (water / workout); between wash and surfaceGlow.
  final LinearGradient sectionWash;

  /// Left neon rail for flat rows / bands.
  final LinearGradient rail;

  /// Title underline tip / check accents.
  final Color highlight;

  /// Soft radial glow center for surfaces.
  final Color glowSpot;

  /// Safe lookup with forest fallback for tests / bootstrap.
  static AppThemeVisuals of(BuildContext context) {
    return Theme.of(context).extension<AppThemeVisuals>() ??
        AppTheme._visualsFor(AppThemeId.forest);
  }

  @override
  AppThemeVisuals copyWith({
    LinearGradient? scaffoldWash,
    LinearGradient? accent,
    LinearGradient? hero,
    Color? heroOnGradient,
    List<Color>? previewColors,
    LinearGradient? surfaceGlow,
    Color? strokeGlow,
    LinearGradient? progress,
    LinearGradient? pillShell,
    LinearGradient? chipSelected,
    LinearGradient? sectionWash,
    LinearGradient? rail,
    Color? highlight,
    Color? glowSpot,
  }) {
    return AppThemeVisuals(
      scaffoldWash: scaffoldWash ?? this.scaffoldWash,
      accent: accent ?? this.accent,
      hero: hero ?? this.hero,
      heroOnGradient: heroOnGradient ?? this.heroOnGradient,
      previewColors: previewColors ?? this.previewColors,
      surfaceGlow: surfaceGlow ?? this.surfaceGlow,
      strokeGlow: strokeGlow ?? this.strokeGlow,
      progress: progress ?? this.progress,
      pillShell: pillShell ?? this.pillShell,
      chipSelected: chipSelected ?? this.chipSelected,
      sectionWash: sectionWash ?? this.sectionWash,
      rail: rail ?? this.rail,
      highlight: highlight ?? this.highlight,
      glowSpot: glowSpot ?? this.glowSpot,
    );
  }

  @override
  AppThemeVisuals lerp(ThemeExtension<AppThemeVisuals>? other, double t) {
    if (other is! AppThemeVisuals) return this;
    return AppThemeVisuals(
      scaffoldWash:
          LinearGradient.lerp(scaffoldWash, other.scaffoldWash, t) ??
              scaffoldWash,
      accent: LinearGradient.lerp(accent, other.accent, t) ?? accent,
      hero: LinearGradient.lerp(hero, other.hero, t) ?? hero,
      heroOnGradient:
          Color.lerp(heroOnGradient, other.heroOnGradient, t) ?? heroOnGradient,
      previewColors: [
        for (var i = 0; i < previewColors.length; i++)
          Color.lerp(
                previewColors[i],
                other.previewColors[i.clamp(0, other.previewColors.length - 1)],
                t,
              ) ??
              previewColors[i],
      ],
      surfaceGlow:
          LinearGradient.lerp(surfaceGlow, other.surfaceGlow, t) ?? surfaceGlow,
      strokeGlow: Color.lerp(strokeGlow, other.strokeGlow, t) ?? strokeGlow,
      progress: LinearGradient.lerp(progress, other.progress, t) ?? progress,
      pillShell: LinearGradient.lerp(pillShell, other.pillShell, t) ?? pillShell,
      chipSelected:
          LinearGradient.lerp(chipSelected, other.chipSelected, t) ??
              chipSelected,
      sectionWash:
          LinearGradient.lerp(sectionWash, other.sectionWash, t) ?? sectionWash,
      rail: LinearGradient.lerp(rail, other.rail, t) ?? rail,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
      glowSpot: Color.lerp(glowSpot, other.glowSpot, t) ?? glowSpot,
    );
  }
}

/// Named theme presets selectable in Profile → Theme.
enum AppThemeId {
  forest,
  midnight,
  sunrise,
  graphite;

  static AppThemeId fromStorage(String? raw) {
    return AppThemeId.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppThemeId.forest,
    );
  }

  /// Primary swatch for simple previews (first hero stop).
  Color get previewColor => AppTheme._visualsFor(this).hero.colors.first;

  /// Preview dots: same stops as the hero card gradient.
  List<Color> get previewColors => AppTheme._visualsFor(this).hero.colors;
}

class AppTheme {
  const AppTheme._();

  /// Shared oil-painting rainbow base for all themes (soft pigment washes).
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

  /// Default light theme (Forest); used by bootstrap / tests.
  static ThemeData get light => ofId(AppThemeId.forest);

  static ThemeData ofId(AppThemeId id) {
    final scheme = _schemeFor(id);
    final visuals = _visualsFor(id);
    return _buildTheme(scheme, visuals);
  }

  static ColorScheme _schemeFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.forest => ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
          surface: const Color(0xFFF3F8F5),
        ).copyWith(
          primary: const Color(0xFF0F766E),
          onPrimary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF2DD4A8),
          onSecondary: const Color(0xFF042F2E),
          primaryContainer: const Color(0xFFCCFBF1),
          onPrimaryContainer: const Color(0xFF0B3D2E),
          secondaryContainer: const Color(0xFFD1FAE5),
          tertiary: const Color(0xFF059669),
        ),
      AppThemeId.midnight => ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          surface: const Color(0xFF0A1628),
        ).copyWith(
          primary: const Color(0xFF3B82F6),
          onPrimary: const Color(0xFFEFF6FF),
          secondary: const Color(0xFF60A5FA),
          onSecondary: const Color(0xFF0A1628),
          primaryContainer: const Color(0xFF1E3A5F),
          onPrimaryContainer: const Color(0xFFDBEAFE),
          secondaryContainer: const Color(0xFF1E293B),
          tertiary: const Color(0xFF38BDF8),
        ),
      AppThemeId.sunrise => ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D04),
          brightness: Brightness.light,
          surface: const Color(0xFFFFF5ED),
        ).copyWith(
          primary: const Color(0xFFE85D04),
          onPrimary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFFF8A4C),
          onSecondary: const Color(0xFF4A1C08),
          primaryContainer: const Color(0xFFFFE0CC),
          onPrimaryContainer: const Color(0xFF4A1C08),
          secondaryContainer: const Color(0xFFFFEDD5),
          tertiary: const Color(0xFFF59E0B),
        ),
      AppThemeId.graphite => ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          surface: const Color(0xFF0E1116),
        ).copyWith(
          primary: const Color(0xFF38BDF8),
          onPrimary: const Color(0xFF0C4A6E),
          secondary: const Color(0xFF94A3B8),
          onSecondary: const Color(0xFF0E1116),
          primaryContainer: const Color(0xFF1E293B),
          onPrimaryContainer: const Color(0xFFE0F2FE),
          secondaryContainer: const Color(0xFF1F2937),
          tertiary: const Color(0xFF64748B),
        ),
    };
  }

  static AppThemeVisuals _visualsFor(AppThemeId id) {
    return switch (id) {
      AppThemeId.forest => const AppThemeVisuals(
          scaffoldWash: AppTheme.oilRainbowWash,
          accent: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA3E635),
              Color(0xFFCA8A04),
              Color(0xFF0D9488),
              Color(0xFF22D3EE),
            ],
          ),
          hero: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B3D2E),
              Color(0xFFA3E635),
              Color(0xFFCA8A04),
              Color(0xFF0D9488),
              Color(0xFF22D3EE),
              Color(0xFFC4B5FD),
            ],
            stops: [0.0, 0.18, 0.32, 0.5, 0.72, 1.0],
          ),
          heroOnGradient: Color(0xFFF0FDFA),
          previewColors: [
            Color(0xFF0B3D2E),
            Color(0xFFA3E635),
            Color(0xFFCA8A04),
            Color(0xFF0D9488),
            Color(0xFF22D3EE),
            Color(0xFFC4B5FD),
          ],
          surfaceGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xEBD9F99D),
              Color(0xEBD4B86A),
              Color(0xEB5EEAD4),
              Color(0xEBA5F3FC),
              Color(0xEBDDD6FE),
            ],
          ),
          strokeGlow: Color(0xFF14B8A6),
          progress: LinearGradient(
            colors: [
              Color(0xFF0B3D2E),
              Color(0xFFA3E635),
              Color(0xFFCA8A04),
              Color(0xFF0D9488),
              Color(0xFF22D3EE),
              Color(0xFFC4B5FD),
            ],
          ),
          pillShell: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF5ECFDF5),
              Color(0xF5D9F99D),
              Color(0xF5D4B86A),
              Color(0xF599F6E4),
              Color(0xF5EDE9FE),
            ],
          ),
          chipSelected: LinearGradient(
            colors: [
              Color(0xFFA3E635),
              Color(0xFFCA8A04),
              Color(0xFF0D9488),
              Color(0xFF22D3EE),
            ],
          ),
          sectionWash: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x77D9F99D),
              Color(0x66D4B86A),
              Color(0x5599F6E4),
              Color(0x44A5F3FC),
              Color(0x33DDD6FE),
            ],
          ),
          rail: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3D2E),
              Color(0xFFA3E635),
              Color(0xFFCA8A04),
              Color(0xFF0D9488),
              Color(0xFF22D3EE),
              Color(0xFFC4B5FD),
            ],
          ),
          highlight: Color(0xFFC4B5FD),
          glowSpot: Color(0xFFA16207),
        ),
      AppThemeId.midnight => const AppThemeVisuals(
          scaffoldWash: AppTheme.oilRainbowWash,
          accent: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFFE879F9), Color(0xFF38BDF8)],
          ),
          hero: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF4338CA),
              Color(0xFFC026D3),
              Color(0xFFF472B6),
              Color(0xFF38BDF8),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          heroOnGradient: Color(0xFFEFF6FF),
          previewColors: [
            Color(0xFF0A1628),
            Color(0xFF4338CA),
            Color(0xFFC026D3),
            Color(0xFFF472B6),
            Color(0xFF38BDF8),
          ],
          surfaceGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xEB312E81),
              Color(0xEB4C1D95),
              Color(0xEB9D174D),
              Color(0xEB1E40AF),
              Color(0xEB0E7490),
            ],
          ),
          strokeGlow: Color(0xFFE879F9),
          progress: LinearGradient(
            colors: [
              Color(0xFF4338CA),
              Color(0xFF6366F1),
              Color(0xFFC026D3),
              Color(0xFFF472B6),
              Color(0xFF38BDF8),
            ],
          ),
          pillShell: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF51E1B4B),
              Color(0xF55B21B6),
              Color(0xF59D174D),
              Color(0xF51E3A8A),
            ],
          ),
          chipSelected: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFD946EF), Color(0xFF38BDF8)],
          ),
          sectionWash: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x88312E81),
              Color(0x776B21A8),
              Color(0x669D174D),
              Color(0x551E3A8A),
            ],
          ),
          rail: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4338CA),
              Color(0xFF6366F1),
              Color(0xFFC026D3),
              Color(0xFFF472B6),
              Color(0xFF38BDF8),
            ],
          ),
          highlight: Color(0xFFF472B6),
          glowSpot: Color(0xFF38BDF8),
        ),
      AppThemeId.sunrise => const AppThemeVisuals(
          scaffoldWash: AppTheme.oilRainbowWash,
          accent: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEA580C), Color(0xFFFBBF24), Color(0xFFF472B6)],
          ),
          hero: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C2D12),
              Color(0xFFEA580C),
              Color(0xFFF59E0B),
              Color(0xFFFB7185),
              Color(0xFFE9D5FF),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          heroOnGradient: Color(0xFFFFF7ED),
          previewColors: [
            Color(0xFF7C2D12),
            Color(0xFFEA580C),
            Color(0xFFF59E0B),
            Color(0xFFFB7185),
            Color(0xFFE9D5FF),
          ],
          surfaceGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xEBFFEDD5),
              Color(0xEBFED7AA),
              Color(0xEBFDE68A),
              Color(0xEBFBCFE8),
              Color(0xEBE9D5FF),
            ],
          ),
          strokeGlow: Color(0xFFF472B6),
          progress: LinearGradient(
            colors: [
              Color(0xFFC2410C),
              Color(0xFFEA580C),
              Color(0xFFFBBF24),
              Color(0xFFFB7185),
              Color(0xFFC084FC),
            ],
          ),
          pillShell: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF5FFF7ED),
              Color(0xF5FED7AA),
              Color(0xF5FCE7F3),
              Color(0xF5F3E8FF),
            ],
          ),
          chipSelected: LinearGradient(
            colors: [Color(0xFFEA580C), Color(0xFFFBBF24), Color(0xFFF472B6)],
          ),
          sectionWash: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x77FFEDD5),
              Color(0x66FED7AA),
              Color(0x55FBCFE8),
              Color(0x44E9D5FF),
            ],
          ),
          rail: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC2410C),
              Color(0xFFEA580C),
              Color(0xFFFBBF24),
              Color(0xFFFB7185),
              Color(0xFFC084FC),
            ],
          ),
          highlight: Color(0xFFC084FC),
          glowSpot: Color(0xFFFB7185),
        ),
      AppThemeId.graphite => const AppThemeVisuals(
          scaffoldWash: AppTheme.oilRainbowWash,
          accent: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE), Color(0xFF6EE7B7)],
          ),
          hero: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E1116),
              Color(0xFF7C3AED),
              Color(0xFF22D3EE),
              Color(0xFFCBD5E1),
              Color(0xFF6EE7B7),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          heroOnGradient: Color(0xFFF1F5F9),
          previewColors: [
            Color(0xFF0E1116),
            Color(0xFF7C3AED),
            Color(0xFF22D3EE),
            Color(0xFFCBD5E1),
            Color(0xFF6EE7B7),
          ],
          surfaceGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xEB2E1065),
              Color(0xEB5B21B6),
              Color(0xEB155E75),
              Color(0xEB334155),
              Color(0xEB064E3B),
            ],
          ),
          strokeGlow: Color(0xFF67E8F9),
          progress: LinearGradient(
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF8B5CF6),
              Color(0xFF22D3EE),
              Color(0xFFE2E8F0),
              Color(0xFF6EE7B7),
            ],
          ),
          pillShell: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF51F2937),
              Color(0xF54C1D95),
              Color(0xF5155E75),
              Color(0xF5064E3B),
            ],
          ),
          chipSelected: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFF34D399)],
          ),
          sectionWash: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0x882E1065),
              Color(0x775B21B6),
              Color(0x66155E75),
              Color(0x55064E3B),
            ],
          ),
          rail: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF8B5CF6),
              Color(0xFF22D3EE),
              Color(0xFFE2E8F0),
              Color(0xFF6EE7B7),
            ],
          ),
          highlight: Color(0xFF6EE7B7),
          glowSpot: Color(0xFF22D3EE),
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
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );

    final stroke = visuals.strokeGlow;

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: stroke.withValues(alpha: 0.45)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: stroke,
        selectedColor: scheme.onSurface,
        selectedTileColor: stroke.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return stroke;
          return null;
        }),
        checkColor: WidgetStatePropertyAll(visuals.heroOnGradient),
        side: BorderSide(color: stroke.withValues(alpha: 0.7), width: 1.6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: stroke,
        linearTrackColor: stroke.withValues(alpha: 0.18),
        circularTrackColor: stroke.withValues(alpha: 0.18),
      ),
      chipTheme: ChipThemeData(
        selectedColor: stroke.withValues(alpha: 0.28),
        checkmarkColor: scheme.onSurface,
        side: BorderSide(color: stroke.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return stroke.withValues(alpha: 0.35);
            }
            return scheme.surfaceContainerLowest.withValues(alpha: 0.55);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSurface;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: stroke.withValues(alpha: 0.45)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.72),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stroke.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stroke, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 52,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
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
        backgroundColor: stroke,
        foregroundColor: visuals.heroOnGradient,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      extensions: [visuals],
    );
  }
}
