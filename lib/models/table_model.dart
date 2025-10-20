import 'package:meta/meta.dart';

enum TableState {
  vacant,    // trống
  occupied,  // đang phục vụ (đã seat)
  billed,    // đã xin tính tiền
  cleaning,  // đang dọn
  reserved,  // đã đặt trước
}

@immutable
class TableModel {
  final String id;
  final String name;
  final int capacity;
  final bool isAvailable;
  final String? currentOrderId;
  final TableState state;

  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isAvailable,
    required this.currentOrderId,
    required this.state,
  });

  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    bool? isAvailable,
    String? currentOrderId,
    TableState? state,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      state: state ?? this.state,
    );
  }

  static TableState _parseState(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'occupied':
        return TableState.occupied;
      case 'billed':
        return TableState.billed;
      case 'cleaning':
        return TableState.cleaning;
      case 'reserved':
        return TableState.reserved;
      case 'vacant':
      default:
        return TableState.vacant;
    }
  }

  static String stateToString(TableState st) {
    switch (st) {
      case TableState.occupied:
        return 'occupied';
      case TableState.billed:
        return 'billed';
      case TableState.cleaning:
        return 'cleaning';
      case TableState.reserved:
        return 'reserved';
      case TableState.vacant:
      return 'vacant';
    }
  }

  factory TableModel.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? const {};
    return TableModel(
      id: id,
      name: (data['name'] ?? '') as String,
      capacity: (data['capacity'] ?? 0) as int,
      isAvailable: (data['isAvailable'] ?? true) as bool,
      currentOrderId: data['currentOrderId'] as String?,
      state: _parseState(data['state'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'currentOrderId': currentOrderId,
      'state': stateToString(state),
      'updatedAt': DateTime.now(),
    };
  }
}



