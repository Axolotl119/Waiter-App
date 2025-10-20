import 'package:demodidong/data/app_repository.dart';
import 'package:demodidong/models/user.dart';
import 'package:demodidong/screens/admin/admin_dashboard.dart';
import 'package:demodidong/screens/auth/login_screen.dart';
import 'package:demodidong/screens/tables/table_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// AuthGate không điều hướng thủ công bằng Navigator.
/// Thay vào đó, nó trả về màn hình phù hợp dựa trên trạng thái đăng nhập + role.
/// Đồng thời đảm bảo gọi repo.init() đúng một lần để bind các stream sau khi login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);

    // Gọi init() đúng 1 lần (để lắng nghe authStateChanges và bind Firestore sau login)
    if (!_initialized) {
      _initialized = true;
      // safe: nếu đã init rồi bên ngoài cũng không sao; chỉ attach listener 1 lần
      repo.init();
    }

    final fbUser = FirebaseAuth.instance.currentUser;

    // Chưa đăng nhập → về LoginScreen
    if (fbUser == null) {
      return const LoginScreen();
    }

    // Đã có user Firebase nhưng repo chưa kịp load userDoc/role → màn chờ
    if (!repo.isLoggedIn || repo.currentUser == null) {
      return const _Splash();
    }

    // Điều hướng theo role
    final role = repo.currentUser!.role;
    if (role == UserRole.admin) {
      return const AdminDashboard();
    } else {
      // Waiter: vào chọn bàn (flow mới: seat → open order → gửi món → billed → paid)
      return const TableScreen();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

