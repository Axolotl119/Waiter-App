class TableModel {
  final String id;
  String name;
  int capacity;
  bool isAvailable;

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.isAvailable = true,
  });
}
