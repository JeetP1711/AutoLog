import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';
const _kDark = 'dark';
const _kLight = 'light';
const _kSystem = 'system';

/// Provides the [SharedPreferences] instance.
///
/// Override this in `main.dart` with the real instance obtained from
/// `SharedPreferences.getInstance()` before the app starts.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a real SharedPreferences instance.',
  ),
);

/// Manages the app-wide [ThemeMode] and persists the user's preference to
/// [SharedPreferences] under the key `"theme_mode"`.
///
/// Default theme is [ThemeMode.dark].
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_readThemeMode(_prefs));

  final SharedPreferences _prefs;

  /// Reads the persisted [ThemeMode] from [prefs], defaulting to [ThemeMode.dark].
  static ThemeMode _readThemeMode(SharedPreferences prefs) {
    final raw = prefs.getString(_kThemeModeKey);
    switch (raw) {
      case _kLight:
        return ThemeMode.light;
      case _kSystem:
        return ThemeMode.system;
      case _kDark:
      default:
        return ThemeMode.dark;
    }
  }

  /// Updates the current [ThemeMode] and persists it to [SharedPreferences].
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, _themeModeName(mode));
  }

  /// Toggles between [ThemeMode.dark] and [ThemeMode.light].
  ///
  /// If the current mode is [ThemeMode.system], switches to [ThemeMode.dark].
  Future<void> toggleTheme() async {
    await setTheme(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  /// Returns a human-readable label for the current [ThemeMode].
  String get themeModeName => _themeModeName(state);

  static String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _kLight;
      case ThemeMode.system:
        return _kSystem;
      case ThemeMode.dark:
        return _kDark;
    }
  }
}

/// Provides the [ThemeController] and exposes the current [ThemeMode] as state.
///
/// Depends on [sharedPreferencesProvider], which must be overridden in
/// `main.dart` before the [ProviderScope] is created.
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(ref.watch(sharedPreferencesProvider)),
);
