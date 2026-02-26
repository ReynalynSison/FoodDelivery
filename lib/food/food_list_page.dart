import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, SliverGridDelegateWithFixedCrossAxisCount, LinearGradient;
import 'package:provider/provider.dart';
import '../cart/cart_page.dart';
import '../cart/cart_provider.dart';
import '../core/database/location_service.dart';
import '../models/food_item.dart';
import '../providers/theme_provider.dart';
import '../providers/wishlist_provider.dart';
import 'food_data.dart' hide FoodItem, FoodCategory, FoodAddon, Restaurant;
import 'food_detail_page.dart';

// ── Accent (never changes) ─────────────────────────────────────────────────
const _kAccent = Color(0xFFFF6B35);

// ── Theme-aware color helpers ──────────────────────────────────────────────
Color _kBg(bool dark)      => dark ? const Color(0xFF1C1C1E) : const Color(0xFFF5EFE6);
Color _kCard(bool dark)    => dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
Color _kDark(bool dark)    => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
Color _kGrey(bool dark)    => dark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
Color _kLightBg(bool dark) => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF0EBE3);

// ── Category model ─────────────────────────────────────────────────────────
class _Category {
  final String label;
  final String emoji;
  final FoodCategory? filter; // null = All
  const _Category(this.label, this.emoji, this.filter);
}

const _categories = [
  _Category('All',      '🍽️', null),
  _Category('Meat',     '🥩', FoodCategory.meat),
  _Category('Pasta',    '🍝', FoodCategory.pasta),
  _Category('Noodles',  '🍜', FoodCategory.noodles),
  _Category('Desserts', '🍰', FoodCategory.desserts),
  _Category('Bread',    '🍞', FoodCategory.bread),
  _Category('Drinks',   '🍷', FoodCategory.drinks),
];

// ──────────────────────────────────────────────────────────────────────────────
class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});
  @override
  State<FoodListPage> createState() => FoodListPageState();
}

