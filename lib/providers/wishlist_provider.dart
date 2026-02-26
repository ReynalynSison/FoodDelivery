import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../food/food_data.dart' hide FoodItem, FoodCategory, FoodAddon, Restaurant;

class WishlistProvider extends ChangeNotifier {
  static const String _prefKey = 'wishlist_ids';

  final Set<String> _ids = {};

  WishlistProvider();

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isWished(String id) => _ids.contains(id);

  List<FoodItem> get items =>
      foodMenu.where((f) => _ids.contains(f.id)).toList();

  // ── Load from SharedPreferences ─────────────────────────────────────────
  static Future<WishlistProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    final provider = WishlistProvider();
    provider._ids.addAll(saved);
    return provider;
  }

  // ── Toggle ──────────────────────────────────────────────────────────────
  void toggle(String id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    if (_ids.remove(id)) {
      notifyListeners();
      _persist();
    }
  }

  /// Clears all wishlisted items — called on account reset.
  void clearAll() {
    _ids.clear();
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _ids.toList());
  }
}

