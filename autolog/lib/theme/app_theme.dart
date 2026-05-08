import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Spacing constants
// ─────────────────────────────────────────────────────────────────────────────

/// Consistent spacing scale used throughout the AutoLog UI.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xl2 = 40.0;
  static const double xl3 = 48.0;
  static const double xxl = 64.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Text style constants
// ─────────────────────────────────────────────────────────────────────────────

/// Predefined text styles for headings, body copy, and captions.
abstract final class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter();

  // Headings
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle get displaySmall => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      );

  static TextStyle get headlineLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineMedium => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.29,
      );

  static TextStyle get headlineSmall => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.33,
      );

  static TextStyle get titleLarge => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
      );

  static TextStyle get titleMedium => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get titleSmall => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // Body
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      );

  // Labels / Captions
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      );

  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      );

  static TextStyle get numeric => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFeatures: [const FontFeature.tabularFigures()],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared shape constants
// ─────────────────────────────────────────────────────────────────────────────

const _cardRadius = BorderRadius.all(Radius.circular(24));
const _inputRadius = BorderRadius.all(Radius.circular(16));
const _buttonRadius = BorderRadius.all(Radius.circular(16));
const _fabRadius = BorderRadius.all(Radius.circular(16));

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBlue.withAlpha(40),
      onPrimaryContainer: AppColors.primaryBlueLight,
      secondary: AppColors.primaryBlueLight,
      onSecondary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.darkDivider,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      appBarBackground: AppColors.darkBackground,
      appBarForeground: AppColors.textPrimaryDark,
      navBarBackground: AppColors.darkSurface,
      inputFillColor: AppColors.darkSurface,
      inputBorderColor: AppColors.darkDivider,
      inputFocusedBorderColor: AppColors.primaryBlue,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textDisabled: AppColors.textDisabledDark,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.darkSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBlue.withAlpha(20),
      onPrimaryContainer: AppColors.primaryBlue,
      secondary: AppColors.primaryBlue,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.lightDivider,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,
      appBarBackground: AppColors.lightBackground,
      appBarForeground: AppColors.textPrimaryLight,
      navBarBackground: AppColors.lightSurface,
      inputFillColor: AppColors.lightSurface,
      inputBorderColor: AppColors.lightDivider,
      inputFocusedBorderColor: AppColors.primaryBlue,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textDisabled: AppColors.textDisabledLight,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.lightSurface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color dividerColor,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color navBarBackground,
    required Color inputFillColor,
    required Color inputBorderColor,
    required Color inputFocusedBorderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textDisabled,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: textPrimary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: textPrimary),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: textPrimary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: textPrimary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: textPrimary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: textPrimary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: textPrimary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: textPrimary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: textPrimary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: textPrimary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: textSecondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: textDisabled),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: dividerColor,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: appBarForeground),
        iconTheme: IconThemeData(color: appBarForeground, size: 22),
        systemOverlayStyle: systemOverlayStyle,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: Colors.transparent),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.primary.withAlpha(20),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: textSecondary.withAlpha(180), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: colorScheme.primary, fontSize: 10);
          }
          return AppTextStyles.labelSmall.copyWith(color: textSecondary.withAlpha(180), fontSize: 10);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: inputFocusedBorderColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textDisabled),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(color: colorScheme.primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: _fabRadius),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withAlpha(100)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: colorScheme.onPrimary),
        side: BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: colorScheme.primary),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),

      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
    );
  }
}
