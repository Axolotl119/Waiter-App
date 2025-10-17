// main.dart
import 'package:demodidong/screens/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'data/app_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tables/table_screen.dart';
import 'screens/waiter/menu_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/success/order_success_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = AppRepository(restaurantId: 'default_restaurant');
  await repo.init(); // lắng nghe Firebase Auth + bind/unbind streams

  runApp(
    ProviderScope(
      child: InheritedApp(
        repo: repo,
        child: const WaiterApp(),
      ),
    ),
  );
}

class WaiterApp extends StatelessWidget {
  const WaiterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waiter App',
      theme: buildTheme(),
      home: const AuthGate(), // 👈 KHÔNG dùng initialRoute: '/login'
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
  }
}

