import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'data/app_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/select_table_screen.dart';
import 'screens/customer/menu_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/order_success_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() {
  runApp(const WaiterApp());
}

class WaiterApp extends StatelessWidget {
  const WaiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository()..seed(); // seed demo data
    return InheritedApp(repo: repo, child: const _App());
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return AnimatedBuilder(
      animation: repo,
      builder: (_, __) {
        return MaterialApp(
          title: 'Waiter App',
          theme: buildTheme(),
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/select_table': (_) => const SelectTableScreen(),
            '/menu': (_) => const MenuScreen(),
            '/cart': (_) => const CartScreen(),
            '/success': (_) => const OrderSuccessScreen(),
            '/admin': (_) => const AdminDashboard(),
          },
        );
      },
    );
  }
}
