import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../theme/theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Keys {
  static const String currencySymbol = 'currency_symbol';
  static const String distanceUnit = 'distance_unit';
  static const String pinEnabled = 'pin_enabled';
  static const String onboardingCompleted = 'onboarding_completed';
}

// ─────────────────────────────────────────────────────────────────────────────
// SettingsNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages all user-configurable settings backed by [SharedPreferences].
///
/// Theme mode is delegated to [ThemeController] (which has its own provider).
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _load(SharedPreferences prefs) {
    final themeName = prefs.getString('theme_mode') ?? 'dark';
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeName,
      orElse: () => ThemeMode.dark,
    );
    final distanceUnitName = prefs.getString(_Keys.distanceUnit) ?? 'km';
    final distanceUnit = DistanceUnit.values.firstWhere(
      (u) => u.name == distanceUnitName,
      orElse: () => DistanceUnit.km,
    );
    return AppSettings(
      themeMode: themeMode,
      currencySymbol: prefs.getString(_Keys.currencySymbol) ?? '₹',
      distanceUnit: distanceUnit,
      pinEnabled: prefs.getBool(_Keys.pinEnabled) ?? false,
      onboardingCompleted: prefs.getBool(_Keys.onboardingCompleted) ?? false,
    );
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  Future<void> setCurrencySymbol(String symbol) async {
    await _prefs.setString(_Keys.currencySymbol, symbol);
    state = state.copyWith(currencySymbol: symbol);
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    await _prefs.setString(_Keys.distanceUnit, unit.name);
    state = state.copyWith(distanceUnit: unit);
  }

  Future<void> setPinEnabled(bool enabled) async {
    await _prefs.setBool(_Keys.pinEnabled, enabled);
    state = state.copyWith(pinEnabled: enabled);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_Keys.onboardingCompleted, completed);
    state = state.copyWith(onboardingCompleted: completed);
  }

  /// Resets all settings to defaults and clears SharedPreferences.
  Future<void> resetAll() async {
    await _prefs.clear();
    state = AppSettings.defaults();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [SettingsNotifier] and exposes [AppSettings] as state.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Convenience provider for the currency symbol.
final currencySymbolProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).currencySymbol,
);

/// Convenience provider for the distance unit.
final distanceUnitProvider = Provider<DistanceUnit>(
  (ref) => ref.watch(settingsProvider).distanceUnit,
);
