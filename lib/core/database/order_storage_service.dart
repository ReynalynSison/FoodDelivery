import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/order.dart';

class OrderStorageService {
  static const String boxName = 'orders';

  Box<Order> _box() => Hive.box<Order>(boxName);

  Future<void> saveOrder(Order order) async {
    await _box().add(order);
  }

  /// Finds the stored order with [orderId] and overwrites it with [newStatus].
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final box = _box();
    for (final key in box.keys) {
      final order = box.get(key);
      if (order != null && order.id == orderId) {
        await box.put(key, order.copyWith(status: newStatus));
        return;
      }
    }
  }

  List<Order> getAllOrders() {
    return _box().values.toList().reversed.toList();
  }

  /// Returns all orders that are NOT yet delivered (confirmed or onTheWay).
  List<Order> getActiveOrders() {
    return _box()
        .values
        .where((o) => o.status != OrderStatus.delivered)
        .toList();
  }

  /// Returns only orders belonging to [username], newest first.
  List<Order> getOrdersForUser(String username) {
    return _box()
        .values
        .where((o) => o.username == username)
        .toList()
        .reversed
        .toList();
  }

  ValueListenable<Box<Order>> listenable() {
    return _box().listenable();
  }
}


