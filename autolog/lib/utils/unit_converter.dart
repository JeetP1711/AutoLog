import '../models/enums.dart';

/// Pure utility for distance unit conversions.
///
/// All methods are static and have no side effects.
abstract final class UnitConverter {
  /// Kilometres per mile (exact NIST definition).
  static const double _kmPerMile = 1.609344;

  // ── Core conversions ───────────────────────────────────────────────────────

  /// Converts [km] to miles.
  static double kmToMiles(double km) => km / _kmPerMile;

  /// Converts [miles] to kilometres.
  static double milesToKm(double miles) => miles * _kmPerMile;

  // ── Generic converter ──────────────────────────────────────────────────────

  /// Converts [value] from [from] to [to].
  ///
  /// Returns [value] unchanged when [from] == [to].
  static double convertDistance(
    double value, {
    required DistanceUnit from,
    required DistanceUnit to,
  }) {
    if (from == to) return value;
    if (from == DistanceUnit.km && to == DistanceUnit.miles) {
      return kmToMiles(value);
    }
    return milesToKm(value);
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  /// Returns the unit label string for [unit].
  static String label(DistanceUnit unit) {
    switch (unit) {
      case DistanceUnit.km:
        return 'km';
      case DistanceUnit.miles:
        return 'mi';
    }
  }
}
