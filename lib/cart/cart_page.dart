import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../pages/tracking_page.dart';
import '../providers/order_provider.dart';
import '../payment/payment_page.dart';
import '../core/database/order_storage_service.dart';
import 'cart_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final bool isEmpty = cart.items.isEmpty;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Cart'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: isEmpty
                  ? const _EmptyCartState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      itemCount: cart.cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _CartItemTile(entry: cart.cartItems[index], index: index),
                    ),
            ),

            // ── Price breakdown + checkout (always visible at bottom) ──
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  // Subtotal row
                  _PriceRow(
                    label: 'Subtotal',
                    value: isEmpty ? 0 : cart.subtotal,
                  ),
                  const SizedBox(height: 6),

                  // Delivery fee row
                  _PriceRow(
                    label: 'Delivery Fee',
                    value: CartProvider.deliveryFee,
                    secondary: true,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 0.5,
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                  ),

                  // Total row
                  _PriceRow(
                    label: 'Total',
                    value: isEmpty
                        ? CartProvider.deliveryFee
                        : cart.grandTotal,
                    bold: true,
                  ),

                  const SizedBox(height: 14),

                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: isEmpty
                          ? null
                          : () => _handleCheckout(context, cart),
                      child: Text(
                        isEmpty
                            ? 'Proceed to Checkout'
                            : 'Checkout  •  \$${cart.grandTotal.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    final totalAmount = cart.grandTotal;

    final bool? paid = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => PaymentPage(totalAmount: totalAmount),
      ),
    );

    if (paid != true || !context.mounted) return;

    debugPrint('[CartPage] Invoice status == PAID');

    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final itemNames = cart.cartItems.map((e) => e.food.name).toList();

    final order = Order(
      id: orderId,
      totalAmount: totalAmount,
      status: OrderStatus.confirmed,
      createdAt: DateTime.now(),
      items: itemNames,
    );

    await OrderStorageService().saveOrder(order);
    debugPrint('[CartPage] Order saved to Hive: $orderId');

    cart.clearCart();

    if (!context.mounted) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Payment Successful'),
        content: Text(
          'Order ID: $orderId\nTotal: \$${totalAmount.toStringAsFixed(2)}',
        ),
        actions: [
          CupertinoDialogAction(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart item tile with image, stepper, and remove button
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem entry;
  final int index;
  const _CartItemTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: CupertinoColors.tertiarySystemBackground
                  .resolveFrom(context),
              child: Icon(
                CupertinoIcons.photo,
                size: 24,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + addons + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.food.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                if (entry.selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.selectedAddons.map((a) => a.name).join(', '),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
                if (entry.specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '"${entry.specialInstructions}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Line total: \$${entry.lineTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),

          // Right column: stepper + remove
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CartStepper(entry: entry, index: index),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => cart.removeItemCompletely(entry.food),
                child: Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed.resolveFrom(context),
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

// ─────────────────────────────────────────────────────────────────────────────
// Quantity stepper used inside cart tile
// ─────────────────────────────────────────────────────────────────────────────

class _CartStepper extends StatelessWidget {
  final CartItem entry;
  final int index;
  const _CartStepper({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleBtn(
          icon: CupertinoIcons.minus,
          onTap: () => cart.updateCartItemQuantity(index, entry.quantity - 1),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${entry.quantity}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        _CircleBtn(
          icon: CupertinoIcons.plus,
          onTap: () => cart.updateCartItemQuantity(index, entry.quantity + 1),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(30),
      onPressed: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: CupertinoColors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price breakdown row
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool secondary;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = secondary
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : CupertinoColors.label.resolveFrom(context);
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('\$${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty cart state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bag,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add items from the menu to get started.',
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
