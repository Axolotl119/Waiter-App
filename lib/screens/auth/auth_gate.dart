// lib/screens/auth/auth_gate.dart (hoặc ngay dưới main.dart)
import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import 'login_screen.dart';
import '../waiter/menu_screen.dart'; // hoặc màn bạn muốn vào sau login

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return AnimatedBuilder(
      animation: repo,
      builder: (_, __) {
        // Chưa login -> LoginScreen
        if (!repo.isLoggedIn) return const LoginScreen();
        // Đã login -> vào app (ví dụ chọn bàn)
        return const MenuScreen();
      },
    );
  }
}
