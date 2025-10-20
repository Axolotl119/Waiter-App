// lib/data/app_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firestore_paths.dart'; // class FP { static String users() ... }
import '../models/user.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item.dart';
import '../models/revenue_point.dart';

class AppRepository extends ChangeNotifier {
  AppRepository({String? restaurantId})
      : _rid = restaurantId ?? 'default_restaurant';

  // Firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final String _rid;

  // Auth
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // In-memory
  final List<TableModel> _tables = [];
  final List<CategoryModel> _categories = [];
  final List<MenuItemModel> _menu = [];
  final List<CartItem> _cart = [];
  TableModel? _selectedTable;
  String? _activeOrderId;

  List<TableModel> get tables => List.unmodifiable(_tables);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<MenuItemModel> get menu => List.unmodifiable(_menu);
  List<CartItem> get cart => List.unmodifiable(_cart);
  TableModel? get selectedTable => _selectedTable;
  String? get activeOrderId => _activeOrderId;

  int get cartItemsCount => _cart.fold<int>(0, (s, c) => s + c.qty);
  double get cartTotal => _cart.fold<double>(0, (s, c) => s + (c.item.price * c.qty));

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
      return 'OK'; // AuthGate tự điều hướng
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sai email hoặc mật khẩu';
    } catch (_) {
      return 'Sai email hoặc mật khẩu';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========== Streams bind/unbind theo auth ===========
  Future<void> _onSignedIn(User u) async {
    final userDoc = await _db.collection(FP.users()).doc(u.uid).get();
    final roleStr = (userDoc.data()?['role'] as String?) ?? 'waiter';
    _currentUser = AppUser(
      id: u.uid,
      email: u.email ?? '',
      role: roleStr == 'admin' ? UserRole.admin : UserRole.waiter,
      password: '',
    );

    _startDataStreams();
    notifyListeners();
  }

  void _onSignedOut() {
    _currentUser = null;
    _selectedTable = null;
    _activeOrderId = null;
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
      // nếu selected table trùng id, đồng bộ field mới
      if (_selectedTable != null) {
        final match = _tables.where((x) => x.id == _selectedTable!.id).toList();
        if (match.isNotEmpty) _selectedTable = match.first;
      }
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
    _activeOrderId = t.currentOrderId;
    notifyListeners();
  }

  void selectTableById(String tableId) {
    final t = _tables.firstWhere(
      (x) => x.id == tableId,
      orElse: () => TableModel(
        id: tableId,
        name: tableId,
        capacity: 0,
        isAvailable: true,
        currentOrderId: null,
        state: TableState.vacant,
      ),
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

  // ====== Flow mới: seat → open order → gửi món → billed → paid ======

  /// Seat table: nếu bàn trống → tạo order rỗng (status 'open') & đánh dấu bàn bận.
  /// Nếu bàn đã có order mở → chỉ load lại _activeOrderId.
  Future<void> seatTable(TableModel t, {int? covers}) async {
    _selectedTable = t;
    notifyListeners();
    if (_currentUser == null) return;

    final tableRef = _db.collection(FP.tables(_rid)).doc(t.id);

    if ((t.currentOrderId ?? '').isNotEmpty) {
      _activeOrderId = t.currentOrderId;
      return;
    }

    final orderRef = _db.collection(FP.orders(_rid)).doc();
    await _db.runTransaction((tx) async {
      tx.set(orderRef, {
        'tableId': t.id,
        'waiterId': _currentUser!.id,
        'status': 'open',
        'covers': covers,
        'subtotal': 0.0,
        'discount': 0.0,
        'serviceCharge': 0.0,
        'tax': 0.0,
        'total': 0.0,
        'itemsCount': 0,
        'openedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'closedAt': null,
      });
      tx.update(tableRef, {
        'isAvailable': false,
        'state': 'occupied',
        'currentOrderId': orderRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _activeOrderId = orderRef.id;
    _selectedTable = _selectedTable!.copyWith(
      isAvailable: false,
      currentOrderId: _activeOrderId,
      state: TableState.occupied,
    );
    notifyListeners();
  }

  /// Gửi giỏ hiện tại vào order đang mở (gửi bếp một đợt).
  Future<void> sendCartToKitchen() async {
    if (_activeOrderId == null || _cart.isEmpty) return;

    final orderId = _activeOrderId!;
    final orderRef = _db.collection(FP.orders(_rid)).doc(orderId);
    final itemsCol = _db.collection(FP.orderItems(_rid, orderId));

    final deltaTotal = cartTotal;
    final deltaCount = cartItemsCount;

    await _db.runTransaction((tx) async {
      for (final c in _cart) {
        tx.set(itemsCol.doc(), {
          'menuItemId': c.item.id,
          'name': c.item.name,
          'price': c.item.price,
          'qty': c.qty,
          'note': c.note,
          'lineStatus': 'new', // hoặc 'fired'
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(orderRef, {
        'status': 'open',
        'subtotal': FieldValue.increment(deltaTotal),
        'total': FieldValue.increment(deltaTotal),
        'itemsCount': FieldValue.increment(deltaCount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    clearCart();
  }

  /// Khách xin tính tiền -> 'billed' + bàn 'billed'
  Future<void> requestBill() async {
    if (_activeOrderId == null) return;
    final orderRef = _db.collection(FP.orders(_rid)).doc(_activeOrderId);
    await orderRef.update({
      'status': 'billed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_selectedTable != null) {
      await _db.collection(FP.tables(_rid)).doc(_selectedTable!.id).update({
        'state': 'billed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _selectedTable = _selectedTable!.copyWith(state: TableState.billed);
      notifyListeners();
    }
  }

  /// Thanh toán -> 'paid' + closedAt + bàn 'vacant'
  Future<void> payAndFreeTable() async {
    if (_activeOrderId == null || _selectedTable == null) return;

    final orderRef = _db.collection(FP.orders(_rid)).doc(_activeOrderId);
    final tableRef = _db.collection(FP.tables(_rid)).doc(_selectedTable!.id);

    await _db.runTransaction((tx) async {
      tx.update(orderRef, {
        'status': 'paid',
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(tableRef, {
        'isAvailable': true,
        'state': 'vacant',
        'currentOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _activeOrderId = null;
    _selectedTable = _selectedTable!.copyWith(
      isAvailable: true,
      currentOrderId: null,
      state: TableState.vacant,
    );
    notifyListeners();
  }

  /// Huỷ order mở và trả bàn
  Future<void> voidOpenOrderAndFreeTable() async {
    if (_activeOrderId == null || _selectedTable == null) return;

    final orderRef = _db.collection(FP.orders(_rid)).doc(_activeOrderId);
    final tableRef = _db.collection(FP.tables(_rid)).doc(_selectedTable!.id);

    await _db.runTransaction((tx) async {
      tx.update(orderRef, {
        'status': 'void',
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(tableRef, {
        'isAvailable': true,
        'state': 'vacant',
        'currentOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _activeOrderId = null;
    _selectedTable = _selectedTable!.copyWith(
      isAvailable: true,
      currentOrderId: null,
      state: TableState.vacant,
    );
    clearCart();
    notifyListeners();
  }

  // ================ Analytics: doanh thu ================
  /// Lấy doanh thu từ các order **paid** theo khoảng [from, to) gộp theo ngày/tháng.
  /// Dùng `closedAt` để phản ánh thời điểm thanh toán.
  Future<List<RevenuePoint>> fetchRevenue({
    required DateTime from,
    required DateTime to,
    RevenueGroupBy groupBy = RevenueGroupBy.day,
  }) async {
    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();

    final snap = await _db
        .collection(FP.orders(_rid))
        .where('status', isEqualTo: 'paid')
        .where('closedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromUtc))
        .where('closedAt', isLessThan: Timestamp.fromDate(toUtc))
        .orderBy('closedAt', descending: false)
        .get();

    final Map<DateTime, _Agg> agg = {};
    for (final d in snap.docs) {
      final data = d.data();
      final ts = data['closedAt'];
      if (ts == null) continue;
      final closed = (ts as Timestamp).toDate().toLocal();
      final total = (data['total'] ?? 0).toDouble();

      final bucket = (groupBy == RevenueGroupBy.day)
          ? DateTime(closed.year, closed.month, closed.day)
          : DateTime(closed.year, closed.month);

      final cur = agg[bucket] ?? _Agg.zero();
      agg[bucket] = cur.add(total);
    }

    final keys = agg.keys.toList()..sort();
    return keys
        .map((k) => RevenuePoint(bucket: k, total: agg[k]!.sum, orders: agg[k]!.count))
        .toList();
  }
}

class _Agg {
  final double sum;
  final int count;
  _Agg(this.sum, this.count);
  factory _Agg.zero() => _Agg(0, 0);
  _Agg add(double v) => _Agg(sum + v, count + 1);
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



