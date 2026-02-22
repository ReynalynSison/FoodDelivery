import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide brightness (light / dark).
///
/// Persists the user's choice to [SharedPreferences] under the key
/// [_prefKey] so it survives app restarts without flicker.
///
/// Usage:
///   context.watch<ThemeProvider>().brightness  → current Brightness
///   context.read<ThemeProvider>().toggleTheme() → flip light ↔ dark
///   context.read<ThemeProvider>().setTheme(b)  → set explicit brightness
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_brightness';

  Brightness _brightness;

  ThemeProvider(this._brightness);

  // ── Public getters ────────────────────────────────────────────────────────

  /// Current brightness value.
  Brightness get brightness => _brightness;

  /// Convenience: true when dark mode is active.
  bool get isDark => _brightness == Brightness.dark;

  // ── Factory: load persisted value before first frame ─────────────────────

  /// Creates a [ThemeProvider] with the last-saved brightness.
  /// Falls back to [Brightness.light] when nothing is stored.
  static Future<ThemeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    final brightness =
        stored == 'dark' ? Brightness.dark : Brightness.light;
    return ThemeProvider(brightness);
  }

  // ── Mutation ──────────────────────────────────────────────────────────────

  /// Flips between light and dark and persists the result.
  void toggleTheme() =>
      setTheme(_brightness == Brightness.light ? Brightness.dark : Brightness.light);

  /// Explicitly sets [brightness] and persists it.
  Future<void> setTheme(Brightness brightness) async {
    if (_brightness == brightness) return;
    _brightness = brightness;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, brightness == Brightness.dark ? 'dark' : 'light');
  }
}

