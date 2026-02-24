import 'package:hive/hive.dart';

/// Service for reading and writing the user's saved delivery location.
///
/// Storage:
///   Box  : "database"
///   Keys : "deliveryLat" (double), "deliveryLng" (double),
///          "deliveryAddress" (String)
///
/// All Hive access is centralised here — UI and pages must not open
/// the box directly for location data.
class LocationService {
  static const String _boxName      = 'database';
  static const String _keyLat       = 'deliveryLat';
  static const String _keyLng       = 'deliveryLng';
  static const String _keyAddress   = 'deliveryAddress';

  Box get _box => Hive.box(_boxName);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the saved latitude, or null if not yet set.
  double? getSavedLat() => _box.get(_keyLat) as double?;

  /// Returns the saved longitude, or null if not yet set.
  double? getSavedLng() => _box.get(_keyLng) as double?;

  /// Returns the human-readable address label, or null if not set.
  String? getSavedAddress() => _box.get(_keyAddress) as String?;

  /// Returns true when both lat and lng are persisted.
  bool hasSavedLocation() =>
      getSavedLat() != null && getSavedLng() != null;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Persists [lat], [lng] and optional [address] to Hive.
  Future<void> saveLocation(double lat, double lng, {String? address}) async {
    await _box.put(_keyLat, lat);
    await _box.put(_keyLng, lng);
    if (address != null) await _box.put(_keyAddress, address);
  }

  /// Clears the saved delivery location and address.
  Future<void> clearLocation() async {
    await _box.delete(_keyLat);
    await _box.delete(_keyLng);
    await _box.delete(_keyAddress);
  }
}

