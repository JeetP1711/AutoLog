import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const double xxl = 48.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Text style constants
// ─────────────────────────────────────────────────────────────────────────────

/// Predefined text styles for headings, body copy, and captions.
///
/// These are base styles without color — apply `.copyWith(color: ...)` when
/// you need a specific color, or rely on the theme's [TextTheme] for
/// context-aware coloring.
abstract final class AppTextStyles {
  // Headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Labels / Captions
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  /// Convenience alias — caption-sized text for secondary information.
  static const TextStyle caption = labelSmall;

  /// Monospaced style for odometer readings and numeric data.
  static const TextStyle numeric = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared shape constants
// ─────────────────────────────────────────────────────────────────────────────

const _cardRadius = BorderRadius.all(Radius.circular(16));
const _inputRadius = BorderRadius.all(Radius.circular(12));
const _buttonRadius = BorderRadius.all(Radius.circular(12));
const _fabRadius = BorderRadius.all(Radius.circular(16));

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the Material 3 [ThemeData] for the AutoLog app.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme(),
///   darkTheme: AppTheme.darkTheme(),
///   themeMode: ThemeMode.dark,
/// );
/// ```
abstract final class AppTheme {
  // ── Dark Theme ──────────────────────────────────────────────────────────────

  /// Dark graphite + blue accent Material 3 theme.
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBlueDark,
      onPrimaryContainer: AppColors.primaryBlueLight,
      secondary: AppColors.primaryBlueLight,
      onSecondary: AppColors.darkBackground,
      secondaryContainer: const Color(0xFF1A2A3A),
      onSecondaryContainer: AppColors.primaryBlueLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.darkDivider,
      outlineVariant: const Color(0xFF1E1E2E),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF4A1010),
      onErrorContainer: const Color(0xFFFFB4AB),
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.primaryBlueDark,
      scrim: Colors.black87,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      appBarBackground: AppColors.darkNavBar,
      appBarForeground: AppColors.textPrimaryDark,
      navBarBackground: AppColors.darkNavBar,
      inputFillColor: AppColors.darkSurface,
      inputBorderColor: AppColors.darkDivider,
      inputFocusedBorderColor: AppColors.primaryBlue,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textDisabled: AppColors.textDisabledDark,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.darkNavBar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────────

  /// Clean white + blue accent Material 3 theme.
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      primary: AppColors.primaryBlueDark,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E8FF),
      onPrimaryContainer: AppColors.primaryBlueDark,
      secondary: AppColors.primaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE3F2FD),
      onSecondaryContainer: AppColors.primaryBlueDark,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.lightDivider,
      outlineVariant: const Color(0xFFF0F0F0),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: AppColors.lightBackground,
      inversePrimary: AppColors.primaryBlueLight,
      scrim: Colors.black54,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,
      appBarBackground: AppColors.lightNavBar,
      appBarForeground: AppColors.textPrimaryLight,
      navBarBackground: AppColors.lightNavBar,
      inputFillColor: AppColors.lightSurface,
      inputBorderColor: AppColors.lightDivider,
      inputFocusedBorderColor: AppColors.primaryBlueDark,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textDisabled: AppColors.textDisabledLight,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.lightNavBar,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // ── Private builder ─────────────────────────────────────────────────────────

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

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: appBarForeground,
        ),
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        systemOverlayStyle: systemOverlayStyle,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        indicatorColor: colorScheme.primary.withAlpha(30),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.labelSmall.copyWith(color: textSecondary);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Input Decoration ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
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
          borderSide: BorderSide(color: inputFocusedBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide(color: inputBorderColor.withAlpha(80)),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textDisabled),
        errorStyle: AppTextStyles.labelSmall.copyWith(color: colorScheme.error),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: inputFocusedBorderColor,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: _fabRadius),
        extendedTextStyle: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),

      // ── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: colorScheme.primary.withAlpha(30),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: textPrimary),
        side: BorderSide(color: inputBorderColor),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: dividerColor,
      ),

      // ── Snack Bar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 4,
      ),

      // ── List Tile ────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTextStyles.labelMedium.copyWith(
          color: textSecondary,
        ),
        iconColor: textSecondary,
        shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
      ),

      // ── Divider ──────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withAlpha(80);
          }
          return inputBorderColor;
        }),
      ),

      // ── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: inputBorderColor,
        circularTrackColor: inputBorderColor,
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge,
        dividerColor: dividerColor,
      ),

      // ── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: textSecondary, size: 24),
      primaryIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
    );
  }
}
