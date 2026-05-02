import 'package:intl/intl.dart';

/// Utility for formatting currency and numeric values throughout AutoLog.
abstract final class CurrencyFormatter {
  // ── Currency formatting ────────────────────────────────────────────────────

  /// Formats [amount] with the given [symbol] and 2 decimal places.
  ///
  /// Example: `format(1234.5, '₹')` → `"₹1,234.50"`
  static String format(double amount, String symbol) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats [amount] with no decimal places (for whole-number display).
  ///
  /// Example: `formatWhole(1234.0, '₹')` → `"₹1,234"`
  static String formatWhole(double amount, String symbol) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Formats [amount] compactly for dashboard widgets.
  ///
  /// Values ≥ 1,00,000 are shown as "₹1.2L"; ≥ 1,000 as "₹1.2K".
  static String formatCompact(double amount, String symbol) {
    if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, symbol);
  }

  // ── Numeric formatting ─────────────────────────────────────────────────────

  /// Formats a distance value with 1 decimal place and the unit label.
  ///
  /// Example: `formatDistance(12345.6, 'km')` → `"12,345.6 km"`
  static String formatDistance(double value, String unit) {
    final formatter = NumberFormat('#,##0.0');
    return '${formatter.format(value)} $unit';
  }

  /// Formats a mileage/efficiency value with 2 decimal places.
  ///
  /// Example: `formatMileage(18.5, 'km/L')` → `"18.50 km/L"`
  static String formatMileage(double value, String unit) {
    return '${value.toStringAsFixed(2)} $unit';
  }

  /// Formats a fuel quantity with 2 decimal places and the unit.
  ///
  /// Example: `formatQuantity(40.5, 'L')` → `"40.50 L"`
  static String formatQuantity(double value, String unit) {
    return '${value.toStringAsFixed(2)} $unit';
  }

  /// Formats a plain number with thousand separators.
  static String formatNumber(double value) {
    return NumberFormat('#,##0.##').format(value);
  }
}
