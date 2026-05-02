import 'package:intl/intl.dart';

/// Utility for formatting [DateTime] values consistently throughout AutoLog.
abstract final class DateFormatter {
  // ── Formatters (created once, reused) ─────────────────────────────────────

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateShort = DateFormat('dd MMM');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _year = DateFormat('yyyy');
  static final DateFormat _iso = DateFormat("yyyy-MM-dd");

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Formats as "15 Jan 2024".
  static String format(DateTime date) => _date.format(date);

  /// Formats as "15 Jan" (no year).
  static String formatShort(DateTime date) => _dateShort.format(date);

  /// Formats as "15 Jan 2024, 02:30 PM".
  static String formatWithTime(DateTime date) => _dateTime.format(date);

  /// Formats as "Jan 2024".
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Formats as "2024".
  static String formatYear(DateTime date) => _year.format(date);

  /// Formats as "2024-01-15" (ISO 8601 date only).
  static String formatIso(DateTime date) => _iso.format(date);

  /// Returns a human-readable relative label such as "Today", "Yesterday",
  /// "3 days ago", or the formatted date for older entries.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return format(date);
  }

  /// Returns the number of days until [date] from today.
  ///
  /// Returns a negative number if [date] is in the past.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  /// Returns a human-readable expiry label such as "Expires in 30 days",
  /// "Expires today", or "Expired 5 days ago".
  static String formatExpiry(DateTime expiryDate) {
    final days = daysUntil(expiryDate);
    if (days > 1) return 'Expires in $days days';
    if (days == 1) return 'Expires tomorrow';
    if (days == 0) return 'Expires today';
    if (days == -1) return 'Expired yesterday';
    return 'Expired ${(-days)} days ago';
  }
}
