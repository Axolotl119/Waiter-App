import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/user.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item.dart';
import '../models/category_model.dart';

/// Đặt RID quán của bạn (hoặc truyền qua constructor)
const String _defaultRestaurantId = 'default_restaurant';

class AppRepository extends ChangeNotifier {
  AppRepository({String? restaurantId})
      : _rid = restaurantId ?? _defaultRestaurantId;

  // ---------- Firebase ----------
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final String _rid;

  // ---------- AUTH ----------
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ---------- DATA (được đồng bộ từ Firestore) ----------
  final List<TableModel> _tables = [];
  final List<CategoryModel> _categories = [];
  final List<MenuItemModel> _menu = [];
  TableModel? _selectedTable;

  List<TableModel> get tables => List.unmodifiable(_tables);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<MenuItemModel> get menu => List.unmodifiable(_menu);
  TableModel? get selectedTable => _selectedTable;

  // ---------- CART (local) ----------
  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);
  double get cartTotal => _cart.fold(0, (s, c) => s + c.lineTotal);

  // ---------- Subscriptions ----------
  StreamSubscription? _tablesSub;
  StreamSubscription? _menuSub;
  StreamSubscription<User?>? _authSub;

  

  // Call ở app start (sau khi Firebase.initializeApp)
  Future<void> init() async {
    // Auth changes -> load user profile
    _authSub = _auth.authStateChanges().listen((u) async {
      if (u == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }
      final userDoc = await _db.collection('users').doc(u.uid).get();
      final roleStr = (userDoc.data()?['role'] as String?) ?? 'waiter';
      _currentUser = AppUser(
        id: u.uid,
        email: u.email ?? '',
        password: '', // không dùng nữa
        role: roleStr == 'admin' ? UserRole.admin : UserRole.waiter,
      );
      notifyListeners();
    });

    // Listen Tables
    _tablesSub = _db
        .collection('restaurants')
        .doc(_rid)
        .collection('tables')
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _tables
        ..clear()
        ..addAll(snap.docs.map((d) {
          final m = d.data();
          return TableModel(
            id: d.id,
            name: (m['name'] ?? '') as String,
            capacity: (m['capacity'] ?? 0) as int,
            isAvailable: (m['isAvailable'] ?? true) as bool,
          );
        }));
      notifyListeners();
    });

    // Listen Menu Items
    _menuSub = _db
        .collection('restaurants')
        .doc(_rid)
        .collection('menu_items')
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _menu
        ..clear()
        ..addAll(snap.docs.map((d) {
          final m = d.data();
          return MenuItemModel(
            id: d.id,
            name: (m['name'] ?? '') as String,
            price: (m['price'] ?? 0).toDouble(),
            categoryId: (m['categoryId'] ?? m['category'] ?? '') as String,
          );
        }));
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tablesSub?.cancel();
    _menuSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  // ---------------- AUTH ----------------

  /// Đăng ký bằng Firebase Auth, mặc định role = waiter
  Future<String> register({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': 'waiter',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'OK';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng ký thất bại';
    } catch (_) {
      return 'Đăng ký thất bại';
    }
  }

  /// Đăng nhập bằng Firebase Auth
  Future<String> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'OK';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sai email hoặc mật khẩu';
    } catch (_) {
      return 'Sai email hoặc mật khẩu';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedTable = null;
    _cart.clear();
    notifyListeners();
  }

  // ---------------- ADMIN: TABLES ----------------

  Future<void> addTable(TableModel t) async {
    final doc = _db.collection('restaurants').doc(_rid).collection('tables').doc(t.id);
    await doc.set({
      'name': t.name,
      'capacity': t.capacity,
      'isAvailable': t.isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Listener sẽ đồng bộ vào _tables
  }

  Future<void> updateTable(
    String id, {
    String? name,
    int? capacity,
    bool? isAvailable,
  }) async {
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (capacity != null) data['capacity'] = capacity;
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('restaurants')
        .doc(_rid)
        .collection('tables')
        .doc(id)
        .update(data);
  }

  Future<void> deleteTable(String id) async {
    await _db
        .collection('restaurants')
        .doc(_rid)
        .collection('tables')
        .doc(id)
        .delete();
  }

  // ---------------- ADMIN: MENU ----------------

  Future<void> addMenuItem(MenuItemModel m) async {
    final doc = _db.collection('restaurants').doc(_rid).collection('menu_items').doc(m.id);
    await doc.set({
      'name': m.name,
      'price': m.price,
      // chấp nhận cả 'category' hay 'categoryId' (tuỳ DB bạn đang có)
      'categoryId': m.categoryId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(
    String id, {
    String? name,
    double? price,
    String? category,
  }) async {
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (category != null) data['categoryId'] = category;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('restaurants')
        .doc(_rid)
        .collection('menu_items')
        .doc(id)
        .update(data);
  }

  Future<void> deleteMenuItem(String id) async {
    await _db
        .collection('restaurants')
        .doc(_rid)
        .collection('menu_items')
        .doc(id)
        .delete();
  }

  // ---------------- CUSTOMER FLOW ----------------

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

  /// Gửi order lên Firestore (orders + items), sau đó xóa giỏ.
  Future<void> checkout() async {
    if (_selectedTable == null || _cart.isEmpty || _currentUser == null) {
      // Không đủ dữ liệu để tạo order
      clearCart();
      return;
    }

    final ordersCol =
        _db.collection('restaurants').doc(_rid).collection('orders');
    final orderRef = ordersCol.doc();

    await _db.runTransaction((tx) async {
      tx.set(orderRef, {
        'tableId': _selectedTable!.id,
        'waiterId': _currentUser!.id,
        'status': 'new',
        'subtotal': cartTotal,
        'discount': 0,
        'serviceCharge': 0,
        'tax': 0,
        'total': cartTotal,
        'itemsCount': _cart.fold<int>(0, (s, c) => s + c.qty),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final itemsCol = orderRef.collection('items');
      for (final c in _cart) {
        final itemRef = itemsCol.doc();
        tx.set(itemRef, {
          'menuItemId': c.item.id,
          'name': c.item.name,
          'price': c.item.price,
          'qty': c.qty,
          'note': c.note,
          'lineStatus': 'new',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // (Tuỳ chọn) Đánh dấu bàn đang dùng:
      // final tableRef = _db.collection('restaurants').doc(_rid).collection('tables').doc(_selectedTable!.id);
      // tx.update(tableRef, {
      //   'isAvailable': false,
      //   'currentOrderId': orderRef.id,
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });
    });

    clearCart();
  }

  // ---------- UTIL ----------
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}

// -----------------------------------------------------------
// InheritedApp giữ nguyên để UI hiện tại không phải đổi
// -----------------------------------------------------------
class InheritedApp extends InheritedNotifier<AppRepository> {
  final AppRepository repo;
  const InheritedApp({super.key, required this.repo, required super.child})
      : super(notifier: repo);

  static AppRepository of(BuildContext context) {
    final i = context.dependOnInheritedWidgetOfExactType<InheritedApp>();
    assert(i != null, 'Không tìm thấy InheritedApp trong context');
    return i!.repo;
  }
}

