import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/order.dart';

class OrderStorageService {
  static const String boxName = 'orders';

  Box<Order> _box() => Hive.box<Order>(boxName);

  Future<void> saveOrder(Order order) async {
    await _box().add(order);
  }

  List<Order> getAllOrders() {
    return _box().values.toList().reversed.toList();
  }

  ValueListenable<Box<Order>> listenable() {
    return _box().listenable();
  }
}

