import 'package:flutter/material.dart';
import '../data/app_repository.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              repo.currentUser?.role == null ? '' : repo.currentUser!.role.name,
            ),
            accountEmail: Text(repo.currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_bar),
            title: const Text('Chọn bàn'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/select_table');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Menu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/menu');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Giỏ hàng'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/cart');
            },
          ),
          const Divider(),
          if (repo.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              repo.logout();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
