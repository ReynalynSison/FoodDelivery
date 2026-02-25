import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../cart/cart_page.dart';
import '../cart/cart_provider.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../payment/payment_page.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../core/database/order_storage_service.dart';
import '../core/database/location_service.dart';
import '../pages/tracking_page.dart';
import 'food_data.dart' hide FoodItem, FoodCategory, FoodAddon, Restaurant;

// ─────────────────────────────────────────────────────────────────────────────
// FoodDetailPage
// ─────────────────────────────────────────────────────────────────────────────

class FoodDetailPage extends StatefulWidget {
  final FoodItem item;
  const FoodDetailPage({super.key, required this.item});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int _quantity = 1;
  final Set<String> _selectedAddonIds = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── Derived values ───────────────────────────────────────────────────────

  double get _addonTotal => widget.item.addons
      .where((a) => _selectedAddonIds.contains(a.id))
      .fold(0.0, (s, a) => s + a.extraPrice);

  double get _unitPrice => widget.item.price + _addonTotal;
  double get _lineTotal => _unitPrice * _quantity;

  // ── Addon toggle ─────────────────────────────────────────────────────────

  void _toggleAddon(String id) {
    setState(() {
      if (_selectedAddonIds.contains(id)) {
        _selectedAddonIds.remove(id);
      } else {
        _selectedAddonIds.add(id);
      }
    });
  }

  // ── Add to cart ──────────────────────────────────────────────────────────

