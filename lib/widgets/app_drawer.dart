// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../data/app_repository.dart';
import '../models/user.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // đóng drawer
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);

    // Dùng AnimatedBuilder để Drawer tự cập nhật khi repo thay đổi (auth/cart...)
    return AnimatedBuilder(
      animation: repo,
      builder: (_, __) {
        final user = repo.currentUser;
        final isAdmin = user?.role == UserRole.admin;
        final cartCount = repo.cart.fold<int>(0, (s, c) => s + c.qty);
        final cartTotal = repo.cartTotal;

        return Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    user == null
                        ? 'Chưa đăng nhập'
                        : (user.role == UserRole.admin ? 'Quản trị' : 'Nhân viên'),
                  ),
                  accountEmail: Text(user?.email ?? '—'),
                  currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
                ),

                // Khu vực waiter
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Phục vụ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.table_bar),
                  title: const Text('Chọn bàn'),
                  onTap: () => _go(context, '/select_table'),
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Menu'),
                  onTap: () => _go(context, '/menu'),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('Giỏ hàng'),
                  trailing: (cartCount > 0)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Chip(label: Text('$cartCount')),
                            Text('${cartTotal.toStringAsFixed(0)} đ',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        )
                      : null,
                  onTap: () => _go(context, '/cart'),
                ),

                const Divider(height: 24),

                // Khu vực admin
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Text('Quản trị', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Admin Dashboard'),
                    onTap: () => _go(context, '/admin'),
                  ),
                  const Divider(height: 24),
                ],

                // Đăng xuất
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    await repo.logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

