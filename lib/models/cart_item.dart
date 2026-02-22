import 'food_item.dart';

/// Represents one line in the cart — a [FoodItem] with quantity,
/// selected add-ons, and optional special instructions.
class CartItem {
  final FoodItem food;
  int quantity;

  /// IDs of the [FoodAddon]s the user selected.
  List<String> selectedAddonIds;

  /// Free-text special instructions entered by the user.
  String specialInstructions;

  CartItem({
    required this.food,
    this.quantity = 1,
    List<String>? selectedAddonIds,
    this.specialInstructions = '',
  }) : selectedAddonIds = selectedAddonIds ?? [];

  // ── Derived helpers ──────────────────────────────────────────────────────

  /// Resolved list of selected [FoodAddon] objects.
  List<FoodAddon> get selectedAddons =>
      food.addons.where((a) => selectedAddonIds.contains(a.id)).toList();

  /// Total extra cost from selected add-ons (NOT multiplied by quantity).
  double get addonTotal =>
      selectedAddons.fold(0.0, (s, a) => s + a.extraPrice);

  /// Unit price INCLUDING add-ons.
  double get unitPrice => food.price + addonTotal;

  /// Line total (unit price × quantity).
  double get lineTotal => unitPrice * quantity;
}

