import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../core/database/order_storage_service.dart';
import '../food/food_data.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import 'tracking_page.dart';

class HistoryPage extends StatelessWidget {
  HistoryPage({super.key});

  final OrderStorageService _storage = OrderStorageService();

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  '
        '${two(local.hour)}:${two(local.minute)}';
  }

  // ── Reorder: look up each item name from foodMenu and add to cart ──────────

  void _reorder(BuildContext context, Order order) {
    final cart = context.read<CartProvider>();
    int added = 0;
    for (final name in order.items) {
      try {
        final food = foodMenu.firstWhere(
          (f) => f.name.toLowerCase() == name.toLowerCase(),
        );
        cart.addCartItem(CartItem(food: food));
        added++;
      } catch (_) {
        // Item no longer on menu — skip silently
      }
    }

    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Added to Cart'),
        content: Text(
          added > 0
              ? '$added item${added > 1 ? 's' : ''} added to your cart.'
              : 'None of the original items are currently available.',
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
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = context.watch<OrderProvider>().activeOrder;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('History'),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<Box<Order>>(
          valueListenable: _storage.listenable(),
          builder: (context, box, _) {
            final allOrders = box.values.toList().reversed.toList();

            // Separate active from delivered
            final delivered = allOrders
                .where((o) => o.status == OrderStatus.delivered)
                .toList();

            final bool hasActive = activeOrder != null;
            final bool hasDelivered = delivered.isNotEmpty;

            if (!hasActive && !hasDelivered) {
              return const _EmptyHistoryState();
            }

            return CustomScrollView(
              slivers: [
                // ── Active Order section ────────────────────────────────
                if (hasActive) ...[
                  _SliverSectionHeader(title: 'Active Order'),
                  SliverToBoxAdapter(
                    child: _OrderCard(
                      order: activeOrder,
                      formatDate: _formatDate,
                      isActive: true,
                      onAction: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const TrackingPage(),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],

                // ── Past Orders section ─────────────────────────────────
                if (hasDelivered) ...[
                  _SliverSectionHeader(title: 'Past Orders'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = delivered[index];
                        return _OrderCard(
                          order: order,
                          formatDate: _formatDate,
                          isActive: false,
                          onAction: () => _reorder(context, order),
                        );
                      },
                      childCount: delivered.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver section header
// ─────────────────────────────────────────────────────────────────────────────

class _SliverSectionHeader extends StatelessWidget {
  final String title;
  const _SliverSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order card — shared between active and delivered
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  final String Function(DateTime) formatDate;
  final bool isActive;
  final VoidCallback onAction;

  const _OrderCard({
    required this.order,
    required this.formatDate,
    required this.isActive,
    required this.onAction,
  });

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.onTheWay:
        return 'Delivery is on the way';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  Color _statusColor(OrderStatus status, BuildContext context) {
    switch (status) {
      case OrderStatus.confirmed:
        return CupertinoColors.systemOrange.resolveFrom(context);
      case OrderStatus.onTheWay:
        return CupertinoColors.systemBlue.resolveFrom(context);
      case OrderStatus.delivered:
        return CupertinoColors.systemGreen.resolveFrom(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: ID + status badge ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.length > 16 ? order.id.substring(6, 16) : order.id}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(order.status, context)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status, context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Items ──────────────────────────────────────────────────────
          if (order.items.isNotEmpty)
            Text(
              order.items.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),

          const SizedBox(height: 6),

          // ── Date + total ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(order.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: isActive
                ? CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: onAction,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.location_fill,
                            size: 15, color: CupertinoColors.white),
                        SizedBox(width: 6),
                        Text('Track Order',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: CupertinoColors.secondarySystemFill
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: onAction,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.arrow_counterclockwise,
                            size: 15,
                            color:
                                CupertinoColors.label.resolveFrom(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Reorder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 56,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your order history will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
