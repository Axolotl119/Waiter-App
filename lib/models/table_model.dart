class TableModel {
  final String id;
  String name;
  int capacity;
  bool isAvailable;
  String? currentOrderId;

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.isAvailable = true,
    this.currentOrderId,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) => TableModel(
        id: id,
        name: map['name'] ?? '',
        capacity: (map['capacity'] ?? 0) as int,
        isAvailable: (map['isAvailable'] ?? true) as bool,
        currentOrderId: map['currentOrderId'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'capacity': capacity,
        'isAvailable': isAvailable,
        'currentOrderId': currentOrderId,
      };
}

