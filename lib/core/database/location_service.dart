import 'package:hive/hive.dart';

/// Service for reading and writing the user's saved delivery location.
///
/// Storage:
///   Box  : "database"
///   Keys : "deliveryLat" (double), "deliveryLng" (double)
///
/// All Hive access is centralised here — UI and pages must not open
/// the box directly for location data.
class LocationService {
  static const String _boxName    = 'database';
  static const String _keyLat     = 'deliveryLat';
  static const String _keyLng     = 'deliveryLng';

  Box get _box => Hive.box(_boxName);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the saved latitude, or null if not yet set.
  double? getSavedLat() => _box.get(_keyLat) as double?;

  /// Returns the saved longitude, or null if not yet set.
  double? getSavedLng() => _box.get(_keyLng) as double?;

  /// Returns true when both lat and lng are persisted.
  bool hasSavedLocation() =>
      getSavedLat() != null && getSavedLng() != null;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Persists [lat] and [lng] to Hive.
  Future<void> saveLocation(double lat, double lng) async {
    await _box.put(_keyLat, lat);
    await _box.put(_keyLng, lng);
  }

  /// Clears the saved delivery location.
  Future<void> clearLocation() async {
    await _box.delete(_keyLat);
    await _box.delete(_keyLng);
  }
}

