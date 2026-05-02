import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads and caches the offline vehicle brand/model/year database from the
/// bundled JSON asset `assets/data/vehicle_database.json`.
///
/// Call [load] once at app startup. All subsequent calls to [getBrands],
/// [getModels], and [getYears] are synchronous and require no network access.
class VehicleDatabase {
  VehicleDatabase._();

  static final VehicleDatabase instance = VehicleDatabase._();

  // Internal cache: brand → model → years
  final Map<String, Map<String, List<int>>> _data = {};
  bool _loaded = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads the JSON asset into memory. Safe to call multiple times — subsequent
  /// calls are no-ops if the data is already loaded.
  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/data/vehicle_database.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final brands = json['brands'] as List<dynamic>;

    for (final brandEntry in brands) {
      final brandMap = brandEntry as Map<String, dynamic>;
      final brandName = brandMap['name'] as String;
      final models = brandMap['models'] as List<dynamic>;

      _data[brandName] = {};
      for (final modelEntry in models) {
        final modelMap = modelEntry as Map<String, dynamic>;
        final modelName = modelMap['name'] as String;
        final years = (modelMap['years'] as List<dynamic>)
            .map((y) => y as int)
            .toList();
        _data[brandName]![modelName] = years;
      }
    }

    _loaded = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the ordered list of brand names.
  ///
  /// Throws a [StateError] if [load] has not been called yet.
  List<String> getBrands() {
    _assertLoaded();
    return _data.keys.toList();
  }

  /// Returns the list of model names for [brand].
  ///
  /// Returns an empty list if [brand] is not found.
  List<String> getModels(String brand) {
    _assertLoaded();
    return _data[brand]?.keys.toList() ?? [];
  }

  /// Returns the list of available years for [brand] + [model].
  ///
  /// Returns an empty list if the combination is not found.
  List<int> getYears(String brand, String model) {
    _assertLoaded();
    return _data[brand]?[model] ?? [];
  }

  /// Returns true if the database has been loaded.
  bool get isLoaded => _loaded;

  void _assertLoaded() {
    if (!_loaded) {
      throw StateError(
        'VehicleDatabase has not been loaded. Call VehicleDatabase.instance.load() first.',
      );
    }
  }
}
