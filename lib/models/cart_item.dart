import 'menu_item_model.dart';

class CartItem {
  final String id;
  final MenuItemModel item;
  int qty;
  String? note;
  CartItem({required this.id, required this.item, required this.qty, this.note});
  double get lineTotal => item.price * qty;
}


