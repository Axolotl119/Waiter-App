import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../widgets/app_drawer.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu ${repo.selectedTable != null ? "• ${repo.selectedTable!.name}" : ""}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: repo.menu.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = repo.menu[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.fastfood),
              title: Text(m.name),
              subtitle: Text('${m.category} • ${_vnd(m.price)}'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => repo.addToCart(m),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _vnd(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i - 1;
    b.write(s[i]);
    if (left > 0 && left % 3 == 0) b.write('.');
  }
  return '${b} đ';
}
