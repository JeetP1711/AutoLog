import 'package:flutter/material.dart';

/// All color constants used throughout the AutoLog app.
///
/// Dark theme uses a graphite/navy palette with a premium blue accent.
/// Light theme uses clean whites with the same blue accent for consistency.
abstract final class AppColors {
  // ── Brand / Accent ──────────────────────────────────────────────────────────

  /// Primary blue accent — used for FABs, active icons, and highlights.
  static const Color primaryBlue = Color(0xFF2563EB);

  /// Darker blue variant for pressed/focused states.
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  /// Lighter blue for secondary actions and tinted surfaces.
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  // ── Dark Theme Surfaces ──────────────────────────────────────────────────────

  /// Deepest background — used as scaffold background in dark mode.
  static const Color darkBackground = Color(0xFF0F172A);

  /// Primary surface — used for cards and bottom sheets in dark mode.
  static const Color darkSurface = Color(0xFF1E293B);

  /// Elevated surface — used for dialogs and elevated cards in dark mode.
  static const Color darkSurfaceElevated = Color(0xFF334155);

  /// App bar / navigation bar background in dark mode.
  static const Color darkNavBar = Color(0xFF1E293B);

  /// Divider and border color in dark mode.
  static const Color darkDivider = Color(0xFF334155);

  // ── Light Theme Surfaces ─────────────────────────────────────────────────────

  /// Scaffold background in light mode.
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Primary surface for cards in light mode.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Elevated surface for dialogs in light mode.
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// App bar background in light mode.
  static const Color lightNavBar = Color(0xFFFFFFFF);

  /// Divider and border color in light mode.
  static const Color lightDivider = Color(0xFFE5E7EB);

  // ── Text ─────────────────────────────────────────────────────────────────────

  /// Primary text on dark backgrounds.
  static const Color textPrimaryDark = Color(0xFFF1F5F9);

  /// Secondary / muted text on dark backgrounds.
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  /// Disabled text on dark backgrounds.
  static const Color textDisabledDark = Color(0xFF475569);

  /// Primary text on light backgrounds.
  static const Color textPrimaryLight = Color(0xFF0F172A);

  /// Secondary / muted text on light backgrounds.
  static const Color textSecondaryLight = Color(0xFF64748B);

  /// Disabled text on light backgrounds.
  static const Color textDisabledLight = Color(0xFF94A3B8);

  // ── Semantic ─────────────────────────────────────────────────────────────────

  /// Success / positive indicator (e.g. good mileage, valid input).
  static const Color success = Color(0xFF10B981);

  /// Warning indicator (e.g. expiring documents, odometer regression).
  static const Color warning = Color(0xFFF59E0B);

  /// Error / destructive indicator (e.g. overdue reminders, delete actions).
  static const Color error = Color(0xFFEF4444);

  /// Informational indicator.
  static const Color info = Color(0xFF3B82F6);

  // ── Fuel Type Accents ────────────────────────────────────────────────────────

  static const Color fuelPetrol = Color(0xFFF97316);
  static const Color fuelDiesel = Color(0xFF78350F);
  static const Color fuelCng = Color(0xFF06B6D4);
  static const Color fuelElectric = Color(0xFF10B981);
  static const Color fuelHybrid = Color(0xFF8B5CF6);
  static const Color fuelLpg = Color(0xFFEAB308);
  static const Color fuelHydrogen = Color(0xFF3B82F6);

  // ── Chart Palette ────────────────────────────────────────────────────────────

  static const List<Color> chartPalette = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

}
