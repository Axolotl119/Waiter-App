import 'package:demodidong/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../models/menu_item_model.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final categories = repo.categories;
    final items = _selectedCategoryId == null
        ? repo.menu
        : repo.menu.where((m) => m.categoryId == _selectedCategoryId).toList();

    final table = repo.selectedTable;
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text(
          table == null
              ? 'Chưa chọn bàn'
              : 'Bàn ${table.name}${table.currentOrderId != null ? " • #${table.currentOrderId!.substring(0,6)}" : ""}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            tooltip: 'Giỏ hàng',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final c = categories[i];
                  final selected = c.id == _selectedCategoryId;
                  return ChoiceChip(
                    label: Text(c.name, overflow: TextOverflow.ellipsis),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedCategoryId = selected ? null : c.id;
                    }),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: categories.length,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) => _MenuTile(item: items[i]),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
              ),
            ),
            const SizedBox(height: 72), // chừa chỗ cho FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/cart'),
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text('Giỏ (${repo.cartItemsCount})'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuItemModel item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(item.name, overflow: TextOverflow.ellipsis),
        subtitle: Text('${item.price.toStringAsFixed(0)} đ'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            repo.addToCart(item);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Đã thêm ${item.name}')));
          },
          tooltip: 'Thêm vào giỏ',
        ),
      ),
    );
  }
}


