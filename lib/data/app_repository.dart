// lib/data/app_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firestore_paths.dart'; // dùng class FP.* (không alias)
import '../models/user.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item.dart';

class AppRepository extends ChangeNotifier {
  AppRepository({String? restaurantId})
      : _rid = restaurantId ?? 'default_restaurant';

  // Firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final String _rid;

  // Auth state
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // In-memory
  final List<TableModel> _tables = [];
  final List<CategoryModel> _categories = [];
  final List<MenuItemModel> _menu = [];
  final List<CartItem> _cart = [];
  TableModel? _selectedTable;

  List<TableModel> get tables => List.unmodifiable(_tables);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<MenuItemModel> get menu => List.unmodifiable(_menu);
  List<CartItem> get cart => List.unmodifiable(_cart);
  TableModel? get selectedTable => _selectedTable;

  int get cartItemsCount => _cart.fold<int>(0, (s, c) => s + c.qty);
  double get cartTotal => _cart.fold<double>(0, (s, c) => s + c.lineTotal);

  // Streams
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tablesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _menuSub;
  bool _streamsStarted = false;

  // ================= Lifecycle =================
  Future<void> init() async {
    _authSub = _auth.authStateChanges().listen((u) async {
      if (u == null) {
        _onSignedOut();
        return;
      }
      await _onSignedIn(u);
    });
  }

  @override
  void dispose() {
    _stopDataStreams();
    _authSub?.cancel();
    super.dispose();
  }

