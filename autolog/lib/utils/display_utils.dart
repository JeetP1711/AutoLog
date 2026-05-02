import '../models/enums.dart';
import 'unit_converter.dart';

/// Converts a stored km value to the user's preferred display unit.
double displayDistance(double km, DistanceUnit unit) {
  return UnitConverter.convertDistance(km, from: DistanceUnit.km, to: unit);
}

/// Formats a stored km value with the unit label for display.
String formatDistance(double km, DistanceUnit unit) {
  final value = displayDistance(km, unit);
  final label = UnitConverter.label(unit);
  return '${value.toStringAsFixed(1)} $label';
}
