import 'package:flutter/material.dart';
import '../data/app_repository.dart';

class AppDrawer extends StatelessWidget {
  /// Dành cho trang Admin: đồng bộ chỉ số tab hiện tại (0: Bàn, 1: Món ăn, 2: Doanh thu).
  final int? currentIndex;

  /// Dành cho trang Admin: callback khi chọn tab (nếu đang đứng trong AdminDashboard).
  final ValueChanged<int>? onSelectIndex;

  /// Tuỳ chọn: callback đăng xuất. Nếu null, sẽ gọi repo.logout().
  final Future<void> Function()? onLogout;

  const AppDrawer({
    super.key,
    this.currentIndex,
    this.onSelectIndex,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final user = repo.currentUser;
    final isAdmin = (user?.isAdmin() == true); // hợp với model hiện tại của bạn

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
              accountName: Text(isAdmin ? 'Admin' : 'Waiter'),
              accountEmail: Text(user?.email ?? ''),
              margin: EdgeInsets.zero,
            ),

            // ===== PHẦN WAITER (luôn hiển thị cho cả admin lẫn waiter) =====
            _waiterItem(
              context,
              icon: Icons.table_bar,
              label: 'Chọn bàn',
              route: '/select_table',
            ),
            _waiterItem(
              context,
              icon: Icons.restaurant,
              label: 'Menu',
              route: '/menu',
            ),
            _waiterItem(
              context,
              icon: Icons.shopping_cart,
              label: 'Giỏ hàng',
              route: '/cart',
            ),
            _waiterItem(
              context,
              icon: Icons.list_alt,
              label: 'Đơn hiện tại',
              route: '/order',
            ),

            // ===== PHẦN ADMIN (chỉ hiện nếu isAdmin) =====
            if (isAdmin) const Divider(),
            if (isAdmin)
              _adminItem(
                context,
                idx: 0,
                icon: Icons.table_bar,
                label: 'Quản trị • Bàn',
              ),
            if (isAdmin)
              _adminItem(
                context,
                idx: 1,
                icon: Icons.restaurant_menu,
                label: 'Quản trị • Món ăn',
              ),
            if (isAdmin)
              _adminItem(
                context,
                idx: 2,
                icon: Icons.auto_graph,
                label: 'Quản trị • Doanh thu',
              ),

            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                Navigator.pop(context);
                if (onLogout != null) {
                  await onLogout!();
                } else {
                  await repo.logout(); // AuthGate sẽ tự đưa về Login
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------- Items cho Waiter (route-based, dùng cho cả admin) ----------
  Widget _waiterItem(BuildContext context,
      {required IconData icon, required String label, required String route}) {
    final current = ModalRoute.of(context)?.settings.name;
    final selected = current == route;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        if (selected) return;
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }

  // --------- Items cho Admin (tab-based nếu đang ở Admin; nếu không thì mở /admin với tab tương ứng) ----------
  Widget _adminItem(BuildContext context,
      {required int idx, required IconData icon, required String label}) {
    final onSelect = onSelectIndex;
    final isInAdmin = ModalRoute.of(context)?.settings.name == '/admin';
    final sel = (currentIndex ?? 0) == idx;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isInAdmin && sel,
      onTap: () {
        Navigator.pop(context);
        if (isInAdmin && onSelect != null) {
          onSelect(idx); // đổi tab trực tiếp nếu đang trong AdminDashboard
        } else {
          // Điều hướng sang /admin với tab mong muốn
          Navigator.pushReplacementNamed(context, '/admin', arguments: {'tab': idx});
        }
      },
    );
  }
}




