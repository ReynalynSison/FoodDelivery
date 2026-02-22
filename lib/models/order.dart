import 'package:hive/hive.dart';

enum OrderStatus {
  /// "Order Confirmed" — immediately after payment
  confirmed,

  /// "Delivery is on the way" — after 60 seconds
  onTheWay,

  /// "Delivered" — rider reaches pinned destination
  delivered,
}

class Order {
  final String id;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final List<String> items;

  const Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  Order copyWith({
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      totalAmount: totalAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      items: items,
    );
  }
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 1;

  @override
  OrderStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return OrderStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    writer.writeByte(obj.index);
  }
}

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 2;

  @override
  Order read(BinaryReader reader) {
    final id = reader.readString();
    final totalAmount = reader.readDouble();
    final status = reader.read() as OrderStatus;
    final createdAtMillis = reader.readInt();
    final items = (reader.read() as List).cast<String>();

    return Order(
      id: id,
      totalAmount: totalAmount,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      items: items,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeString(obj.id)
      ..writeDouble(obj.totalAmount)
      ..write(obj.status)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..write(obj.items);
  }
}
