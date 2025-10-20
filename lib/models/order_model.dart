import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

enum OrderStatus {
  open,    // đã seat, đang thêm món
  billed,  // đã xin tính tiền
  paid,    // đã thanh toán
  voided,  // huỷ
}

@immutable
class OrderModel {
  final String id;
  final String tableId;
  final String waiterId;
  final OrderStatus status;

  final int? covers; // số khách
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double tax;
  final double total;
  final int itemsCount;

  final DateTime? openedAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  const OrderModel({
    required this.id,
    required this.tableId,
    required this.waiterId,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.tax,
    required this.total,
    required this.itemsCount,
    this.covers,
    this.openedAt,
    this.updatedAt,
    this.closedAt,
  });

  OrderModel copyWith({
    String? id,
    String? tableId,
    String? waiterId,
    OrderStatus? status,
    int? covers,
    double? subtotal,
    double? discount,
    double? serviceCharge,
    double? tax,
    double? total,
    int? itemsCount,
    DateTime? openedAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      waiterId: waiterId ?? this.waiterId,
      status: status ?? this.status,
      covers: covers ?? this.covers,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      itemsCount: itemsCount ?? this.itemsCount,
      openedAt: openedAt ?? this.openedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  static OrderStatus _parseStatus(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'billed':
        return OrderStatus.billed;
      case 'paid':
        return OrderStatus.paid;
      case 'void':
      case 'voided':
        return OrderStatus.voided;
      case 'open':
      default:
        return OrderStatus.open;
    }
  }

  static String statusToString(OrderStatus st) {
    switch (st) {
      case OrderStatus.billed:
        return 'billed';
      case OrderStatus.paid:
        return 'paid';
      case OrderStatus.voided:
        return 'void';
      case OrderStatus.open:
      default:
        return 'open';
    }
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? const {};
    return OrderModel(
      id: id,
      tableId: (data['tableId'] ?? '') as String,
      waiterId: (data['waiterId'] ?? '') as String,
      status: _parseStatus(data['status'] as String?),
      covers: data['covers'] is int ? data['covers'] as int : (data['covers'] == null ? null : int.tryParse('${data['covers']}')),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      itemsCount: (data['itemsCount'] ?? 0) as int,
      openedAt: _ts(data['openedAt']),
      updatedAt: _ts(data['updatedAt']),
      closedAt: _ts(data['closedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'waiterId': waiterId,
      'status': statusToString(status),
      'covers': covers,
      'subtotal': subtotal,
      'discount': discount,
      'serviceCharge': serviceCharge,
      'tax': tax,
      'total': total,
      'itemsCount': itemsCount,
      'openedAt': openedAt,
      'updatedAt': updatedAt,
      'closedAt': closedAt,
    };
  }
}



