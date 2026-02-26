import '../models/food_item.dart'
    show FoodCategory, FoodAddon, Restaurant, FoodItem;
// ignore_for_file: prefer_const_constructors


// Meat addons
const _meatAddons = [
  FoodAddon(id: 'meat_1', name: 'Sauce',          extraPrice: 15),
  FoodAddon(id: 'meat_2', name: 'Mashed Potato',  extraPrice: 35),
  FoodAddon(id: 'meat_3', name: 'Garlic Butter Dip', extraPrice: 20),
];

// Pasta addons
const _pastaAddons = [
  FoodAddon(id: 'pasta_1', name: 'Sauce',            extraPrice: 15),
  FoodAddon(id: 'pasta_2', name: 'Meat',             extraPrice: 50),
  FoodAddon(id: 'pasta_3', name: 'Pasta',            extraPrice: 30),
];

// Noodles addons
const _noodlesAddons = [
  FoodAddon(id: 'noodle_1', name: 'Egg',           extraPrice: 15),
  FoodAddon(id: 'noodle_2', name: 'Dumplings',     extraPrice: 40),
  FoodAddon(id: 'noodle_3', name: 'Vegetables',    extraPrice: 20),
  FoodAddon(id: 'noodle_4', name: 'Extra Noodles', extraPrice: 25),
];

// Drinks addons
const _drinksAddons = [
  FoodAddon(id: 'drink_1', name: 'Lemon Slice',   extraPrice: 10),
  FoodAddon(id: 'drink_2', name: 'Whipped Cream', extraPrice: 20),
  FoodAddon(id: 'drink_3', name: 'Pearl',         extraPrice: 25),
];

// Desserts addons
const _dessertsAddons = [
  FoodAddon(id: 'sweet_1', name: 'Vanilla Ice Cream', extraPrice: 35),
  FoodAddon(id: 'sweet_2', name: 'Fruits',            extraPrice: 25),
  FoodAddon(id: 'sweet_3', name: 'Melted Chocolate',  extraPrice: 20),
];

// Bread addons
const _breadAddons = [
  FoodAddon(id: 'bread_1', name: 'Sauce',      extraPrice: 15),
  FoodAddon(id: 'bread_2', name: 'Add Butter', extraPrice: 10),
  FoodAddon(id: 'bread_3', name: 'Add Jam',    extraPrice: 15),
];

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Restaurant catalogue
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const List<Restaurant> restaurantData = [
  Restaurant(id: 'r1', name: 'Food Tiger', rating: 4.8, reviewCount: 312, distanceKm: 1.4, isOpen: true),
  Restaurant(id: 'r2', name: 'Food Tiger', rating: 4.6, reviewCount: 187, distanceKm: 2.1, isOpen: true),
  Restaurant(id: 'r3', name: 'Food Tiger', rating: 4.7, reviewCount: 265, distanceKm: 1.8, isOpen: true),
  Restaurant(id: 'r4', name: 'Food Tiger', rating: 4.5, reviewCount: 143, distanceKm: 2.5, isOpen: true),
];

