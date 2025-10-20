import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../models/cart_item.dart';
import '../../widgets/app_drawer.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final table = repo.selectedTable;

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text(
          table == null ? 'Giỏ hàng' : 'Bàn ${table.name} – Giỏ hàng',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (_, __) {
            final cart = repo.cart;
            if (cart.isEmpty) {
              return const Center(child: Text('Giỏ trống. Hãy thêm món từ Menu.'));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) => _CartTile(item: cart[i]),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: cart.length,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12, right: 12, top: 12,
                    bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tổng: ${repo.cartTotal.toStringAsFixed(0)} đ',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      // Dùng Wrap để tránh overflow khi màn nhỏ
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: repo.clearCart,
                            child: const Text('Xoá giỏ'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.fireplace),
                            label: const Text('Gửi bếp'),
                            onPressed: () async {
                              if (table == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chưa chọn/nhận bàn!')),
                                );
                                return;
                              }
                              await repo.sendCartToKitchen();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('Đã gửi bếp')));
                            },
                          ),
                        ],
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
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Card(
      child: ListTile(
        title: Text(item.item.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${item.item.price.toStringAsFixed(0)} đ x ${item.qty} = '
          '${(item.item.price * item.qty).toStringAsFixed(0)} đ',
        ),
        leading: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => repo.decreaseQty(item.id),
          tooltip: 'Giảm số lượng',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => repo.increaseQty(item.id),
          tooltip: 'Tăng số lượng',
        ),
      ),
    );
  }
}


