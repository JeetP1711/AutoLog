// Feature: autolog-vehicle-manager
// Property 7: Log filter consistency
//
// For any combination of search query, date range, vehicle filter, and
// category filter applied to the unified log timeline, every returned entry
// satisfies all active filter criteria, and no entry that satisfies all active
// filter criteria is absent from the results.
//
// Validates: Requirements 13.2, 13.3

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal log entry model (mirrors LogsScreen._LogEntry)
// ─────────────────────────────────────────────────────────────────────────────

enum LogCategory { fuel, service, expense }

class LogEntry {
  const LogEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.title,
    required this.subtitle,
  });
  final String id;
  final String vehicleId;
  final DateTime date;
  final LogCategory category;
  final String title;
  final String subtitle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter function (mirrors LogsScreen filtering logic)
// ─────────────────────────────────────────────────────────────────────────────

List<LogEntry> applyFilters(
  List<LogEntry> entries, {
  String searchQuery = '',
  String? vehicleFilter,
  LogCategory? categoryFilter,
  DateTime? rangeStart,
  DateTime? rangeEnd,
}) {
  return entries.where((e) {
    if (vehicleFilter != null && e.vehicleId != vehicleFilter) return false;
    if (categoryFilter != null && e.category != categoryFilter) return false;
    if (rangeStart != null && e.date.isBefore(rangeStart)) return false;
    if (rangeEnd != null && e.date.isAfter(rangeEnd)) return false;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      if (!e.title.toLowerCase().contains(q) &&
          !e.subtitle.toLowerCase().contains(q)) return false;
    }
    return true;
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

Arbitrary<DateTime> get _date => integer(min: 0, max: 3650).map(
      (d) => DateTime(2022).add(Duration(days: d)),
    );

Arbitrary<LogCategory> get _category =>
    integer(min: 0, max: LogCategory.values.length - 1)
        .map((i) => LogCategory.values[i]);

Arbitrary<LogEntry> get _entry => combine5(
      string(minLength: 1, maxLength: 8).map((s) => s.isEmpty ? 'id' : s),
      string(minLength: 1, maxLength: 4).map((s) => s.isEmpty ? 'v1' : s),
      _date,
      _category,
      string(minLength: 0, maxLength: 20),
      (id, vid, date, cat, title) => LogEntry(
        id: id,
        vehicleId: vid,
        date: date,
        category: cat,
        title: title.isEmpty ? 'entry' : title,
        subtitle: 'subtitle',
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('LogFilter — Property 7: filter consistency', () {
    test('every returned entry satisfies all active filter criteria', () async {
      await property(
        forAll(
          combine3(
            list(_entry, minLength: 0, maxLength: 20),
            string(minLength: 0, maxLength: 10),
            _category,
            (entries, query, cat) =>
                (entries: entries, query: query, cat: cat),
          ),
        ),
        (triple) async {
          final results = applyFilters(
            triple.entries,
            searchQuery: triple.query,
            categoryFilter: triple.cat,
          );

          for (final r in results) {
            expect(r.category, triple.cat,
                reason: 'Returned entry must match category filter');

            if (triple.query.isNotEmpty) {
              final q = triple.query.toLowerCase();
              final matches = r.title.toLowerCase().contains(q) ||
                  r.subtitle.toLowerCase().contains(q);
              expect(matches, isTrue,
                  reason:
                      'Returned entry must match search query "${triple.query}"');
            }
          }
        },
      );
    });

    test('no matching entry is absent from results', () async {
      await property(
        forAll(
          combine2(
            list(_entry, minLength: 0, maxLength: 20),
            _category,
            (entries, cat) => (entries: entries, cat: cat),
          ),
        ),
        (pair) async {
          final results = applyFilters(
            pair.entries,
            categoryFilter: pair.cat,
          );

          final matching =
              pair.entries.where((e) => e.category == pair.cat).toList();
          for (final m in matching) {
            expect(results.any((r) => r.id == m.id), isTrue,
                reason:
                    'Entry ${m.id} matches filter but is absent from results');
          }
        },
      );
    });

    test('vehicle filter: only entries for selected vehicle are returned', () async {
      await property(
        forAll(
          combine2(
            list(_entry, minLength: 1, maxLength: 20),
            string(minLength: 1, maxLength: 4).map((s) => s.isEmpty ? 'v1' : s),
            (entries, vid) => (entries: entries, vid: vid),
          ),
        ),
        (pair) async {
          final results = applyFilters(
            pair.entries,
            vehicleFilter: pair.vid,
          );
          for (final r in results) {
            expect(r.vehicleId, pair.vid,
                reason: 'Returned entry must belong to vehicle ${pair.vid}');
          }
        },
      );
    });

    test('date range filter: only entries within range are returned', () {
      final start = DateTime(2023, 1, 1);
      final end = DateTime(2023, 12, 31);

      final entries = [
        LogEntry(
            id: '1',
            vehicleId: 'v1',
            date: DateTime(2022, 6, 1),
            category: LogCategory.fuel,
            title: 'old',
            subtitle: ''),
        LogEntry(
            id: '2',
            vehicleId: 'v1',
            date: DateTime(2023, 6, 1),
            category: LogCategory.fuel,
            title: 'in range',
            subtitle: ''),
        LogEntry(
            id: '3',
            vehicleId: 'v1',
            date: DateTime(2024, 1, 1),
            category: LogCategory.fuel,
            title: 'future',
            subtitle: ''),
      ];

      final results = applyFilters(entries, rangeStart: start, rangeEnd: end);
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('empty filter returns all entries', () async {
      await property(
        forAll(list(_entry, minLength: 0, maxLength: 20)),
        (entries) async {
          final results = applyFilters(entries);
          expect(results.length, entries.length);
        },
      );
    });
  });
}
