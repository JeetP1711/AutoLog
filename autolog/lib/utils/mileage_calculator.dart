import '../models/enums.dart';

/// Pure utility for mileage and distance calculations.
///
/// All methods are static and have no side effects, making them easy to test
/// and safe to call from any layer.
abstract final class MileageCalculator {
  // ── Distance ───────────────────────────────────────────────────────────────

  /// Returns the distance between two odometer readings in kilometres.
  ///
  /// Returns `null` if [current] is not strictly greater than [previous]
  /// (handles odometer resets and data-entry errors gracefully).
  static double? distance(double current, double previous) {
    final d = current - previous;
    return d > 0 ? d : null;
  }

  // ── Mileage ────────────────────────────────────────────────────────────────

  /// Calculates fuel efficiency for the given [fuelType].
  ///
  /// Returns:
  /// - km/litre  for [FuelType.petrol], [FuelType.diesel], [FuelType.lpg],
  ///             and [FuelType.hybrid]
  /// - km/kg     for [FuelType.cng] and [FuelType.hydrogen]
  /// - km/kWh    for [FuelType.electric]
  /// - km/unit   for [FuelType.custom] (unit label is managed by the caller)
  ///
  /// Returns `null` if:
  /// - [distanceKm] is null, zero, or negative
  /// - [quantity] is zero or negative
  static double? calculate({
    required double? distanceKm,
    required double quantity,
    required FuelType fuelType,
  }) {
    if (distanceKm == null || distanceKm <= 0) return null;
    if (quantity <= 0) return null;

    // All supported fuel types use the same formula: distance / quantity.
    // The unit label (km/litre, km/kg, km/kWh) is determined by the caller
    // based on the fuel type.
    return distanceKm / quantity;
  }

  // ── Unit label helpers ─────────────────────────────────────────────────────

  /// Returns the human-readable efficiency unit for [fuelType].
  ///
  /// Examples: "km/L", "km/kg", "km/kWh".
  static String efficiencyUnit(FuelType fuelType, {String? customUnit}) {
    switch (fuelType) {
      case FuelType.petrol:
      case FuelType.diesel:
      case FuelType.lpg:
      case FuelType.hybrid:
        return 'km/L';
      case FuelType.cng:
      case FuelType.hydrogen:
        return 'km/kg';
      case FuelType.electric:
        return 'km/kWh';
      case FuelType.custom:
        return customUnit != null ? 'km/$customUnit' : 'km/unit';
    }
  }

  /// Returns the human-readable quantity unit for [fuelType].
  ///
  /// Examples: "L", "kg", "kWh".
  static String quantityUnit(FuelType fuelType, {String? customUnit}) {
    switch (fuelType) {
      case FuelType.petrol:
      case FuelType.diesel:
      case FuelType.lpg:
      case FuelType.hybrid:
        return 'L';
      case FuelType.cng:
      case FuelType.hydrogen:
        return 'kg';
      case FuelType.electric:
        return 'kWh';
      case FuelType.custom:
        return customUnit ?? 'unit';
    }
  }
}