  // ================= Auth =================
  Future<String> register({
    required String email,
    required String password,
    UserRole role = UserRole.waiter,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection(FP.users()).doc(cred.user!.uid).set({
        'email': email,
        'role': role == UserRole.admin ? 'admin' : 'waiter',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'OK';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng ký thất bại';
    } catch (_) {
      return 'Đăng ký thất bại';
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'OK'; // AuthGate sẽ tự điều hướng
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sai email hoặc mật khẩu';
    } catch (_) {
      return 'Sai email hoặc mật khẩu';
    }
  }

  Future<void> logout() async {
    await _auth.signOut(); // AuthGate sẽ quay về Login
  }

  // =========== Streams bind/unbind theo auth ===========
  Future<void> _onSignedIn(User u) async {
    final userDoc = await _db.collection(FP.users()).doc(u.uid).get();
    final roleStr = (userDoc.data()?['role'] as String?) ?? 'waiter';
    _currentUser = AppUser(
      id: u.uid,
      email: u.email ?? '',
      password: u.refreshToken ?? '',
      role: roleStr == 'admin' ? UserRole.admin : UserRole.waiter,
    );

    _startDataStreams();
    notifyListeners();
  }

  void _onSignedOut() {
    _currentUser = null;
    _selectedTable = null;
    _cart.clear();
    _tables.clear();
    _categories.clear();
    _menu.clear();
    _stopDataStreams();
    notifyListeners();
  }

  void _startDataStreams() {
    if (_streamsStarted) return;
    _streamsStarted = true;

    _tablesSub = _db
        .collection(FP.tables(_rid))
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _tables
        ..clear()
        ..addAll(snap.docs.map((d) => TableModel.fromMap(d.id, d.data())));
      notifyListeners();
    }, onError: _log('tables'));

    _categoriesSub = _db
        .collection(FP.categories(_rid))
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _categories
        ..clear()
        ..addAll(snap.docs.map((d) => CategoryModel.fromMap(d.id, d.data())));
      notifyListeners();
    }, onError: _log('categories'));

    _menuSub = _db
        .collection(FP.menuItems(_rid))
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _menu
        ..clear()
        ..addAll(snap.docs.map((d) => MenuItemModel.fromMap(d.id, d.data())));
      notifyListeners();
    }, onError: _log('menu_items'));
  }

  void _stopDataStreams() {
    if (!_streamsStarted) return;
    _streamsStarted = false;
    _tablesSub?.cancel(); _tablesSub = null;
    _categoriesSub?.cancel(); _categoriesSub = null;
    _menuSub?.cancel(); _menuSub = null;
  }

  void Function(Object) _log(String name) => (e) {
        if (kDebugMode) print('[$name] stream error: $e');
      };

  // ================ Waiter flow (bàn & giỏ) ================
  void selectTable(TableModel t) {
    _selectedTable = t;
    notifyListeners();
  }

  void selectTableById(String tableId) {
    final t = _tables.firstWhere(
      (x) => x.id == tableId,
      orElse: () => TableModel(id: tableId, name: tableId, capacity: 0),
    );
    selectTable(t);
  }

  void addToCart(MenuItemModel item, {String? note}) {
    final idx = _cart.indexWhere(
      (c) => c.item.id == item.id && (c.note ?? '') == (note ?? ''),
    );
    if (idx == -1) {
      _cart.add(CartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        item: item,
        qty: 1,
        note: note,
      ));
    } else {
      _cart[idx].qty += 1;
    }
    notifyListeners();
  }

  void increaseQty(String cartId) {
    final i = _cart.indexWhere((c) => c.id == cartId);
    if (i != -1) {
      _cart[i].qty += 1;
      notifyListeners();
    }
  }

  void decreaseQty(String cartId) {
    final i = _cart.indexWhere((c) => c.id == cartId);
    if (i != -1) {
      _cart[i].qty -= 1;
      if (_cart[i].qty <= 0) _cart.removeAt(i);
      notifyListeners();
    }
  }

  void setCartItemNote(String cartId, String? note) {
    final i = _cart.indexWhere((c) => c.id == cartId);
    if (i != -1) {
      _cart[i] = CartItem(
        id: _cart[i].id,
        item: _cart[i].item,
        qty: _cart[i].qty,
        note: note,
      );
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

  /// Tạo Order + Items; có thể đánh dấu bàn đang dùng.
  Future<String?> checkout({bool markTableBusy = true}) async {
    if (_selectedTable == null || _cart.isEmpty || _currentUser == null) {
      return null;
    }

    final orderRef = _db.collection(FP.orders(_rid)).doc();
    final tableRef = _db.collection(FP.tables(_rid)).doc(_selectedTable!.id);

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
        'itemsCount': cartItemsCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final itemsCol = _db.collection(FP.orderItems(_rid, orderRef.id));
      for (final c in _cart) {
        tx.set(itemsCol.doc(), {
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

      if (markTableBusy) {
        tx.update(tableRef, {
          'isAvailable': false,
          'currentOrderId': orderRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    clearCart();
    return orderRef.id;
  }

  /// Thanh toán + trả bàn.
  Future<void> closeOrderAndFreeTable(String orderId) async {
    final orderRef = _db.collection(FP.orders(_rid)).doc(orderId);
    final snap = await orderRef.get();
    final tableId = snap.data()?['tableId'] as String?;
    if (tableId == null) return;

    final tableRef = _db.collection(FP.tables(_rid)).doc(tableId);
    await _db.runTransaction((tx) async {
      tx.update(orderRef, {
        'status': 'paid',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(tableRef, {
        'isAvailable': true,
        'currentOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================ Admin CRUD ================
  // Tables
  Future<void> addTable(TableModel t) async {
    final doc = _db.collection(FP.tables(_rid)).doc(t.id);
    await doc.set({
      'name': t.name,
      'capacity': t.capacity,
      'isAvailable': t.isAvailable,
      'currentOrderId': t.currentOrderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTable(
    String id, {
    String? name,
    int? capacity,
    bool? isAvailable,
    String? currentOrderId,
  }) async {
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (capacity != null) data['capacity'] = capacity;
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (currentOrderId != null) data['currentOrderId'] = currentOrderId;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(FP.tables(_rid)).doc(id).update(data);
  }

  Future<void> deleteTable(String id) async {
    await _db.collection(FP.tables(_rid)).doc(id).delete();
  }

  // Categories
  Future<void> addCategory(CategoryModel c) async {
    final doc = _db.collection(FP.categories(_rid)).doc(c.id);
    await doc.set({
      'name': c.name,
      'image': c.image,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    String? image,
  }) async {
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (image != null) data['image'] = image;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(FP.categories(_rid)).doc(id).update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection(FP.categories(_rid)).doc(id).delete();
  }

  // Menu items
  Future<void> addMenuItem(MenuItemModel m) async {
    final doc = _db.collection(FP.menuItems(_rid)).doc(m.id);
    await doc.set({
      'name': m.name,
      'price': m.price,
      'categoryId': m.categoryId,
      'description': m.description,
      'image': m.image,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hỗ trợ cả `categoryId:` và alias cũ `category:`
  Future<void> updateMenuItem(
    String id, {
    String? name,
    double? price,
    String? categoryId,
    String? category, // alias
    String? description,
    String? image,
  }) async {
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    final cid = categoryId ?? category;
    if (cid != null) data['categoryId'] = cid;
    if (description != null) data['description'] = description;
    if (image != null) data['image'] = image;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(FP.menuItems(_rid)).doc(id).update(data);
  }

  Future<void> deleteMenuItem(String id) async {
    await _db.collection(FP.menuItems(_rid)).doc(id).delete();
  }
}

// ============ InheritedApp: cung cấp repo cho toàn bộ UI ============
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


