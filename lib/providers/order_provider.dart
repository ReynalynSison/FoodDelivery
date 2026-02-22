import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  Order? _currentOrder;

  /// Single timer: fires once after 60 s to transition confirmed → onTheWay.
  Timer? _confirmationTimer;

  Order? get currentOrder => _currentOrder;

  /// Returns the current order only when it is NOT yet delivered.
  /// Used by Homepage banner and History page to detect an in-progress order.
  Order? get activeOrder =>
      (_currentOrder != null &&
              _currentOrder!.status != OrderStatus.delivered)
          ? _currentOrder
          : null;

  // -------------------------------------------------------------------------
  // Start order (called AFTER Hive save + cart clear in CartPage)
  // -------------------------------------------------------------------------

  /// Sets the current order to [order] (status must be [OrderStatus.confirmed])
  /// and starts the 60-second timer that transitions to [OrderStatus.onTheWay].
  void startOrder(Order order) {
    _confirmationTimer?.cancel();
    _currentOrder = order;
    notifyListeners();

    debugPrint('[OrderProvider] 60-second timer started for order: ${order.id}');

    _confirmationTimer = Timer(const Duration(seconds: 60), () {
      if (_currentOrder == null) return;
      debugPrint('[OrderProvider] 60 seconds elapsed → status: onTheWay');
      _currentOrder = _currentOrder!.copyWith(status: OrderStatus.onTheWay);
      notifyListeners();
    });
  }

  // -------------------------------------------------------------------------
  // Force delivered — called by TrackingPage when rider reaches destination
  // -------------------------------------------------------------------------

  /// Cancels the confirmation timer and marks the order as delivered.
  /// Called by TrackingPage when the rider animation reaches the final waypoint.
  void forceDelivered() {
    _confirmationTimer?.cancel();
    if (_currentOrder != null &&
        _currentOrder!.status != OrderStatus.delivered) {
      debugPrint('[OrderProvider] Rider reached destination → status: delivered');
      _currentOrder = _currentOrder!.copyWith(status: OrderStatus.delivered);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    super.dispose();
  }
}
