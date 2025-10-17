import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../widgets/app_drawer.dart';

class SelectTableScreen extends StatelessWidget {
  const SelectTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn bàn')),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: repo.tables.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final t = repo.tables[i];
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.table_bar,
                color: t.isAvailable ? Colors.green : Colors.red,
              ),
              title: Text(t.name),
              subtitle: Text(
                'Sức chứa: ${t.capacity} • ${t.isAvailable ? 'Còn trống' : 'Đang bận'}',
              ),
              onTap: t.isAvailable
                  ? () {
                      repo.selectTable(t);
                      Navigator.pushReplacementNamed(context, '/menu');
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }
}
