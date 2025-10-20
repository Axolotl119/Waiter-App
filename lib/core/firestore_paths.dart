/// Chuẩn hoá mọi đường dẫn sử dụng trong Firestore.
/// Dùng dạng class + static method để tránh lỗi "undefined_function" và lỗi lint prefix.
class FP {
  // Top-level collections
  static String users() => 'users';
  static String restaurants() => 'restaurants';

  // Nested collections under a restaurant
  static String tables(String rid) => 'restaurants/$rid/tables';
  static String categories(String rid) => 'restaurants/$rid/categories';
  static String menuItems(String rid) => 'restaurants/$rid/menu_items';
  static String orders(String rid) => 'restaurants/$rid/orders';

  // Sub-collections of a specific order
  static String orderItems(String rid, String orderId) =>
      'restaurants/$rid/orders/$orderId/items';

  // (Tuỳ nhu cầu: bạn có thể bổ sung thêm analytics, reservations...)
  // static String analyticsDaily(String rid) => 'restaurants/$rid/analytics_daily';
}


