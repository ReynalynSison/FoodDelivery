import '../models/food_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Restaurant catalogue
// ─────────────────────────────────────────────────────────────────────────────

const List<Restaurant> restaurantData = [
  Restaurant(
    id: 'r1',
    name: 'Sakura Japanese Kitchen',
    rating: 4.8,
    reviewCount: 312,
    distanceKm: 1.4,
    isOpen: true,
  ),
  Restaurant(
    id: 'r2',
    name: 'Matcha & More',
    rating: 4.6,
    reviewCount: 187,
    distanceKm: 2.1,
    isOpen: true,
  ),
];

/// Returns the [Restaurant] matching [id], or null if not found.
Restaurant? restaurantById(String id) {
  try {
    return restaurantData.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food menu
// ─────────────────────────────────────────────────────────────────────────────

const List<FoodItem> foodMenu = [
  FoodItem(
    id: '1',
    name: 'Sushi Set',
    description: 'Fresh salmon and tuna rolls with pickled ginger and wasabi.',
    price: 12.50,
    imagePath: 'assets/images/sushi.png',
    rating: 4.9,
    reviewCount: 204,
    prepTime: 10,
    restaurantId: 'r1',
    addons: [
      FoodAddon(id: 'a1', name: 'Extra Wasabi', extraPrice: 0.50),
      FoodAddon(id: 'a2', name: 'Spicy Mayo', extraPrice: 0.75),
      FoodAddon(id: 'a3', name: 'Edamame Side', extraPrice: 1.50),
    ],
  ),
  FoodItem(
    id: '2',
    name: 'Ramen Bowl',
    description: 'Rich tonkotsu broth with chashu pork, soft egg and nori.',
    price: 10.00,
    imagePath: 'assets/images/ramen.png',
    rating: 4.7,
    reviewCount: 178,
    prepTime: 12,
    restaurantId: 'r1',
    addons: [
      FoodAddon(id: 'b1', name: 'Extra Chashu', extraPrice: 2.00),
      FoodAddon(id: 'b2', name: 'Soft-boiled Egg', extraPrice: 1.00),
      FoodAddon(id: 'b3', name: 'Corn Topping', extraPrice: 0.75),
    ],
  ),
  FoodItem(
    id: '3',
    name: 'Bento Box',
    description: 'Chicken teriyaki with steamed rice, gyoza and miso soup.',
    price: 11.25,
    imagePath: 'assets/images/bento.png',
    rating: 4.6,
    reviewCount: 145,
    prepTime: 15,
    restaurantId: 'r1',
    addons: [
      FoodAddon(id: 'c1', name: 'Upgrade to Brown Rice', extraPrice: 0.50),
      FoodAddon(id: 'c2', name: 'Add California Roll', extraPrice: 3.00),
      FoodAddon(id: 'c3', name: 'Extra Sauce', extraPrice: 0.25),
    ],
  ),
  FoodItem(
    id: '4',
    name: 'Gyoza',
    description: 'Crispy pan-fried pork dumplings served with ponzu dip.',
    price: 6.75,
    imagePath: 'assets/images/gyoza.png',
    rating: 4.5,
    reviewCount: 92,
    prepTime: 8,
    restaurantId: 'r1',
    addons: [
      FoodAddon(id: 'd1', name: 'Extra Dipping Sauce', extraPrice: 0.50),
      FoodAddon(id: 'd2', name: 'Add 3 More Pieces', extraPrice: 2.25),
    ],
  ),
  FoodItem(
    id: '5',
    name: 'Matcha Latte',
    description: 'Ceremonial-grade matcha blended with oat milk and honey.',
    price: 4.50,
    imagePath: 'assets/images/matcha.png',
    rating: 4.8,
    reviewCount: 231,
    prepTime: 5,
    restaurantId: 'r2',
    addons: [
      FoodAddon(id: 'e1', name: 'Extra Shot', extraPrice: 0.75),
      FoodAddon(id: 'e2', name: 'Oat Milk Upgrade', extraPrice: 0.50),
      FoodAddon(id: 'e3', name: 'Add Boba Pearls', extraPrice: 1.00),
    ],
  ),
  FoodItem(
    id: '6',
    name: 'Mochi Trio',
    description: 'Assorted sweet rice cakes: strawberry, matcha, and mango.',
    price: 5.25,
    imagePath: 'assets/images/mochi.png',
    rating: 4.7,
    reviewCount: 119,
    prepTime: 5,
    restaurantId: 'r2',
    addons: [
      FoodAddon(id: 'f1', name: 'Add 2 Extra Pieces', extraPrice: 1.50),
      FoodAddon(id: 'f2', name: 'Gift Wrap', extraPrice: 0.50),
    ],
  ),
];
