import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firestore_paths.dart';

class FirestoreService {
  FirestoreService(this.rid);
  final String rid;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> tablesCol() =>
      _db.collection(FP.tables(rid));
  CollectionReference<Map<String, dynamic>> ordersCol() =>
      _db.collection(FP.orders(rid));
  CollectionReference<Map<String, dynamic>> orderItemsCol(String orderId) =>
      _db.collection(FP.orderItems(rid, orderId));

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTables() =>
      tablesCol().orderBy('name').snapshots();

  Future<String> openOrderForTable({required String tableId, required String waiterId}) async {
    final orderRef = ordersCol().doc();
    final tableRef = tablesCol().doc(tableId);
    await _db.runTransaction((tx) async {
      final tableSnap = await tx.get(tableRef);
      if (tableSnap.data()?['currentOrderId'] != null) return;
      tx.set(orderRef, {
        'tableId': tableId,
        'waiterId': waiterId,
        'status': 'new',
        'subtotal': 0, 'discount': 0, 'serviceCharge': 0, 'tax': 0, 'total': 0,
        'itemsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(tableRef, {
        'isAvailable': false,
        'currentOrderId': orderRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return orderRef.id;
  }

  Future<void> addItemToOrder({
    required String orderId,
    required String menuItemId,
    required String name,
    required double price,
    required int qty,
    String? note,
  }) async {
    final orderRef = ordersCol().doc(orderId);
    final itemRef = orderItemsCol(orderId).doc();
    await _db.runTransaction((tx) async {
      tx.set(itemRef, {
        'menuItemId': menuItemId, 'name': name, 'price': price, 'qty': qty,
        'note': note, 'lineStatus': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snap = await tx.get(orderRef);
      final oldSubtotal = (snap.data()?['subtotal'] ?? 0).toDouble();
      final oldCount = (snap.data()?['itemsCount'] ?? 0) as int;
      final newSubtotal = oldSubtotal + price * qty;
      tx.update(orderRef, {
        'subtotal': newSubtotal,
        'total': newSubtotal,
        'itemsCount': oldCount + qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) =>
      ordersCol().doc(orderId).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> closeOrderAndFreeTable(String orderId) async {
    final orderRef = ordersCol().doc(orderId);
    final snap = await orderRef.get();
    final tableId = snap.data()?['tableId'];
    if (tableId == null) return;
    final tableRef = tablesCol().doc(tableId);
    await _db.runTransaction((tx) async {
      tx.update(orderRef, {'status': 'paid', 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(tableRef, {'isAvailable': true, 'currentOrderId': null, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }
}
