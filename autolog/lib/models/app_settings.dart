import 'package:flutter/material.dart';

import 'enums.dart';

/// Application-wide settings stored in SharedPreferences (not Hive).
///
/// Each field maps to an individual SharedPreferences key for simplicity.
class AppSettings {
  /// Light, dark, or system-default theme.
  final ThemeMode themeMode;

  /// Currency symbol displayed throughout the app (default: ₹).
  final String currencySymbol;

  /// Whether distances are shown in kilometres or miles.
  final DistanceUnit distanceUnit;

  /// Whether the PIN lock screen is enabled.
  final bool pinEnabled;

  /// Whether the user has completed the onboarding flow.
  final bool onboardingCompleted;

  const AppSettings({
    required this.themeMode,
    required this.currencySymbol,
    required this.distanceUnit,
    required this.pinEnabled,
    required this.onboardingCompleted,
  });

  /// Default settings used on first launch.
  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.system,
      currencySymbol: '₹',
      distanceUnit: DistanceUnit.km,
      pinEnabled: false,
      onboardingCompleted: false,
    );
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currencySymbol,
    DistanceUnit? distanceUnit,
    bool? pinEnabled,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'currencySymbol': currencySymbol,
      'distanceUnit': distanceUnit.name,
      'pinEnabled': pinEnabled,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.byName(json['themeMode'] as String),
      currencySymbol: json['currencySymbol'] as String,
      distanceUnit: DistanceUnit.values.byName(json['distanceUnit'] as String),
      pinEnabled: json['pinEnabled'] as bool,
      onboardingCompleted: json['onboardingCompleted'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.currencySymbol == currencySymbol &&
        other.distanceUnit == distanceUnit &&
        other.pinEnabled == pinEnabled &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        currencySymbol,
        distanceUnit,
        pinEnabled,
        onboardingCompleted,
      );

  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, currencySymbol: $currencySymbol, '
        'distanceUnit: $distanceUnit, pinEnabled: $pinEnabled, '
        'onboardingCompleted: $onboardingCompleted)';
  }
}
