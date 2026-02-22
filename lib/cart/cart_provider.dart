import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartProvider extends ChangeNotifier {
  /// One [CartItem] per unique (food + addon combination).
  /// Key = food id for simple add/remove; detail page adds with addons.
  final List<CartItem> _items = [];

  // ── Read ────────────────────────────────────────────────────────────────

  List<CartItem> get cartItems => List.unmodifiable(_items);

  /// Backwards-compat: list of unique [FoodItem]s in cart.
  List<FoodItem> get items => _items.map((e) => e.food).toList();

  /// Total number of individual units.
  int get itemCount => _items.fold(0, (s, e) => s + e.quantity);

  // ── Price ────────────────────────────────────────────────────────────────

  static const double deliveryFee = 2.99;

  double get subtotal => _items.fold(0.0, (s, e) => s + e.lineTotal);

  double get grandTotal => subtotal + deliveryFee;

  /// Legacy alias used by payment flow.
  double get totalPrice => grandTotal;

  // ── Quantity helpers (used by food list / cart steppers) ─────────────────

  /// Returns combined quantity of [item] across all cart lines.
  int quantityOf(FoodItem item) => _items
      .where((e) => e.food.id == item.id)
      .fold(0, (s, e) => s + e.quantity);

  // ── Mutate ───────────────────────────────────────────────────────────────

  /// Quick-add: adds [item] with no addons.
  /// If a plain (no-addon) entry already exists, increments it.
  void addItem(FoodItem item) {
    final idx = _items.indexWhere(
      (e) => e.food.id == item.id && e.selectedAddonIds.isEmpty,
    );
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(food: item));
    }
    notifyListeners();
  }

  /// Quick-remove: decrements the plain (no-addon) entry for [item].
  void removeItem(FoodItem item) {
    final idx = _items.indexWhere(
      (e) => e.food.id == item.id && e.selectedAddonIds.isEmpty,
    );
    if (idx < 0) return;
    if (_items[idx].quantity <= 1) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity--;
    }
    notifyListeners();
  }

  /// Removes ALL lines matching [item] regardless of add-ons.
  void removeItemCompletely(FoodItem item) {
    _items.removeWhere((e) => e.food.id == item.id);
    notifyListeners();
  }

  /// Adds a fully-configured [CartItem] from the detail page.
  /// If an identical line (same food + same addon set) exists, merges qty.
  void addCartItem(CartItem entry) {
    final sortedNew = [...entry.selectedAddonIds]..sort();
    final idx = _items.indexWhere((e) {
      if (e.food.id != entry.food.id) return false;
      final sortedExisting = [...e.selectedAddonIds]..sort();
      return sortedExisting.join(',') == sortedNew.join(',');
    });
    if (idx >= 0) {
      _items[idx].quantity += entry.quantity;
    } else {
      _items.add(entry);
    }
    notifyListeners();
  }

  /// Updates qty on a specific [CartItem] by index. Removes if qty reaches 0.
  void updateCartItemQuantity(int index, int newQty) {
    if (index < 0 || index >= _items.length) return;
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = newQty;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
