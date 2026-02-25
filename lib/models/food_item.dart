/// A single add-on option (e.g. "Extra Cheese +$1.00").
class FoodAddon {
  final String id;
  final String name;
  final double extraPrice;

  const FoodAddon({
    required this.id,
    required this.name,
    required this.extraPrice,
  });
}

/// Food categories used for filtering.
enum FoodCategory { all, meat, pasta, noodles, desserts, bread, drinks }

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;

  // ── Phase 4B additions ──────────────────────────────────────────────────
  final double rating;
  final int reviewCount;

  /// Average kitchen prep time in minutes.
  final int prepTime;

  /// Links to a restaurant in [restaurantData].
  final String restaurantId;

  /// Available add-ons the user can select on the detail page.
  final List<FoodAddon> addons;

  /// Food category for filtering.
  final FoodCategory category;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.prepTime = 15,
    this.restaurantId = 'r1',
    this.addons = const [],
    this.category = FoodCategory.all,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Restaurant data model (used by RestaurantInfoCard)
// ─────────────────────────────────────────────────────────────────────────────

class Restaurant {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;

  /// Distance in km (mocked).
  final double distanceKm;

  /// Whether the restaurant is currently open.
  final bool isOpen;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    this.isOpen = true,
  });

  /// Estimated delivery time in minutes derived from distance.
  int get etaMinutes => (distanceKm * 4 + 10).round();
}