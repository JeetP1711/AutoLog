import '../models/enums.dart';

/// Pure utility for mileage and distance calculations.
abstract final class MileageCalculator {
  // ── Distance ───────────────────────────────────────────────────────────────

  static double? distance(double current, double previous) {
    final d = current - previous;
    return d > 0 ? d : null;
  }

  // ── Mileage ────────────────────────────────────────────────────────────────

  static double? calculate({
    required double? distanceKm,
    required double quantity,
    required FuelType fuelType,
  }) {
    if (distanceKm == null || distanceKm <= 0) return null;
    if (quantity <= 0) return null;
    return distanceKm / quantity;
  }

  // ── Unit label helpers ─────────────────────────────────────────────────────

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
      case FuelType.petrolCng:
        return 'km/L or km/kg';
      case FuelType.custom:
        return customUnit != null ? 'km/$customUnit' : 'km/unit';
    }
  }

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
      case FuelType.petrolCng:
        return 'L / kg';
      case FuelType.custom:
        return customUnit ?? 'unit';
    }
  }
}
