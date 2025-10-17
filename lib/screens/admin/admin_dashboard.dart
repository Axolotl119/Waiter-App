import 'package:demodidong/models/menu_item_model.dart';
import 'package:demodidong/models/table_model.dart';
import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../core/validators.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Quản trị'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.table_bar), text: 'Bàn'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Món'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: repo,
        builder: (_, __) => TabBarView(
          controller: _tab,
          children: [
            _TablesTab(repo: repo),
            _MenuTab(repo: repo),
          ],
        ),
      ),
    );
  }
}

class _TablesTab extends StatelessWidget {
  final AppRepository repo;
  const _TablesTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(title: 'Danh sách bàn', onAdd: () => _editTable(context)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: repo.tables.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = repo.tables[i];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: t.isAvailable ? Colors.green : Colors.red,
                  ),
                  title: Text('${t.name} • ${t.capacity} chỗ'),
                  subtitle: Text(t.isAvailable ? 'Còn trống' : 'Đang bận'),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTable(context, id: t.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.deleteTable(t.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editTable(BuildContext context, {String? id}) async {
    final t = id == null ? null : repo.tables.firstWhere((x) => x.id == id);
    final nameCtl = TextEditingController(text: t?.name ?? '');
    final capCtl = TextEditingController(text: t?.capacity.toString() ?? '');
    bool avail = t?.isAvailable ?? true;
    final key = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id == null ? 'Thêm bàn' : 'Sửa bàn',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Tên/Số bàn'),
                validator: (v) => V.notEmpty(v, 'Tên bàn'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: capCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sức chứa'),
                validator: (v) => V.positiveInt(v, 'Sức chứa'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Còn trống'),
                value: avail,
                onChanged: (v) {
                  avail = v;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!key.currentState!.validate()) return;
                        final cap = int.parse(capCtl.text.trim());
                        if (id == null) {
                          repo.addTable(
                            TableModel(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              name: nameCtl.text.trim(),
                              capacity: cap,
                              isAvailable: avail,
                            ),
                          );
                        } else {
                          repo.updateTable(
                            id,
                            name: nameCtl.text.trim(),
                            capacity: cap,
                            isAvailable: avail,
                          );
                        }
                        Navigator.pop(context);
                      },
                      child: Text(id == null ? 'Thêm' : 'Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  final AppRepository repo;
  const _MenuTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(title: 'Danh sách món', onAdd: () => _editItem(context)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: repo.menu.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = repo.menu[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text(m.name),
                  subtitle: Text('${m.categoryId} • ${_vnd(m.price)}'),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editItem(context, id: m.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.deleteMenuItem(m.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editItem(BuildContext context, {String? id}) async {
    final it = id == null ? null : repo.menu.firstWhere((x) => x.id == id);
    final nameCtl = TextEditingController(text: it?.name ?? '');
    final priceCtl = TextEditingController(
      text: it?.price.toStringAsFixed(0) ?? '',
    );
    final catCtl = TextEditingController(text: it?.categoryId ?? '');
    final key = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id == null ? 'Thêm món' : 'Sửa món',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Tên món'),
                validator: (v) => V.notEmpty(v, 'Tên món'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                validator: (v) => V.positiveDouble(v, 'Giá'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: catCtl,
                decoration: const InputDecoration(labelText: 'Loại'),
                validator: (v) => V.notEmpty(v, 'Loại'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!key.currentState!.validate()) return;
                        final price = double.parse(priceCtl.text.trim());
                        if (id == null) {
                          repo.addMenuItem(
                            MenuItemModel(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              name: nameCtl.text.trim(),
                              price: price,
                              categoryId: catCtl.text.trim(),
                            ),
                          );
                        } else {
                          repo.updateMenuItem(
                            id,
                            name: nameCtl.text.trim(),
                            price: price,
                            category: catCtl.text.trim(),
                          );
                        }
                        Navigator.pop(context);
                      },
                      child: Text(id == null ? 'Thêm' : 'Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _header({required String title, required VoidCallback onAdd}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        ),
      ],
    ),
  );
}

String _vnd(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i - 1;
    b.write(s[i]);
    if (left > 0 && left % 3 == 0) b.write('.');
  }
  return '$b đ';
}