class FoodListPageState extends State<FoodListPage> {
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _searchActive = false;

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredItems {
    final cat = _categories[_selectedCategory].filter;
    final q   = _searchQuery.trim().toLowerCase();

    return foodMenu.where((item) {
      final matchesCat = cat == null || item.category == cat;
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          _categoryLabel(item.category).toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  String _categoryLabel(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.meat:     return 'Meat';
      case FoodCategory.pasta:    return 'Pasta';
      case FoodCategory.noodles:  return 'Noodles';
      case FoodCategory.desserts: return 'Desserts';
      case FoodCategory.bread:    return 'Bread';
      case FoodCategory.drinks:   return 'Drinks';
      default:                    return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final items = _filteredItems;

    // Read saved delivery address for the top bar location label
    final locationService = LocationService();
    final savedAddress = locationService.getSavedAddress();
    String locationLabel = 'Not set';
    if (savedAddress != null && savedAddress.isNotEmpty) {
      try {
        // Nominatim address format: "Place, Municipality, Province, Region, Country"
        // Extract municipality (2nd-to-last or 3rd-to-last part) and country (last part)
        final parts = savedAddress.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (parts.length >= 2) {
          final country = parts.last;
          // Try to find a meaningful municipality — skip region/province, pick ~3rd from end
          final municipality = parts.length >= 4 ? parts[parts.length - 4] : parts[parts.length - 2];
          locationLabel = '$municipality, $country';
        } else if (parts.isNotEmpty) {
          locationLabel = parts.first;
        }
      } catch (e) {
        // Fallback to truncated full address if parsing fails
        locationLabel = savedAddress.length > 30
            ? '${savedAddress.substring(0, 27)}...'
            : savedAddress;
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: _kBg(isDark),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Top bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _searchActive
                  ? _SearchBar(
                      controller: _searchController,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClose: () => setState(() {
                        _searchActive = false;
                        _searchQuery  = '';
                        _searchController.clear();
                      }),
                    )
                  : _TopBar(
                      isDark: isDark,
                      locationLabel: locationLabel,
                      onSearchTap: () => setState(() => _searchActive = true),
                    ),
            ),

            // ── Promo banner ───────────────────────────────────────────────
            if (!_searchActive)
              SliverToBoxAdapter(child: _PromoBanner()),

            // ── "Categories" label ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kDark(isDark),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // ── Category chips (icon cards) ────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final sel = i == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        decoration: BoxDecoration(
                          color: sel ? _kAccent : _kCard(isDark),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: sel
                                  ? const Color(0x59FF6B35)
                                  : const Color(0x0F000000),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_categories[i].emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              _categories[i].label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel ? CupertinoColors.white : _kDark(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Results header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'Results for "$_searchQuery"'
                            : _selectedCategory == 0
                                ? 'Popular Food'
                                : _categories[_selectedCategory].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kDark(isDark),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kLightBg(isDark),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${items.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Empty state ────────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.search_circle_fill,
                            size: 80,
                            color: _kGrey(isDark).withOpacity(0.25),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _kBg(isDark),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 28,
                                color: CupertinoColors.systemRed
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No food found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kDark(isDark),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different search or category',
                        style: TextStyle(fontSize: 14, color: _kGrey(isDark)),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Food grid ─────────────────────────────────────────────────
            if (items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item   = items[index];
                      final wished = context.watch<WishlistProvider>().isWished(item.id);
                      return _FoodGridCard(
                        item: item,
                        wished: wished,
                        isDark: isDark,
                        categoryLabel: _categoryLabel(item.category),
                        onWishToggle: () =>
                            context.read<WishlistProvider>().toggle(item.id),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Search bar (shown when active)
// ──────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _kCard(isDark),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: CupertinoTextField(
                controller: controller,
                autofocus: true,
                placeholder: 'Search food or category...',
                placeholderStyle:
                    TextStyle(color: _kGrey(isDark), fontSize: 14),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.search,
                      color: _kGrey(isDark), size: 18),
                ),
                style: TextStyle(color: _kDark(isDark), fontSize: 14),
                decoration: const BoxDecoration(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClose,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _kLightBg(isDark),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _kAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Top bar
// ──────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final bool isDark;
  final String locationLabel;
  const _TopBar({required this.onSearchTap, required this.isDark, required this.locationLabel});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().uniqueItemCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Food Tiger logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40FF6B35),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🐯', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Food Tiger',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _kAccent,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Icon(CupertinoIcons.location_fill,
                        size: 11, color: _kGrey(isDark)),
                    const SizedBox(width: 3),
                    Text(locationLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: _kGrey(isDark),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          _IconBtn(icon: CupertinoIcons.search, onTap: onSearchTap, isDark: isDark),
          const SizedBox(width: 10),
          _BadgeIconBtn(
            icon: CupertinoIcons.bag,
            badge: count,
            isDark: isDark,
            onTap: () => Navigator.of(context)
                .push(CupertinoPageRoute(builder: (_) => const CartPage())),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _IconBtn({required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _kCard(isDark),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: Icon(icon, color: _kDark(isDark), size: 20),
        ),
      );
}

class _BadgeIconBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  final bool isDark;
  const _BadgeIconBtn(
      {required this.icon, required this.badge, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kCard(isDark),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Icon(icon, color: _kDark(isDark), size: 20),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: _kAccent, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// Promo banner
// ──────────────────────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF3A2010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x59000000),
              blurRadius: 20,
              offset: Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x26FF6B35)),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x1AFF6B35)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _kAccent,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'LIMITED OFFER',
                          style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Discount\n50% OFF',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Text('Learn more',
                              style: TextStyle(
                                  color: _kAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(CupertinoIcons.arrow_right,
                              color: _kAccent, size: 13),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🐯',
                            style: TextStyle(fontSize: 64, shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(4, 6),
                              )
                            ])),
                        const SizedBox(height: 4),
                        const Text(
                          'Food Tiger',
                          style: TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Food grid card
// ──────────────────────────────────────────────────────────────────────────────
class _FoodGridCard extends StatelessWidget {
  final FoodItem item;
  final bool wished;
  final String categoryLabel;
  final bool isDark;
  final VoidCallback onWishToggle;

  const _FoodGridCard({
    required this.item,
    required this.wished,
    required this.categoryLabel,
    required this.isDark,
    required this.onWishToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty  = cart.quantityOf(item);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => FoodDetailPage(item: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard(isDark),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C2C2E), const Color(0xFF3A3A3C)]
                            : [const Color(0xFFFFF3E8), const Color(0xFFFFE4CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _buildImage(item),
                  ),
                ),
                // Wishlist heart
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onWishToggle,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: wished
                            ? const Color(0x26FF6B35)
                            : _kCard(isDark),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Icon(
                        wished
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        size: 16,
                        color: wished ? _kAccent : _kGrey(isDark),
                      ),
                    ),
                  ),
                ),
                // Category badge
                if (categoryLabel.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xCC1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryLabel,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kDark(isDark),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '₱${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _kAccent,
                          ),
                        ),
                        const Spacer(),
                        const Icon(CupertinoIcons.star_fill,
                            size: 12, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kDark(isDark),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    qty == 0
                        ? GestureDetector(
                            onTap: () => cart.addItem(item),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _kAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kLightBg(isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.check_mark_circled_solid,
                                    size: 14, color: _kAccent),
                                const SizedBox(width: 5),
                                Text(
                                  'In Cart ($qty)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(FoodItem item) {
    if (item.imagePath.startsWith('http')) {
      return Image.network(
        item.imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(
                child: Text(_emojiFor(item.name),
                    style: const TextStyle(fontSize: 48))),
        errorBuilder: (_, __, ___) => Center(
            child: Text(_emojiFor(item.name),
                style: const TextStyle(fontSize: 48))),
      );
    }
    if (item.imagePath.isNotEmpty) {
      return Image.asset(
        item.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
            child: Text(_emojiFor(item.name),
                style: const TextStyle(fontSize: 48))),
      );
    }
    return Center(
        child: Text(_emojiFor(item.name),
            style: const TextStyle(fontSize: 48)));
  }

  String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('ramen') || n.contains('noodle') || n.contains('pad thai')) return '🍜';
    if (n.contains('sushi'))                            return '🍣';
    if (n.contains('roll'))                             return '🌯';
    if (n.contains('bento'))                            return '🍱';
    if (n.contains('gyoza') || n.contains('dumpling'))  return '🥟';
    if (n.contains('matcha') || n.contains('latte'))    return '🧋';
    if (n.contains('mochi'))                            return '🍡';
    if (n.contains('salmon') || n.contains('fish'))     return '🐟';
    if (n.contains('burger'))                           return '🍔';
    if (n.contains('salad'))                            return '🥗';
    if (n.contains('carbonara') || n.contains('pasta')) return '🍝';
    if (n.contains('pizza'))                            return '🍕';
    if (n.contains('tiramisu') || n.contains('cake'))   return '🍰';
    if (n.contains('wing'))                             return '🍗';
    if (n.contains('avocado') || n.contains('toast'))   return '🥑';
    if (n.contains('cheesecake'))                       return '🍰';
    if (n.contains('bibimbap'))                         return '🍚';
    if (n.contains('croissant'))                        return '🥐';
    if (n.contains('acai') || n.contains('bowl'))       return '🫐';
    if (n.contains('taco'))                             return '🌮';
    if (n.contains('chocolate') || n.contains('lava'))  return '🍫';
    if (n.contains('soup'))                             return '🥣';
    if (n.contains('beef') || n.contains('steak'))      return '🥩';
    if (n.contains('chicken'))                          return '🍗';
    if (n.contains('bread'))                            return '🍞';
    if (n.contains('drink') || n.contains('juice'))     return '🧃';
    return '🍽️';
  }
}

