import 'menu_item_model.dart';

class CartItem {
  final String id;
  final MenuItemModel item;
  int qty;

  CartItem({required this.id, required this.item, required this.qty});

  double get lineTotal => item.price * qty;
}