Restaurant? restaurantById(String id) {
  try { return restaurantData.firstWhere((r) => r.id == id); } catch (_) { return null; }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Food menu
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const List<FoodItem> foodMenu = [
  // â”€â”€ MEATS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '1', name: 'Grilled Salmon Salad',
    description: 'Fresh salmon and tuna rolls with pickled ginger and wasabi.',
    price: 350, imagePath: 'https://i.pinimg.com/1200x/8e/5b/a7/8e5ba7ec864dcd8d4c2b7183b50e18cd.jpg',
    rating: 4.9, reviewCount: 204, prepTime: 10, restaurantId: 'r1',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '2', name: 'Grilled Chicken Breast with Vegetables',
    description: 'Tender grilled pork with a smoky marinade and side of garlic rice.',
    price: 320, imagePath: 'https://i.pinimg.com/1200x/1b/94/9f/1b949f83be480e80096ddb0a21be52ac.jpg',
    rating: 4.7, reviewCount: 178, prepTime: 15, restaurantId: 'r1',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '3', name: 'Slice Steak with Chimichurri',
    description: 'Slow-cooked baby back ribs glazed with smoky barbecue sauce.',
    price: 480, imagePath: 'https://i.pinimg.com/736x/8b/5a/37/8b5a3725e540b5423b469811df0ec597.jpg',
    rating: 4.8, reviewCount: 245, prepTime: 20, restaurantId: 'r1',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '4', name: 'Roasted Lamb Chop',
    description: 'Juicy sirloin steak cooked to perfection with herb butter.',
    price: 550, imagePath: 'https://i.pinimg.com/736x/c4/ba/49/c4ba49f5cbcd5a50b47534e3093eeb2d.jpg',
    rating: 4.9, reviewCount: 310, prepTime: 18, restaurantId: 'r2',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '5', name: 'Beef Fillet with Sweet Potato Puree',
    description: 'Whole roasted chicken seasoned with herbs and lemon.',
    price: 395, imagePath: 'https://i.pinimg.com/1200x/b2/fc/eb/b2fceb25cd9bbd7928a978c5c8d6aeea.jpg',
    rating: 4.6, reviewCount: 192, prepTime: 25, restaurantId: 'r2',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '6', name: 'Roasted Duck with Orange and Plum',
    description: 'Tender lamb chops marinated in rosemary and garlic, grilled to perfection.',
    price: 520, imagePath: 'https://i.pinimg.com/1200x/d7/2a/df/d72adf3a3c391b210b65987f270fe944.jpg',
    rating: 4.7, reviewCount: 163, prepTime: 20, restaurantId: 'r2',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '7', name: 'Pan Seared Roasted Glazed Ribs',
    description: 'Crispy buffalo wings tossed in tangy hot sauce, served with ranch.',
    price: 275, imagePath: 'https://i.pinimg.com/736x/3e/20/34/3e20340fca981ba9d8a09c7cdf2878fa.jpg',
    rating: 4.6, reviewCount: 278, prepTime: 16, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '8', name: 'Sliced Filet Mignon with Mash',
    description: 'Juicy 200g beef patty with cheddar, lettuce, tomato and pickles.',
    price: 375, imagePath: 'https://i.pinimg.com/736x/3a/c3/55/3ac355047e36a77776ea71ceec7a35ac.jpg',
    rating: 4.6, reviewCount: 302, prepTime: 12, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '9', name: 'Glazed Chicken Breast with Greens',
    description: 'Atlantic salmon fillet grilled with lemon butter and herbs.',
    price: 480, imagePath: 'https://i.pinimg.com/1200x/68/68/fa/6868fae65711e14f5af529a602c65b08.jpg',
    rating: 4.8, reviewCount: 189, prepTime: 18, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '10', name: 'Lemon Pepper Chicken Wings',
    description: 'Crispy-skinned pork belly with a melt-in-your-mouth tender center.',
    price: 420, imagePath: 'https://i.pinimg.com/1200x/4b/47/f2/4b47f22041fe1f5106efc80e38019e40.jpg',
    rating: 4.7, reviewCount: 215, prepTime: 22, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '11', name: 'Grilled Buffalo Wings',
    description: 'Street-style tacos with marinated pork, pineapple, cilantro and onion.',
    price: 295, imagePath: 'https://i.pinimg.com/736x/bc/9b/52/bc9b52672394ad52225f65630f67514f.jpg',
    rating: 4.8, reviewCount: 259, prepTime: 10, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '12', name: 'BBQ Chicken Drumsticks',
    description: 'Slow-cooked duck leg with crispy skin served with roasted potatoes.',
    price: 510, imagePath: 'https://i.pinimg.com/736x/d5/1b/56/d51b562aaec73c76cacedd2a572830ee.jpg',
    rating: 4.8, reviewCount: 174, prepTime: 25, restaurantId: 'r4',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '13', name: 'Whole Roasted Chicken with Root Vegetables',
    description: 'Chicken teriyaki with steamed rice, gyoza and miso soup.',
    price: 320, imagePath: 'https://i.pinimg.com/1200x/03/5d/53/035d53740b79bf186458360f8a479afe.jpg',
    rating: 4.6, reviewCount: 145, prepTime: 15, restaurantId: 'r4',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '14', name: 'Roasted Chichken Leg',
    description: 'Korean rice bowl with seasoned vegetables, beef bulgogi and gochujang.',
    price: 340, imagePath: 'https://i.pinimg.com/1200x/7a/51/00/7a510004ec1e265c10954a11584af9e3.jpg',
    rating: 4.7, reviewCount: 167, prepTime: 15, restaurantId: 'r4',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '15', name: 'Braised Short Ribs with Corn',
    description: 'Crispy pan-fried pork dumplings served with ponzu dip.',
    price: 195, imagePath: 'https://i.pinimg.com/736x/32/da/a5/32daa52da70d309ac98c95170f042fda.jpg',
    rating: 4.5, reviewCount: 92, prepTime: 8, restaurantId: 'r1',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '16', name: 'Shawarma Plate',
    description: 'Seasoned shawarma meat served with pita, garlic sauce and pickles.',
    price: 285, imagePath: 'https://i.pinimg.com/736x/69/8d/ff/698dfff716f70208f852ebd5d743e078.jpg',
    rating: 4.6, reviewCount: 231, prepTime: 12, restaurantId: 'r1',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '17', name: 'Grilled Tuna',
    description: 'Fresh tuna steak grilled with soy glaze and sesame seeds.',
    price: 465, imagePath: 'https://i.pinimg.com/1200x/6b/21/80/6b21806601d05b16b70eb8c3c7722f9e.jpg',
    rating: 4.7, reviewCount: 138, prepTime: 14, restaurantId: 'r2',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '18', name: 'Slow cooked Pot Roast',
    description: 'Fall-off-the-bone pork ribs with sweet and spicy glaze.',
    price: 490, imagePath: 'https://i.pinimg.com/736x/23/35/eb/2335eb8f2366f1e7bcf57447112a35d7.jpg',
    rating: 4.8, reviewCount: 299, prepTime: 25, restaurantId: 'r2',
    category: FoodCategory.meat, addons: _meatAddons,
  ),
  FoodItem(
    id: '19', name: 'BBQ Pork Ribs',
    description: 'Filipino-style grilled chicken marinated in calamansi and annatto.',
    price: 310, imagePath: 'https://i.pinimg.com/1200x/eb/1d/19/eb1d19d7e4774f4549a43e37beced9d5.jpg',
    rating: 4.7, reviewCount: 182, prepTime: 18, restaurantId: 'r3',
    category: FoodCategory.meat, addons: _meatAddons,
  ),

  // â”€â”€ PASTA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '20', name: 'Penne Arrabbiata',
    description: 'Al dente spaghetti with crispy pancetta, egg yolk and pecorino.',
    price: 395, imagePath: 'https://i.pinimg.com/736x/50/33/7a/50337a274b4fcc96703efeda1e3d76f6.jpg',
    rating: 4.7, reviewCount: 211, prepTime: 14, restaurantId: 'r4',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '21', name: 'Spaghetti Pomodoro',
    description: 'Classic meat sauce slow-cooked with tomatoes and red wine over tagliatelle.',
    price: 380, imagePath: 'https://i.pinimg.com/736x/1e/bd/59/1ebd59d232fc2c0ff4f66e225dc5aba3.jpg',
    rating: 4.6, reviewCount: 198, prepTime: 16, restaurantId: 'r4',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '22', name: 'Vegetable Pasta',
    description: 'Fresh basil pesto tossed with fusilli, pine nuts and parmesan.',
    price: 360, imagePath: 'https://i.pinimg.com/736x/02/51/b4/0251b4e10700b7e2465b31a349a85740.jpg',
    rating: 4.7, reviewCount: 175, prepTime: 12, restaurantId: 'r4',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '23', name: 'Spaghetti with Olives and Tomatoes',
    description: 'Spicy tomato and garlic sauce with penne and fresh parsley.',
    price: 340, imagePath: 'https://i.pinimg.com/1200x/d4/4d/b6/d44db664d238074ae5f92e50185999c6.jpg',
    rating: 4.5, reviewCount: 143, prepTime: 13, restaurantId: 'r1',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '24', name: 'Spaghetti Bolognese',
    description: 'Layered pasta with rich meat sauce, bÃ©chamel and melted mozzarella.',
    price: 420, imagePath: 'https://i.pinimg.com/736x/11/94/4c/11944c1bd2ccc49fbd198122405afa01.jpg',
    rating: 4.8, reviewCount: 267, prepTime: 20, restaurantId: 'r1',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '25', name: 'Shrimp Scampi Linguine',
    description: 'Simple yet elegant spaghetti with garlic-infused olive oil and chili.',
    price: 320, imagePath: 'https://i.pinimg.com/1200x/19/9f/28/199f28e89a26c611d3aed0c40a148641.jpg',
    rating: 4.6, reviewCount: 154, prepTime: 11, restaurantId: 'r2',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '26', name: 'Tomato Basil Fettuccine',
    description: 'Linguine with shrimp, clams, mussels in a white wine tomato sauce.',
    price: 450, imagePath: 'https://i.pinimg.com/736x/86/08/65/860865b7fd1911fd7f0461c6bf89bf72.jpg',
    rating: 4.8, reviewCount: 219, prepTime: 18, restaurantId: 'r2',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '27', name: 'Herb Infused Linguine',
    description: 'Creamy mushroom and truffle oil pasta topped with shaved parmesan.',
    price: 370, imagePath: 'https://i.pinimg.com/1200x/5d/ba/b3/5dbab3eb01783e989ae9878edcf0f2a3.jpg',
    rating: 4.7, reviewCount: 188, prepTime: 14, restaurantId: 'r3',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '28', name: 'Classic Spaghetti Marinara',
    description: 'Ziti pasta baked with ricotta, mozzarella and chunky tomato sauce.',
    price: 400, imagePath: 'https://i.pinimg.com/1200x/29/36/83/293683c7c147f11cb1401747c9d01825.jpg',
    rating: 4.6, reviewCount: 162, prepTime: 22, restaurantId: 'r3',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),
  FoodItem(
    id: '29', name: 'Burrata and Blistered Tomato Pasta',
    description: 'Roman classic â€” pecorino, black pepper and perfectly cooked tonnarelli.',
    price: 345, imagePath: 'https://i.pinimg.com/736x/fa/df/09/fadf0902be62e7507a3fb6c76d28f40b.jpg',
    rating: 4.7, reviewCount: 177, prepTime: 12, restaurantId: 'r4',
    category: FoodCategory.pasta, addons: _pastaAddons,
  ),

  // â”€â”€ BREAD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '30', name: 'Butter Croissant',
    description: 'Buttery, flaky all-butter croissant baked fresh every morning.',
    price: 95, imagePath: 'https://i.pinimg.com/736x/15/03/a9/1503a9dc547f5b169613f2f046c941df.jpg',
    rating: 4.6, reviewCount: 98, prepTime: 3, restaurantId: 'r2',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '31', name: 'Toasted Country Bread',
    description: 'New York-style baked cheesecake with fresh berry compote.',
    price: 190, imagePath: 'https://i.pinimg.com/1200x/30/4c/4b/304c4b5f51abefd0dd0b36c135c224a5.jpg',
    rating: 4.8, reviewCount: 222, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '32', name: 'Chocolate Babka Slices',
    description: 'Artisan sourdough with a crispy crust and chewy open crumb.',
    price: 145, imagePath: 'https://i.pinimg.com/1200x/fc/a6/e0/fca6e0002b825f3afb4e586f000a03a3.jpg',
    rating: 4.7, reviewCount: 134, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '33', name: 'Braised Cinnamon Swiri',
    description: 'Toasted baguette loaded with garlic butter and fresh herbs.',
    price: 85, imagePath: 'https://i.pinimg.com/1200x/19/fa/82/19fa826d66710b2134f34b755a673157.jpg',
    rating: 4.5, reviewCount: 201, prepTime: 5, restaurantId: 'r1',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '34', name: 'Butter Croissants',
    description: 'Italian flatbread drizzled with olive oil, rosemary and sea salt.',
    price: 120, imagePath: 'https://i.pinimg.com/1200x/a9/eb/42/a9eb42c98551f0729cd2264a334160f3.jpg',
    rating: 4.6, reviewCount: 116, prepTime: 6, restaurantId: 'r1',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '35', name: 'Chocolate Tart',
    description: 'Sourdough toast topped with smashed avocado, poached egg and chili flakes.',
    price: 260, imagePath: 'https://i.pinimg.com/1200x/62/aa/51/62aa519f6621c5f38f05e8ddf3aa30f2.jpg',
    rating: 4.5, reviewCount: 134, prepTime: 8, restaurantId: 'r3',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '36', name: 'Chocolate Mousse',
    description: 'Grilled ciabatta filled with prosciutto, mozzarella and basil pesto.',
    price: 215, imagePath: 'https://i.pinimg.com/736x/5d/63/4e/5d634ec7647f7b95a36ebfa3d9d00106.jpg',
    rating: 4.6, reviewCount: 147, prepTime: 8, restaurantId: 'r3',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '37', name: 'Almond Croissant',
    description: 'Soft, golden brioche bun with a hint of sweetness, perfect on its own.',
    price: 90, imagePath: 'https://i.pinimg.com/1200x/d9/99/80/d9998064ae35b8ba9480a684f0edaa8e.jpg',
    rating: 4.5, reviewCount: 88, prepTime: 3, restaurantId: 'r4',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '38', name: 'Glazed Cruffins',
    description: 'Soft swirled roll with cinnamon sugar filling and cream cheese glaze.',
    price: 110, imagePath: 'https://i.pinimg.com/1200x/cd/7a/42/cd7a42d32c789a10a0f86778a21685c4.jpg',
    rating: 4.8, reviewCount: 256, prepTime: 5, restaurantId: 'r4',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '39', name: 'Mini Chocolate Babka',
    description: 'Soft baked pretzel with coarse salt, served with mustard dipping sauce.',
    price: 95, imagePath: 'https://i.pinimg.com/736x/d6/c7/f8/d6c7f889167a3deb1fee51a4653217bc.jpg',
    rating: 4.4, reviewCount: 102, prepTime: 4, restaurantId: 'r2',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '40', name: 'Chocolate Braided Pastry',
    description: 'Classic New York bagel with cream cheese and smoked salmon.',
    price: 165, imagePath: 'https://i.pinimg.com/736x/73/fb/e2/73fbe2358035bf478f15080afc1a57c9.jpg',
    rating: 4.5, reviewCount: 119, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.bread, addons: _breadAddons,
  ),
  FoodItem(
    id: '41', name: 'Basket of Croissants',
    description: 'Classic Neapolitan pizza with San Marzano tomato and fresh mozzarella.',
    price: 420, imagePath: 'https://i.pinimg.com/736x/5b/31/80/5b31801bff603266089782ca93f07b6f.jpg',
    rating: 4.8, reviewCount: 344, prepTime: 20, restaurantId: 'r4',
    category: FoodCategory.bread, addons: _breadAddons,
  ),

  // â”€â”€ SWEETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '42', name: 'Mochi Trio',
    description: 'Assorted sweet rice cakes: strawberry, matcha, and mango.',
    price: 150, imagePath: 'https://i.pinimg.com/736x/4f/33/75/4f3375cbc835f90c9c2fd93b4413a398.jpg',
    rating: 4.7, reviewCount: 119, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '43', name: 'Raspberry Chocolate Cake',
    description: 'Warm dark chocolate cake with a gooey molten centre and vanilla ice cream.',
    price: 200, imagePath: 'https://i.pinimg.com/736x/90/28/e2/9028e299b9fbf7638a4d73c6b47ac5ec.jpg',
    rating: 4.9, reviewCount: 312, prepTime: 12, restaurantId: 'r4',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '44', name: 'Chocolate Toffee Tart',
    description: 'Classic Italian dessert with mascarpone cream and espresso-soaked ladyfingers.',
    price: 220, imagePath: 'https://i.pinimg.com/1200x/5c/a7/b6/5ca7b6ae976e011304526ec3c5e8ca0f.jpg',
    rating: 4.9, reviewCount: 156, prepTime: 5, restaurantId: 'r4',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '45', name: 'Chocolate Ganache Mousse',
    description: 'Silky vanilla custard topped with a perfectly caramelized sugar crust.',
    price: 195, imagePath: 'https://i.pinimg.com/1200x/dc/15/8b/dc158b826add4d1bc086ae46a5033cdf.jpg',
    rating: 4.8, reviewCount: 201, prepTime: 8, restaurantId: 'r3',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '46', name: 'Belgian Waffle with Syrup',
    description: 'Assorted French macarons in rose, pistachio, chocolate and lemon.',
    price: 180, imagePath: 'https://i.pinimg.com/1200x/54/51/8f/54518f3756d113975f9d937305c6fa8c.jpg',
    rating: 4.7, reviewCount: 143, prepTime: 3, restaurantId: 'r3',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '47', name: 'Berry and Pomegranate Bowl',
    description: 'Three scoops of ice cream with hot fudge, whipped cream and a cherry.',
    price: 165, imagePath: 'https://i.pinimg.com/1200x/c2/5c/18/c25c188f33d786c8108173f07dcb9064.jpg',
    rating: 4.6, reviewCount: 177, prepTime: 4, restaurantId: 'r1',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '48', name: 'Ink Octuper Pastry',
    description: 'Fluffy buttermilk pancakes stacked high with maple syrup and berries.',
    price: 210, imagePath: 'https://i.pinimg.com/736x/d1/a8/51/d1a851068d02da393869978308650132.jpg',
    rating: 4.8, reviewCount: 265, prepTime: 10, restaurantId: 'r1',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '49', name: 'Chocolate Bundt Cake',
    description: 'Golden fried dough dusted with cinnamon sugar, served with chocolate dip.',
    price: 155, imagePath: 'https://i.pinimg.com/1200x/08/8b/e2/088be239b521b4757295ad0b6937e855.jpg',
    rating: 4.7, reviewCount: 188, prepTime: 8, restaurantId: 'r2',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),
  FoodItem(
    id: '50', name: 'Sliced Chocolate Bundt Cake',
    description: 'Crispy Belgian waffles topped with fresh strawberries and whipped cream.',
    price: 185, imagePath: 'https://i.pinimg.com/1200x/9b/74/54/9b745489e1ae751469af1b76efa3b46a.jpg',
    rating: 4.7, reviewCount: 234, prepTime: 9, restaurantId: 'r2',
    category: FoodCategory.desserts, addons: _dessertsAddons,
  ),

  // â”€â”€ DRINKS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '51', name: 'Clear Cocktail with Lime',
    description: 'Ceremonial-grade matcha blended with oat milk and honey.',
    price: 130, imagePath: 'https://i.pinimg.com/736x/fd/ee/ca/fdeeca06ca37f8b0d45bb21fa73be5ae.jpg',
    rating: 4.8, reviewCount: 231, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '52', name: 'Classic Mojito',
    description: 'Smooth 24-hour steeped cold brew served over ice with a splash of milk.',
    price: 120, imagePath: 'https://i.pinimg.com/1200x/1a/0f/2d/1a0f2d5e1359aae710b669991a9eb949.jpg',
    rating: 4.7, reviewCount: 198, prepTime: 3, restaurantId: 'r3',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '53', name: 'Watermelon Rosemary Sprintz',
    description: 'Fresh mango blended with coconut milk, lime and a pinch of chili.',
    price: 115, imagePath: 'https://i.pinimg.com/1200x/7f/04/3c/7f043cfafba534e0ef7b4f9c8105a422.jpg',
    rating: 4.6, reviewCount: 163, prepTime: 4, restaurantId: 'r1',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '54', name: 'Mulled Wine',
    description: 'Freshly squeezed lemonade with a hint of mint and sparkling water.',
    price: 95, imagePath: 'https://i.pinimg.com/736x/34/05/5c/34055c8752e3cfc1d8222ff12f815489.jpg',
    rating: 4.5, reviewCount: 142, prepTime: 3, restaurantId: 'r1',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '55', name: 'Berry Gin and Tonic',
    description: 'Thick and creamy milkshake blended with fresh strawberries and vanilla.',
    price: 140, imagePath: 'https://i.pinimg.com/736x/61/2b/9e/612b9e5d35be8c4f2aa8f078303ec95c.jpg',
    rating: 4.7, reviewCount: 207, prepTime: 5, restaurantId: 'r4',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '56', name: 'Pomegranate Hibscus Iced Tea',
    description: 'Espresso over ice with milk and a generous drizzle of caramel sauce.',
    price: 135, imagePath: 'https://i.pinimg.com/1200x/65/cc/a0/65cca0ed8def8be76dc12dfe60e13371.jpg',
    rating: 4.8, reviewCount: 319, prepTime: 4, restaurantId: 'r4',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '57', name: 'White Wine',
    description: 'Brown sugar milk tea with chewy tapioca pearls and fresh milk.',
    price: 125, imagePath: 'https://i.pinimg.com/1200x/28/fb/c5/28fbc53ddaa67340f8ddb652564e7574.jpg',
    rating: 4.7, reviewCount: 284, prepTime: 5, restaurantId: 'r2',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),
  FoodItem(
    id: '58', name: 'Grape Fruit Negroni ',
    description: 'Fresh passion fruit juice with a touch of honey and mint.',
    price: 100, imagePath: 'https://i.pinimg.com/736x/1f/df/16/1fdf16875490bf65773a64e3aeff2705.jpg',
    rating: 4.6, reviewCount: 156, prepTime: 3, restaurantId: 'r3',
    category: FoodCategory.drinks, addons: _drinksAddons,
  ),

  // â”€â”€ NOODLES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  FoodItem(
    id: '59', name: 'Ramen Bowl',
    description: 'Rich tonkotsu broth with chashu pork, soft egg and nori.',
    price: 280, imagePath: 'https://i.pinimg.com/736x/2f/70/14/2f701473cf49ff3e7244abf1a6d74163.jpg',
    rating: 4.7, reviewCount: 178, prepTime: 12, restaurantId: 'r1',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '60', name: 'Tonkotsu Ramen',
    description: 'Stir-fried rice noodles with shrimp, tofu, bean sprouts and crushed peanuts.',
    price: 310, imagePath: 'https://i.pinimg.com/736x/2e/c9/0b/2ec90b644bcde43f6313cbf570c57142.jpg',
    rating: 4.7, reviewCount: 193, prepTime: 13, restaurantId: 'r1',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '61', name: 'Shoyu Ramen',
    description: 'Vietnamese beef noodle soup with fragrant star anise broth and fresh herbs.',
    price: 295, imagePath: 'https://i.pinimg.com/736x/03/36/1b/03361b3c110694cc9a8bcd03b6d22531.jpg',
    rating: 4.8, reviewCount: 221, prepTime: 15, restaurantId: 'r2',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '62', name: 'Spicy Miso Ramen',
    description: 'Japanese stir-fried wheat noodles with pork, cabbage and yakisoba sauce.',
    price: 265, imagePath: 'https://i.pinimg.com/736x/b5/4c/99/b54c99c9d9a5026ebc0ddf0ab2cc3c5e.jpg',
    rating: 4.6, reviewCount: 147, prepTime: 11, restaurantId: 'r2',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '63', name: 'Chicken Ramen',
    description: 'Sichuan spicy noodles with minced pork, chili oil and crushed peanuts.',
    price: 290, imagePath: 'https://i.pinimg.com/1200x/6f/d0/1b/6fd01b947f204453257a3c7e86252de4.jpg',
    rating: 4.7, reviewCount: 169, prepTime: 13, restaurantId: 'r3',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '64', name: 'Spicy Ramen Bowl',
    description: 'Thick chewy udon noodles in a light dashi broth with tempura and scallions.',
    price: 275, imagePath: 'https://i.pinimg.com/736x/09/b0/ad/09b0ad17fbe802986bed5d7770da6b43.jpg',
    rating: 4.6, reviewCount: 158, prepTime: 12, restaurantId: 'r3',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
  FoodItem(
    id: '65', name: 'Classic Ramen',
    description: 'Spicy coconut curry noodle soup with shrimp, tofu puffs and bean sprouts.',
    price: 305, imagePath: 'https://i.pinimg.com/736x/5c/bd/f7/5cbdf77e79fafda3a9080ad186d6fddc.jpg',
    rating: 4.8, reviewCount: 194, prepTime: 14, restaurantId: 'r4',
    category: FoodCategory.noodles, addons: _noodlesAddons,
  ),
];
