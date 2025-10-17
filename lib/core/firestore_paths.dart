class FP {
  static String restaurant(String rid) => 'restaurants/$rid';
  static String tables(String rid) => '${restaurant(rid)}/tables';
  static String orders(String rid) => '${restaurant(rid)}/orders';
  static String orderItems(String rid, String orderId) => '${orders(rid)}/$orderId/items';
  static String categories(String rid) => '${restaurant(rid)}/categories';
  static String menuItems(String rid) => '${restaurant(rid)}/menu_items';
  static String users() => 'users'; // hồ sơ user (role)
}

