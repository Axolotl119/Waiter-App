import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../core/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();
  final keyForm = GlobalKey<FormState>();
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
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
                      if (!keyForm.currentState!.validate()) return;
                      final r = repo.register(
                        email: emailCtl.text.trim(),
                        password: passCtl.text.trim(),
                      );
                      // ignore: unrelated_type_equality_checks
                      if (r != 'OK') {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(await r)));
                        return;
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Tạo tài khoản'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
