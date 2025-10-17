class CategoryModel {
  String id;
  String name;
  String? image;

  CategoryModel({required this.id, required this.name, this.image});

  factory CategoryModel.fromMap(String id, Map<String, dynamic> json) =>
      CategoryModel(id: id, name: json['name'] ?? '', image: json['image']);

  Map<String, dynamic> toMap() => {'name': name, 'image': image};
}

