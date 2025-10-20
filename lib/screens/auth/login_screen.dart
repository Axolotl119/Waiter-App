import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../core/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtl = TextEditingController(text: '');
  final passCtl = TextEditingController(text: '');
  final keyForm = GlobalKey<FormState>();
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    InheritedApp.of(context);
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
                      if (!keyForm.currentState!.validate()) return;
                      final repo = InheritedApp.of(context);

                      final msg = await repo.login(
                        email: emailCtl.text.trim(),
                        password: passCtl.text.trim(),
                      );

                      if (!mounted) return;
                      if (msg != 'OK') {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
