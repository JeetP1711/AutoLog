import 'package:flutter/material.dart';

/// All color constants used throughout the AutoLog app.
///
/// Dark theme uses a graphite/navy palette with a premium blue accent.
/// Light theme uses clean whites with the same blue accent for consistency.
abstract final class AppColors {
  // ── Brand / Accent ──────────────────────────────────────────────────────────

  /// Primary blue accent — used for FABs, active icons, and highlights.
  static const Color primaryBlue = Color(0xFF2196F3);

  /// Darker blue variant for pressed/focused states.
  static const Color primaryBlueDark = Color(0xFF1565C0);

  /// Lighter blue for secondary actions and tinted surfaces.
  static const Color primaryBlueLight = Color(0xFF64B5F6);

  // ── Dark Theme Surfaces ──────────────────────────────────────────────────────

  /// Deepest background — used as scaffold background in dark mode.
  static const Color darkBackground = Color(0xFF0D0D0D);

  /// Primary surface — used for cards and bottom sheets in dark mode.
  static const Color darkSurface = Color(0xFF1E1E2E);

  /// Elevated surface — used for dialogs and elevated cards in dark mode.
  static const Color darkSurfaceElevated = Color(0xFF252535);

  /// App bar / navigation bar background in dark mode.
  static const Color darkNavBar = Color(0xFF1A1A2E);

  /// Divider and border color in dark mode.
  static const Color darkDivider = Color(0xFF2A2A3E);

  // ── Light Theme Surfaces ─────────────────────────────────────────────────────

  /// Scaffold background in light mode.
  static const Color lightBackground = Color(0xFFF5F5F5);

  /// Primary surface for cards in light mode.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Elevated surface for dialogs in light mode.
  static const Color lightSurfaceElevated = Color(0xFFFAFAFA);

  /// App bar background in light mode.
  static const Color lightNavBar = Color(0xFFFFFFFF);

  /// Divider and border color in light mode.
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ── Text ─────────────────────────────────────────────────────────────────────

  /// Primary text on dark backgrounds.
  static const Color textPrimaryDark = Color(0xFFEEEEEE);

  /// Secondary / muted text on dark backgrounds.
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  /// Disabled text on dark backgrounds.
  static const Color textDisabledDark = Color(0xFF616161);

  /// Primary text on light backgrounds.
  static const Color textPrimaryLight = Color(0xFF212121);

  /// Secondary / muted text on light backgrounds.
  static const Color textSecondaryLight = Color(0xFF757575);

  /// Disabled text on light backgrounds.
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // ── Semantic ─────────────────────────────────────────────────────────────────

  /// Success / positive indicator (e.g. good mileage, valid input).
  static const Color success = Color(0xFF4CAF50);

  /// Warning indicator (e.g. expiring documents, odometer regression).
  static const Color warning = Color(0xFFFFC107);

  /// Error / destructive indicator (e.g. overdue reminders, delete actions).
  static const Color error = Color(0xFFF44336);

  /// Informational indicator.
  static const Color info = Color(0xFF29B6F6);

  // ── Fuel Type Accents ────────────────────────────────────────────────────────

  static const Color fuelPetrol = Color(0xFFFF7043);
  static const Color fuelDiesel = Color(0xFF8D6E63);
  static const Color fuelCng = Color(0xFF26C6DA);
  static const Color fuelElectric = Color(0xFF66BB6A);
  static const Color fuelHybrid = Color(0xFFAB47BC);
  static const Color fuelLpg = Color(0xFFFFCA28);
  static const Color fuelHydrogen = Color(0xFF42A5F5);

  // ── Chart Palette ────────────────────────────────────────────────────────────

  static const List<Color> chartPalette = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];
}
