import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item.dart';

// -----------------------------
// App-wide state: auth + data + cart
// -----------------------------
class AppRepository extends ChangeNotifier {
  // ---------- AUTH ----------
  AppUser? _currentUser;
  final List<AppUser> _users = [];

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // ---------- DATA ----------
  final List<TableModel> _tables = [];
  final List<MenuItemModel> _menu = [];
  TableModel? _selectedTable;
  final List<CartItem> _cart = [];

  List<TableModel> get tables => List.unmodifiable(_tables);
  List<MenuItemModel> get menu => List.unmodifiable(_menu);
  TableModel? get selectedTable => _selectedTable;
  List<CartItem> get cart => List.unmodifiable(_cart);
  double get cartTotal => _cart.fold(0, (s, c) => s + c.lineTotal);

  // ---------- MOCK DATA ----------
  void seed() {
    // demo users
    _users.addAll([
      AppUser(
        id: _id(),
        email: 'admin@demo.com',
        password: '123456',
        role: UserRole.admin,
      ),
      AppUser(
        id: _id(),
        email: 'guest@demo.com',
        password: '123456',
        role: UserRole.customer,
      ),
    ]);

    // demo tables
    _tables.addAll([
      TableModel(id: _id(), name: 'Bàn 1', capacity: 2),
      TableModel(id: _id(), name: 'Bàn 2', capacity: 4),
      TableModel(id: _id(), name: 'Bàn 3', capacity: 6, isAvailable: false),
    ]);

    // demo menu
    _menu.addAll([
      MenuItemModel(
        id: _id(),
        name: 'Cà phê sữa',
        price: 22000,
        category: 'Đồ uống',
      ),
      MenuItemModel(
        id: _id(),
        name: 'Trà đào',
        price: 26000,
        category: 'Đồ uống',
      ),
      MenuItemModel(
        id: _id(),
        name: 'Mì xào bò',
        price: 45000,
        category: 'Món chính',
      ),
      MenuItemModel(
        id: _id(),
        name: 'Cơm gà',
        price: 38000,
        category: 'Món chính',
      ),
    ]);
  }

  // ---------- AUTH ----------
  String register({required String email, required String password}) {
    if (_users.any((u) => u.email == email)) {
      return 'Email đã tồn tại';
    }
    _users.add(
      AppUser(
        id: _id(),
        email: email,
        password: password,
        role: UserRole.customer,
      ),
    );
    notifyListeners();
    return 'OK';
  }

  String login({required String email, required String password}) {
    final u = _users
        .where((u) => u.email == email && u.password == password)
        .toList();
    if (u.isEmpty) return 'Sai email hoặc mật khẩu';
    _currentUser = u.first;
    notifyListeners();
    return 'OK';
  }

  void logout() {
    _currentUser = null;
    _selectedTable = null;
    _cart.clear();
    notifyListeners();
  }

  // ---------- TABLES (ADMIN) ----------
  void addTable(TableModel t) {
    _tables.add(t);
    notifyListeners();
  }

  void updateTable(
    String id, {
    String? name,
    int? capacity,
    bool? isAvailable,
  }) {
    final i = _tables.indexWhere((e) => e.id == id);
    if (i != -1) {
      if (name != null) _tables[i].name = name;
      if (capacity != null) _tables[i].capacity = capacity;
      if (isAvailable != null) _tables[i].isAvailable = isAvailable;
      notifyListeners();
    }
  }

  void deleteTable(String id) {
    _tables.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---------- MENU (ADMIN) ----------
  void addMenuItem(MenuItemModel m) {
    _menu.add(m);
    notifyListeners();
  }

  void updateMenuItem(
    String id, {
    String? name,
    double? price,
    String? category,
  }) {
    final i = _menu.indexWhere((e) => e.id == id);
    if (i != -1) {
      if (name != null) _menu[i].name = name;
      if (price != null) _menu[i].price = price;
      if (category != null) _menu[i].category = category;
      notifyListeners();
    }
  }

  void deleteMenuItem(String id) {
    _menu.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---------- CUSTOMER FLOW ----------
  void selectTable(TableModel t) {
    _selectedTable = t;
    notifyListeners();
  }

  void addToCart(MenuItemModel item) {
    final idx = _cart.indexWhere((c) => c.item.id == item.id);
    if (idx == -1) {
      _cart.add(CartItem(id: _id(), item: item, qty: 1));
    } else {
      _cart[idx].qty += 1;
    }
    notifyListeners();
  }

  void decreaseQty(String cartId) {
    final i = _cart.indexWhere((c) => c.id == cartId);
    if (i != -1) {
      _cart[i].qty -= 1;
      if (_cart[i].qty <= 0) _cart.removeAt(i);
      notifyListeners();
    }
  }

  void removeFromCart(String cartId) {
    _cart.removeWhere((c) => c.id == cartId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------- CHECKOUT ----------
  void checkout() {
    clearCart();
    notifyListeners();
  }

  // ---------- UTIL ----------
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}

// -----------------------------------------------------------
// ✅ FIXED VERSION OF InheritedApp
// -----------------------------------------------------------
class InheritedApp extends InheritedNotifier<AppRepository> {
  final AppRepository repo;

  const InheritedApp({Key? key, required this.repo, required Widget child})
    : super(key: key, notifier: repo, child: child);

  static AppRepository of(BuildContext context) {
    final i = context.dependOnInheritedWidgetOfExactType<InheritedApp>();
    assert(i != null, 'Không tìm thấy InheritedApp trong context');
    return i!.repo;
  }
}
