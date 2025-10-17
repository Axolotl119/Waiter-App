import 'package:flutter/material.dart';
import '../../data/app_repository.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: repo.cart.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: repo.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = repo.cart[i];
                      return Card(
                        child: ListTile(
                          title: Text(c.item.name),
                          subtitle: Text(
                            '${c.qty} × ${_vnd(c.item.price)} = ${_vnd(c.lineTotal)}',
                          ),
                          trailing: SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => repo.decreaseQty(c.id),
                                ),
                                Text('${c.qty}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => repo.addToCart(c.item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => repo.removeFromCart(c.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Tổng')),
                          Text(
                            _vnd(repo.cartTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Thanh toán (mock)'),
                          onPressed: () {
                            repo.checkout();
                            Navigator.pushReplacementNamed(context, '/success');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

String _vnd(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i - 1;
    b.write(s[i]);
    if (left > 0 && left % 3 == 0) b.write('.');
  }
  return '$b đ';
}
