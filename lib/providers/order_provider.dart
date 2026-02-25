import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/database/order_storage_service.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  // ── Multiple active orders ────────────────────────────────────────────────
  final List<Order>         _activeOrders  = [];
  final Map<String, Timer?> _confirmTimers = {};
  final Map<String, bool>   _pendingRating = {};

  final _storage = OrderStorageService();

  // ── Getters ───────────────────────────────────────────────────────────────

  /// All orders that are NOT yet delivered (confirmed or onTheWay).
  List<Order> get activeOrders => List.unmodifiable(_activeOrders);

  /// First active (non-delivered) order — kept for backwards-compat.
  Order? get activeOrder =>
      _activeOrders.isNotEmpty ? _activeOrders.first : null;

  /// First current order regardless of status — kept for backwards-compat.
  Order? get currentOrder => _activeOrders.isNotEmpty
      ? _activeOrders.first
      : null;

  /// Whether ANY order has a pending (unrated) delivery.
  bool get pendingRating => _pendingRating.values.any((v) => v);

  /// Returns true if the specific order is pending rating.
  bool isPendingRating(String orderId) => _pendingRating[orderId] == true;

  // ── Restore persisted active orders on app launch ─────────────────────────

  /// Call once from [main] (or initState) after Hive is ready.
  Future<void> restoreActiveOrders() async {
    final saved = _storage.getActiveOrders();
    final now   = DateTime.now();

    for (final order in saved) {
      _pendingRating[order.id] = false;
      final elapsed = now.difference(order.createdAt).inSeconds;

      if (order.status == OrderStatus.confirmed) {
        // How many seconds remain until the 60s transition?
        final remaining = 60 - elapsed;

        if (remaining <= 0) {
          // Already past 60s — immediately move to onTheWay and persist.
          final updated = order.copyWith(status: OrderStatus.onTheWay);
          _activeOrders.add(updated);
          await _storage.updateOrderStatus(order.id, OrderStatus.onTheWay);
          // No more timer needed — TrackingPage handles rider movement.
        } else {
          // Resume countdown with remaining seconds.
          _activeOrders.add(order);
          _confirmTimers[order.id] = Timer(
            Duration(seconds: remaining),
            () => _updateStatus(order.id, OrderStatus.onTheWay),
          );
          debugPrint('[OrderProvider] Resumed timer for ${order.id}: ${remaining}s left');
        }
      } else if (order.status == OrderStatus.onTheWay) {
        // Already on the way — add directly; rider animation in TrackingPage
        // will pick it up and move to delivered when done.
        _activeOrders.add(order);
      }
      // delivered orders are ignored (not active)
    }

    if (_activeOrders.isNotEmpty) notifyListeners();
  }

  // ── Start a brand-new order ───────────────────────────────────────────────

  void startOrder(Order order) {
    // Cancel previous timer for same id just in case
    _confirmTimers[order.id]?.cancel();
    _pendingRating[order.id] = false;

    _activeOrders.add(order);
    notifyListeners();

    debugPrint('[OrderProvider] Timer started for ${order.id}');

    _confirmTimers[order.id] = Timer(const Duration(seconds: 60), () {
      _updateStatus(order.id, OrderStatus.onTheWay);
    });
  }

  // ── Force delivered ───────────────────────────────────────────────────────
  Future<void> forceDelivered(String orderId) async {
    _confirmTimers[orderId]?.cancel();
    _confirmTimers[orderId] = null;

    final idx = _activeOrders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    if (_activeOrders[idx].status == OrderStatus.delivered) return;

    debugPrint('[OrderProvider] Delivered: $orderId');
    _activeOrders[idx] = _activeOrders[idx].copyWith(status: OrderStatus.delivered);
    _pendingRating[orderId] = true;

    await _storage.updateOrderStatus(orderId, OrderStatus.delivered);

    notifyListeners();
  }

  /// Called after the user dismisses the rating sheet.
  void clearPendingRating(String orderId) {
    _pendingRating[orderId] = false;
    _activeOrders.removeWhere((o) => o.id == orderId);
    _confirmTimers.remove(orderId);
    _pendingRating.remove(orderId);
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  void _updateStatus(String orderId, OrderStatus newStatus) {
    final idx = _activeOrders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    debugPrint('[OrderProvider] $orderId → $newStatus');
    _activeOrders[idx] = _activeOrders[idx].copyWith(status: newStatus);
    // Persist the status change so it survives the next app launch too.
    _storage.updateOrderStatus(orderId, newStatus);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _confirmTimers.values) t?.cancel();
    super.dispose();
  }
}
