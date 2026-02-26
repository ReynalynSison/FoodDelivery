import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearGradient, SliverGridDelegateWithFixedCrossAxisCount;
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../models/food_item.dart';
import '../providers/theme_provider.dart';
import '../providers/wishlist_provider.dart';
import '../food/food_detail_page.dart';

// ── Accent ────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFFF6B35);

// ── Theme-aware color helpers ─────────────────────────────────────────────
Color _kBg(bool dark)      => dark ? const Color(0xFF1C1C1E) : const Color(0xFFF5EFE6);
Color _kCard(bool dark)    => dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
Color _kDark(bool dark)    => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
Color _kGrey(bool dark)    => dark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
Color _kLightBg(bool dark) => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF0EBE3);

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final wishlist = context.watch<WishlistProvider>();
    final items    = wishlist.items;

    return CupertinoPageScaffold(
      backgroundColor: _kBg(isDark),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Wishlist',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _kDark(isDark),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${items.length}',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Sub-title ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Text(
                  items.isEmpty
                      ? 'Heart food items to save them here'
                      : 'Your saved favourites',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGrey(isDark),
                  ),
                ),
              ),
            ),

            // ── Empty state ───────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _kLightBg(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.heart_slash,
                          size: 44,
                          color: _kGrey(isDark),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Favourites Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kDark(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the ♥ on any food item\nto add it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _kGrey(isDark),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Wish list grid ─────────────────────────────────────────────
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
                    (context, index) => _WishCard(
                      item: items[index],
                      isDark: isDark,
                    ),
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
// Single wishlist card
// ──────────────────────────────────────────────────────────────────────────────
class _WishCard extends StatelessWidget {
  final FoodItem item;
  final bool isDark;

  const _WishCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart     = context.watch<CartProvider>();
    final qty      = cart.quantityOf(item);

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
                offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with heart ──────────────────────────────────────────
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
                            : [
                                const Color(0xFFFFF3E8),
                                const Color(0xFFFFE4CC)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _buildImage(item),
                  ),
                ),
                // Remove from wishlist heart button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => wishlist.toggle(item.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0x26FF6B35),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        size: 16,
                        color: _kAccent,
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kLightBg(isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    size: 14,
                                    color: _kAccent),
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
      return Image.asset(item.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
              child: Text(_emojiFor(item.name),
                  style: const TextStyle(fontSize: 48))));
    }
    return Center(
        child:
            Text(_emojiFor(item.name), style: const TextStyle(fontSize: 48)));
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



