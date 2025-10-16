class MenuItemModel {
  final String id;
  String name;
  String? description;
  String? image;
  double price;
  String category;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });
}
