import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../core/database/order_storage_service.dart';
import '../food/food_data.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../providers/theme_provider.dart';

const _kAccent = Color(0xFFFF6B35);

Color _kBg(bool dark)    => dark ? const Color(0xFF1C1C1E) : const Color(0xFFF5EFE6);
Color _kCard(bool dark)  => dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
Color _kDark(bool dark)  => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
Color _kGrey(bool dark)  => const Color(0xFF8E8E93);
Color _kLight(bool dark) => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF0EBE3);

class HistoryPage extends StatelessWidget {
  HistoryPage({super.key, this.onBrowseMenu});

  /// Called when the user taps "Browse Menu" on the empty state.
  final VoidCallback? onBrowseMenu;

  final OrderStorageService _storage = OrderStorageService();

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}  •  ${two(d.hour)}:${two(d.minute)}';
  }

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
      } catch (_) {}
    }
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Added to Cart'),
        content: Text(added > 0
            ? '$added item${added > 1 ? 's' : ''} added to your cart.'
            : 'None of the original items are currently available.'),
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
    final isDark = context.watch<ThemeProvider>().isDark;

    return CupertinoPageScaffold(
      backgroundColor: _kBg(isDark),
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Box<Order>>(
          valueListenable: _storage.listenable(),
          builder: (context, box, _) {
            final currentUser = Hive.box('database').get('username', defaultValue: '') as String;
            final allOrders   = box.values.toList().reversed.toList();

            // Only show DELIVERED orders that belong to this account.
            final pastOrders  = allOrders
                .where((o) =>
                    o.status == OrderStatus.delivered &&
                    (o.username.isEmpty || o.username == currentUser))
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _PageHeader(isDark: isDark)),

                if (pastOrders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHistoryState(
                      isDark: isDark,
                      onBrowseMenu: onBrowseMenu,
                    ),
                  )
                else ...[
                  _sectionLabel('Past Orders', isDark),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PastOrderCard(
                        order: pastOrders[i],
                        isDark: isDark,
                        formatDate: _formatDate,
                        onReorder: () => _reorder(context, pastOrders[i]),
                      ),
                      childCount: pastOrders.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionLabel(String text, bool isDark) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Text(text,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: _kDark(isDark), letterSpacing: -0.3)),
        ),
      );
}

// ── Page header ───────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final bool isDark;
  const _PageHeader({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Orders',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900,
                          color: _kDark(isDark), letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('Track and reorder your meals',
                      style: TextStyle(
                          fontSize: 13, color: _kGrey(isDark),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _kCard(isDark),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: Icon(CupertinoIcons.bell, color: _kDark(isDark), size: 20),
            ),
          ],
        ),
      );
}

// ── Past order card ───────────────────────────────────────────────────────────
class _PastOrderCard extends StatelessWidget {
  final Order order;
  final String Function(DateTime) formatDate;
  final VoidCallback onReorder;
  final bool isDark;
  const _PastOrderCard({required this.order, required this.formatDate, required this.onReorder, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: _kCard(isDark),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0x1F34C759),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: const [
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            size: 11, color: Color(0xFF34C759)),
                        SizedBox(width: 4),
                        Text('Delivered',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF34C759))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                    style: TextStyle(
                        fontSize: 11, color: _kGrey(isDark), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.items.isNotEmpty ? order.items.join(' · ') : 'No items',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _kDark(isDark)),
              ),
              const SizedBox(height: 4),
              Text(formatDate(order.createdAt),
                  style: TextStyle(fontSize: 11, color: _kGrey(isDark))),
              const SizedBox(height: 14),
              Container(height: 1, color: _kLight(isDark)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total paid',
                          style: TextStyle(fontSize: 11, color: _kGrey(isDark))),
                      Text('₱${order.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900, color: _kDark(isDark))),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onReorder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kLight(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4DFF6B35), width: 1.5),
                      ),
                      child: Row(
                        children: const [
                          Icon(CupertinoIcons.arrow_counterclockwise,
                              size: 14, color: _kAccent),
                          SizedBox(width: 6),
                          Text('Reorder',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kAccent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyHistoryState extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onBrowseMenu;
  const _EmptyHistoryState({required this.isDark, this.onBrowseMenu});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: _kLight(isDark), shape: BoxShape.circle),
              child: Icon(CupertinoIcons.bag, size: 40, color: _kGrey(isDark)),
            ),
            const SizedBox(height: 20),
            Text('No orders yet',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _kDark(isDark))),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here\nonce you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kGrey(isDark), height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onBrowseMenu,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x59FF6B35), blurRadius: 12, offset: Offset(0, 5))
                  ],
                ),
                child: const Text('Browse Menu',
                    style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}