  void _addToCart(BuildContext context) {
    final entry = CartItem(
      food: widget.item,
      quantity: _quantity,
      selectedAddonIds: _selectedAddonIds.toList(),
      specialInstructions: _notesController.text.trim(),
    );
    context.read<CartProvider>().addCartItem(entry);

    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Added to Cart'),
        content: Text(
          '${_quantity}× ${widget.item.name}\n'
              'Total: ₱${_lineTotal.toStringAsFixed(0)}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Keep Browsing'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('View Cart'),
            onPressed: () {
              Navigator.of(context).pop(); // dismiss dialog
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Order Now (bypass cart) ──────────────────────────────────────────────

  Future<void> _orderNow(BuildContext context) async {
    // ── Guard: require a delivery location before payment ──────────────────
    final locationService = LocationService();
    if (!locationService.hasSavedLocation()) {
      if (!context.mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No Delivery Location'),
          content: const Text(
            'Please set your delivery location first before proceeding to payment.\n\nGo to Settings → Set Location.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final entry = CartItem(
      food: widget.item,
      quantity: _quantity,
      selectedAddonIds: _selectedAddonIds.toList(),
      specialInstructions: _notesController.text.trim(),
    );

    final total = entry.lineTotal + CartProvider.deliveryFee;

    final bool? paid = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => PaymentPage(totalAmount: total),
      ),
    );

    if (paid != true || !context.mounted) return;

    debugPrint('[FoodDetail] Invoice status == PAID');

    final orderId  = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final username = Hive.box('database').get('username', defaultValue: '') as String;
    final order = Order(
      id: orderId,
      totalAmount: total,
      status: OrderStatus.confirmed,
      createdAt: DateTime.now(),
      items: [widget.item.name],
      username: username,
    );

    await OrderStorageService().saveOrder(order);
    debugPrint('[FoodDetail] Order saved to Hive: $orderId');

    if (!context.mounted) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Payment Successful'),
        content: Text(
          'Order ID: $orderId\nTotal: ₱${total.toStringAsFixed(0)}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Track Order'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              context.read<OrderProvider>().startOrder(order);
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => const TrackingPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final restaurant = restaurantById(item.restaurantId);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(item.name),
        trailing: _CartIconBadge(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Scrollable body
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Hero image ──
                  SliverToBoxAdapter(child: _HeroImage(item: item)),

                  // ── Name + price + rating ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.label
                                        .resolveFrom(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '₱${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.systemBlue
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _RatingRow(
                            rating: item.rating,
                            reviewCount: item.reviewCount,
                            prepTime: item.prepTime,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Divider ──
                  const SliverToBoxAdapter(child: _Divider()),

                  // ── Restaurant info card ──
                  if (restaurant != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: RestaurantInfoCard(restaurant: restaurant),
                      ),
                    ),

                  if (restaurant != null)
                    const SliverToBoxAdapter(child: _Divider()),

                  // ── Add-ons ──
                  if (item.addons.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'Add-ons',
                        subtitle: 'Optional',
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _AddonTile(
                          addon: item.addons[i],
                          selected:
                          _selectedAddonIds.contains(item.addons[i].id),
                          onToggle: () => _toggleAddon(item.addons[i].id),
                        ),
                        childCount: item.addons.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: _Divider()),
                  ],

                  // ── Quantity selector ──
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'Quantity',
                      subtitle: null,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: _QuantitySelector(
                        quantity: _quantity,
                        onDecrement: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        onIncrement: () => setState(() => _quantity++),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: _Divider()),

                  // ── Special instructions ──
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'Special Instructions',
                      subtitle: 'Optional',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: CupertinoTextField(
                        controller: _notesController,
                        placeholder: 'e.g. No onions, less spicy…',
                        minLines: 2,
                        maxLines: 4,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        placeholderStyle: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.placeholderText
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                  ),

                  // Extra bottom space for the sticky footer
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),

            // ── Sticky bottom bar ──
            _StickyBottomBar(
              lineTotal: _lineTotal,
              deliveryFee: CartProvider.deliveryFee,
              onAddToCart: () => _addToCart(context),
              onOrderNow: () => _orderNow(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RestaurantInfoCard  (exported — used from other places if needed)
// ─────────────────────────────────────────────────────────────────────────────

class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantInfoCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Store icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.building_2_fill,
              size: 22,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(width: 12),
          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(CupertinoIcons.star_fill,
                        size: 12, color: CupertinoColors.systemYellow),
                    const SizedBox(width: 3),
                    Text(
                      '${restaurant.rating}  (${restaurant.reviewCount} reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _MetaChip(
                      icon: CupertinoIcons.location_fill,
                      label: '${restaurant.distanceKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: CupertinoIcons.clock_fill,
                      label: '~${restaurant.etaMinutes} min',
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(isOpen: restaurant.isOpen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final FoodItem item;
  const _HeroImage({required this.item});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: item.imagePath.isNotEmpty
            ? Image.network(
                item.imagePath,
                fit: BoxFit.cover,
                cacheWidth: 800,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: CupertinoColors.tertiarySystemBackground
                        .resolveFrom(context),
                    child: const Center(child: CupertinoActivityIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context),
                  child: Icon(
                    CupertinoIcons.photo_fill,
                    size: 64,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              )
            : Container(
                color: CupertinoColors.tertiarySystemBackground
                    .resolveFrom(context),
                child: Icon(
                  CupertinoIcons.photo_fill,
                  size: 64,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final int prepTime;
  const _RatingRow({
    required this.rating,
    required this.reviewCount,
    required this.prepTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.star_fill,
            size: 14, color: CupertinoColors.systemYellow),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        Text(
          '  ($reviewCount)',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(CupertinoIcons.clock, size: 13,
            color: CupertinoColors.secondaryLabel),
        const SizedBox(width: 4),
        Text(
          '$prepTime min prep',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _AddonTile extends StatelessWidget {
  final FoodAddon addon;
  final bool selected;
  final VoidCallback onToggle;
  const _AddonTile({
    required this.addon,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.systemBlue.withValues(alpha: 0.08)
              : CupertinoColors.tertiarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? CupertinoColors.systemBlue.resolveFrom(context)
                : CupertinoColors.separator.resolveFrom(context),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: selected
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                addon.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            Text(
              '+₱${addon.extraPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyBtn(
          icon: CupertinoIcons.minus,
          enabled: onDecrement != null,
          onTap: onDecrement ?? () {},
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        _QtyBtn(icon: CupertinoIcons.plus, enabled: true, onTap: onIncrement),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey4.resolveFrom(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? CupertinoColors.white
              : CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

class _StickyBottomBar extends StatelessWidget {
  final double lineTotal;
  final double deliveryFee;
  final VoidCallback onAddToCart;
  final VoidCallback onOrderNow;
  const _StickyBottomBar({
    required this.lineTotal,
    required this.deliveryFee,
    required this.onAddToCart,
    required this.onOrderNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item total',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(
                '₱${lineTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery fee',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(
                '₱${deliveryFee.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Add to Cart
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onAddToCart,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.systemBlue
                            .resolveFrom(context),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.bag_badge_plus,
                          size: 18,
                          color: CupertinoColors.systemBlue
                              .resolveFrom(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemBlue
                                .resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Order Now
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onOrderNow,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.bolt_fill,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Order Now',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen
            ? CupertinoColors.systemGreen.withValues(alpha: 0.15)
            : CupertinoColors.systemRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen
              ? CupertinoColors.systemGreen.resolveFrom(context)
              : CupertinoColors.systemRed.resolveFrom(context),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart icon badge (top-right nav button)
// ─────────────────────────────────────────────────────────────────────────────

class _CartIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().uniqueItemCount;
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
                constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}