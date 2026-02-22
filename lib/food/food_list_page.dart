import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../cart/cart_page.dart';
import '../cart/cart_provider.dart';
import '../models/food_item.dart';
import 'food_data.dart';
import 'food_detail_page.dart';

class FoodListPage extends StatelessWidget {
  const FoodListPage({super.key});

  /// Returns time-appropriate greeting.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    // Popular = first 3 items, All = full list
    final List<FoodItem> popular = [foodMenu[0], foodMenu[1], foodMenu[2]];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Discover'),
        trailing: _CartIconButton(),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Greeting header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What are you craving today?',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Popular section header ──
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Popular')),

            // ── Popular cards (horizontal scroll) ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popular.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _FoodCardHorizontal(item: popular[index]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── All Items section header ──
            const SliverToBoxAdapter(child: _SectionHeader(title: 'All Items')),

            // ── All items vertical list ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _FoodItemTile(item: foodMenu[index]),
                childCount: foodMenu.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart icon with reactive badge
// ─────────────────────────────────────────────────────────────────────────────

class _CartIconButton extends StatelessWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => const CartPage()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(CupertinoIcons.bag_fill),
          if (count > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal card (Popular row)
// ─────────────────────────────────────────────────────────────────────────────

class _FoodCardHorizontal extends StatelessWidget {
  final FoodItem item;
  const _FoodCardHorizontal({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => FoodDetailPage(item: item)),
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
              child: const Icon(
                CupertinoIcons.photo,
                size: 36,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                _AddOrStepper(item: item, quantity: qty, compact: true),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vertical list tile (All Items)
// ─────────────────────────────────────────────────────────────────────────────

class _FoodItemTile extends StatelessWidget {
  final FoodItem item;
  const _FoodItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => FoodDetailPage(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Image placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
                child: const Icon(
                  CupertinoIcons.photo,
                  size: 28,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + description + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.star_fill,
                              size: 11, color: CupertinoColors.systemYellow),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Add / stepper — stop tap from propagating to row
            GestureDetector(
              onTap: () {}, // absorb taps on stepper
              behavior: HitTestBehavior.opaque,
              child: _AddOrStepper(item: item, quantity: qty, compact: false),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Add / Quantity Stepper widget
// ─────────────────────────────────────────────────────────────────────────────

class _AddOrStepper extends StatelessWidget {
  final FoodItem item;
  final int quantity;

  /// compact = true  → used in 150-wide horizontal card (smaller stepper)
  /// compact = false → used in vertical list tile (full-size stepper)
  final bool compact;

  const _AddOrStepper({
    required this.item,
    required this.quantity,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final double btnSize = compact ? 26 : 32;
    final double fontSize = compact ? 12 : 14;

    if (quantity == 0) {
      // ── "Add" pill ──
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => cart.addItem(item),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // ── [-] qty [+] stepper ──
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: CupertinoIcons.minus,
          size: btnSize,
          onTap: () => cart.removeItem(item),
        ),
        SizedBox(
          width: compact ? 24 : 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        _StepperButton(
          icon: CupertinoIcons.plus,
          size: btnSize,
          onTap: () => cart.addItem(item),
        ),
      ],
    );
  }
}

/// Small circular icon button used by the stepper.
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.square(size),
      onPressed: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: CupertinoColors.white),
      ),
    );
  }
}
