import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../core/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtl = TextEditingController(text: 'guest@demo.com');
  final passCtl = TextEditingController(text: '123456');
  final keyForm = GlobalKey<FormState>();
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: keyForm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => V.notEmpty(v, 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtl,
                    obscureText: hide,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        icon: Icon(
                          hide ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                    validator: (v) => V.notEmpty(v, 'Mật khẩu'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      // trong onPressed nút Đăng nhập
                      final repo = InheritedApp.of(context);
                      if (!(keyForm.currentState?.validate() ?? false)) return;

                      final msg = await repo.login(
                        email: emailCtl.text.trim(),
                        password: passCtl.text,
                      );
                      if (!mounted) return;
                      if (msg == 'OK') {
                        // KHÔNG điều hướng ở đây. AuthGate sẽ tự chuyển màn.
                        // Có thể show 1 snack bar nhẹ nếu muốn.
                      } else {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Demo: admin@demo.com / 123456 (quyền Admin)'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
