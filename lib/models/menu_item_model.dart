class MenuItemModel {
  final String id;
  String name;
  String? description;
  String? image;
  double price;
  String categoryId;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.image,
  });

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> map) =>
      MenuItemModel(
        id: id,
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        categoryId: map['categoryId'] ?? '',
        description: map['description'],
        image: map['image'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'categoryId': categoryId,
        'description': description,
        'image': image,
      };
}



