import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demodidong/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';
import '../../data/app_repository.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final table = repo.selectedTable;
    final orderId = repo.activeOrderId;

    if (table == null || orderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn hàng')),
        body: const Center(child: Text('Chưa có bàn hoặc order đang mở')),
      );
    }

    // TODO: nếu bạn có getter: final rid = repo.restaurantId;
    const rid = 'default_restaurant';

    final orderRef = FirebaseFirestore.instance
        .collection(FP.orders(rid))
        .doc(orderId);

    final itemsRef = FirebaseFirestore.instance
        .collection(FP.orderItems(rid, orderId))
        .orderBy('createdAt', descending: false);

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Bàn ${table.name} • #${orderId.substring(0, 6)}',
            overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: orderRef.snapshots(),
          builder: (context, orderSnap) {
            if (orderSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!orderSnap.hasData || !orderSnap.data!.exists) {
              return const Center(child: Text('Order không tồn tại'));
            }
            final od = orderSnap.data!.data()!;
            final status = (od['status'] ?? 'open') as String;
            final subtotal = (od['subtotal'] ?? 0).toDouble();
            final total = (od['total'] ?? 0).toDouble();
            final itemsCount = (od['itemsCount'] ?? 0) as int;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header tóm tắt
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          _statusLabel(status),
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: _statusColor(status).withOpacity(.12),
                        side: BorderSide(color: _statusColor(status)),
                        labelStyle: TextStyle(color: _statusColor(status).shade700),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text('Món: $itemsCount'),
                      Text('Tạm tính: ${_vnd(subtotal)}'),
                      Text('Tổng: ${_vnd(total)}'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Danh sách món
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: itemsRef.snapshots(),
                    builder: (context, itemsSnap) {
                      if (itemsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = itemsSnap.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Chưa có món trong order'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final it = docs[i].data();
                          final name = (it['name'] ?? '') as String;
                          final price = (it['price'] ?? 0).toDouble();
                          final qty = (it['qty'] ?? 0) as int;
                          final note = (it['note'] ?? '') as String;

                          return Card(
                            child: ListTile(
                              title: Text(name, overflow: TextOverflow.ellipsis),
                              subtitle: Text([
                                '${_vnd(price)} x $qty = ${_vnd(price * qty)}',
                                if (note.isNotEmpty) 'Ghi chú: $note',
                              ].join('\n')),
                              isThreeLine: note.isNotEmpty,
                              leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                // Hành động
                Padding(
                  padding: EdgeInsets.only(
                    left: 12, right: 12, top: 12,
                    bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (status == 'open')
                        OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Xin tính tiền'),
                          onPressed: () async {
                            await repo.requestBill();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã chuyển trạng thái: chờ thanh toán')),
                            );
                          },
                        ),
                      if (status == 'billed' || status == 'open')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payments),
                          label: const Text('Thanh toán & trả bàn'),
                          onPressed: () async {
                            await repo.payAndFreeTable();
                            if (!context.mounted) return;
                            Navigator.pop(context); // quay về màn trước (bàn/menu)
                          },
                        ),
                      if (status == 'open')
                        TextButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Huỷ order'),
                          onPressed: () async {
                            final ok = await _confirm(context, 'Huỷ order và trả bàn?');
                            if (ok) {
                              await repo.voidOpenOrderAndFreeTable();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'billed': return 'Chờ thanh toán';
      case 'paid': return 'Đã thanh toán';
      case 'void': return 'Đã huỷ';
      case 'open':
      default: return 'Đang phục vụ';
    }
  }

  static MaterialColor _statusColor(String s) {
    switch (s) {
      case 'billed': return Colors.red;
      case 'paid': return Colors.green;
      case 'void': return Colors.blueGrey;
      case 'open':
      default: return Colors.orange;
    }
  }

  static String _vnd(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if ((idx - 1) % 3 == 0 && i != s.length - 1) b.write('.');
    }
    return '${b.toString()} đ';
  }

  static Future<bool> _confirm(BuildContext context, String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Có')),
        ],
      ),
    );
    return ok ?? false;
  }
}

