enum OrderStatus { newOrder, sent, inKitchen, ready, served, paid, cancelled }
enum OrderLineStatus { newLine, sent, inKitchen, ready, served, cancelled }
enum PaymentMethod { cash, card, mobilePayment }
enum OrderServiceType { dineIn, takeAway, delivery }

class OrderLine {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final int qty;
  final String? note;
  final PaymentMethod? paymentMethod;
  final OrderServiceType? serviceType;
  final OrderLineStatus lineStatus;

  OrderLine({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
    this.note,
    this.paymentMethod,
    this.serviceType,
    this.lineStatus = OrderLineStatus.newLine,
  });

  factory OrderLine.fromMap(String id, Map<String, dynamic> map) {
    return OrderLine(
      id: id,
      menuItemId: map['menuItemId'],
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      qty: (map['qty'] ?? 1) as int,
      note: map['note'],
      lineStatus: _parseLineStatus(map['lineStatus']),
    );
  }

  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'name': name,
    'price': price,
    'qty': qty,
    'note': note,
    'lineStatus': lineStatus.name,
  };

  static OrderLineStatus _parseLineStatus(String? s) {
    switch (s) {
      case 'sent': return OrderLineStatus.sent;
      case 'inKitchen': return OrderLineStatus.inKitchen;
      case 'ready': return OrderLineStatus.ready;
      case 'served': return OrderLineStatus.served;
      case 'cancelled': return OrderLineStatus.cancelled;
      default: return OrderLineStatus.newLine;
    }
  }
}

class OrderModel {
  final String id;
  final String tableId;
  final String waiterId;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double tax;
  final double total;
  final int itemsCount;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.waiterId,
    this.status = OrderStatus.newOrder,
    this.subtotal = 0,
    this.discount = 0,
    this.serviceCharge = 0,
    this.tax = 0,
    this.total = 0,
    this.itemsCount = 0,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      tableId: map['tableId'],
      waiterId: map['waiterId'],
      status: _parseStatus(map['status']),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      serviceCharge: (map['serviceCharge'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      itemsCount: (map['itemsCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'tableId': tableId,
    'waiterId': waiterId,
    'status': status.name == 'newOrder' ? 'new' : status.name,
    'subtotal': subtotal,
    'discount': discount,
    'serviceCharge': serviceCharge,
    'tax': tax,
    'total': total,
    'itemsCount': itemsCount,
    'updatedAt': DateTime.now(),
  };

  static OrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'sent': return OrderStatus.sent;
      case 'in_kitchen': return OrderStatus.inKitchen;
      case 'ready': return OrderStatus.ready;
      case 'served': return OrderStatus.served;
      case 'paid': return OrderStatus.paid;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.newOrder;
    }
  }
}

