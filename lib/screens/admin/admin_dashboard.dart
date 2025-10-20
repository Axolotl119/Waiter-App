import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/firestore_paths.dart';
import '../../data/app_repository.dart';
import '../../models/table_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/category_model.dart';
import '../../models/revenue_point.dart';
import '../../widgets/app_drawer.dart';

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
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {})); // cập nhật selected trong Drawer/AppBar
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // nhận tab ban đầu khi navigate từ Drawer (arguments: {'tab': int})
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['tab'] is int) {
      final t = (args['tab'] as int).clamp(0, 2);
      if (_tab.index != t) _tab.index = t;
    }
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
      // Drawer role-aware: truyền index + callback để sync Tab khi đang ở Admin
      drawer: AppDrawer(
        currentIndex: _tab.index,
        onSelectIndex: (i) {
          _tab.index = i;
          setState(() {}); // để AppBar/Drawer reflect đúng trạng thái
        },
        onLogout: () async {
          await repo.logout();
        },
      ),
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.table_bar), text: 'Bàn'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Món ăn'),
            Tab(icon: Icon(Icons.auto_graph), text: 'Doanh thu'),
          ],
        ),
      ),
      // ⛔ KHÔNG wrap TabBarView trong AnimatedBuilder để tránh lệch nhịp → màn đen.
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(), // chỉ đổi tab bằng TabBar/Drawer
        children: const [
          _TablesCrudTab(),
          _MenuCrudTab(),
          _RevenueTab(),
        ],
      ),
    );
  }
}

/// ================= TAB 1: BÀN (CRUD) =================

class _TablesCrudTab extends StatelessWidget {
  const _TablesCrudTab();

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return AnimatedBuilder(
      animation: repo, // chỉ tab này rebuild theo repo
      builder: (_, __) {
        final tables = repo.tables;
        if (tables.isEmpty) {
          return const Center(child: Text('Chưa có bàn nào'));
        }
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            int cross = 2;
            if (w >= 1200) cross = 4;
            else if (w >= 900) cross = 3;
            else if (w >= 600) cross = 2;
            else cross = 1;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) => _TableCrudCard(t: tables[i]),
            );
          },
        );
      },
    );
  }
}

class _TableCrudCard extends StatelessWidget {
  final TableModel t;
  const _TableCrudCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final color = switch (t.state) {
      TableState.vacant => Colors.green,
      TableState.occupied => Colors.orange,
      TableState.billed => Colors.red,
      TableState.cleaning => Colors.blueGrey,
      TableState.reserved => Colors.purple,
    };

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Chip(
                  label: Text(_labelState(t.state), overflow: TextOverflow.ellipsis),
                  backgroundColor: color.withOpacity(.12),
                  side: BorderSide(color: color),
                  labelStyle: TextStyle(color: color.shade700),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showTableForm(context, existing: t);
                    } else if (v == 'delete') {
                      _deleteTable(context, t);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xoá')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Sức chứa: ${t.capacity}'),
            if ((t.currentOrderId ?? '').isNotEmpty)
              Text('Order: #${t.currentOrderId!.substring(0, 6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showTableForm(context, existing: t),
                  icon: const Icon(Icons.edit),
                  label: const Text('Sửa'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteTable(context, t),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xoá'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelState(TableState s) => switch (s) {
        TableState.vacant => 'Trống',
        TableState.occupied => 'Đang phục vụ',
        TableState.billed => 'Chờ thanh toán',
        TableState.cleaning => 'Đang dọn',
        TableState.reserved => 'Đã đặt',
      };
}

Future<void> _deleteTable(BuildContext context, TableModel t) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xoá bàn?'),
      content: Text(
        t.state == TableState.vacant
            ? 'Bạn có chắc muốn xoá ${t.name}?'
            : 'Bàn đang không trống, xoá có thể làm mất liên kết order.\nBạn có chắc muốn xoá ${t.name}?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
      ],
    ),
  );
  if (ok != true) return;

  const rid = 'default_restaurant';
  await FirebaseFirestore.instance.collection(FP.tables(rid)).doc(t.id).delete();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xoá ${t.name}')));
}

Future<void> _showTableForm(BuildContext context, {TableModel? existing}) async {
  final nameCtl = TextEditingController(text: existing?.name ?? '');
  final capCtl = TextEditingController(text: existing?.capacity.toString() ?? '2');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Thêm bàn' : 'Sửa bàn',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Tên bàn', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Sức chứa', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu'),
                    onPressed: () async {
                      final name = nameCtl.text.trim();
                      final capacity = int.tryParse(capCtl.text.trim());
                      if (name.isEmpty || capacity == null || capacity <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên & sức chứa hợp lệ')),
                        );
                        return;
                      }

                      const rid = 'default_restaurant';
                      final col = FirebaseFirestore.instance.collection(FP.tables(rid));

                      if (existing == null) {
                        await col.add({
                          'name': name,
                          'capacity': capacity,
                          'isAvailable': true,
                          'currentOrderId': null,
                          'state': 'vacant',
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Đã thêm bàn $name')));
                      } else {
                        await col.doc(existing.id).update({
                          'name': name,
                          'capacity': capacity,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Đã cập nhật ${existing.name}')));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// ================= TAB 2: MÓN ĂN (CRUD) =================

class _MenuCrudTab extends StatefulWidget {
  const _MenuCrudTab();

  @override
  State<_MenuCrudTab> createState() => _MenuCrudTabState();
}

class _MenuCrudTabState extends State<_MenuCrudTab> {
  String _keyword = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    return AnimatedBuilder(
      animation: repo,
      builder: (_, __) {
        final categories = repo.categories;
        final allItems = repo.menu;
        final items = allItems.where((m) {
          final okCat = _categoryId == null || m.categoryId == _categoryId;
          final okKw = m.name.toLowerCase().contains(_keyword.toLowerCase());
          return okCat && okKw;
        }).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm món…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (s) => setState(() => _keyword = s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _categoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                        ...categories.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Không có món phù hợp'))
                  : LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        int cross = 2;
                        if (w >= 1200) cross = 4;
                        else if (w >= 900) cross = 3;
                        else if (w >= 600) cross = 2;
                        else cross = 1;
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _MenuCrudCard(
                            item: items[i],
                            category: categories.firstWhere(
                              (c) => c.id == items[i].categoryId,
                              orElse: () => CategoryModel(id: '', name: 'Khác'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuCrudCard extends StatelessWidget {
  final MenuItemModel item;
  final CategoryModel category;
  const _MenuCrudCard({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Danh mục: ${category.name}', overflow: TextOverflow.ellipsis),
            Text('Giá: ${item.price.toStringAsFixed(0)} đ'),
            if ((item.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            const Spacer(),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showMenuForm(context, existing: item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Sửa'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteMenuItem(context, item),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xoá'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteMenuItem(BuildContext context, MenuItemModel item) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xoá món?'),
      content: Text('Bạn có chắc muốn xoá "${item.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
      ],
    ),
  );
  if (ok != true) return;

  const rid = 'default_restaurant';
  await FirebaseFirestore.instance.collection(FP.menuItems(rid)).doc(item.id).delete();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xoá ${item.name}')));
}

Future<void> _showMenuForm(BuildContext context, {MenuItemModel? existing}) async {
  final repo = InheritedApp.of(context);
  final categories = repo.categories;

  String? categoryId = existing?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
  final nameCtl = TextEditingController(text: existing?.name ?? '');
  final priceCtl = TextEditingController(text: existing?.price.toStringAsFixed(0) ?? '');
  final descCtl = TextEditingController(text: existing?.description ?? '');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Thêm món' : 'Sửa món',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryId,
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => categoryId = v,
                decoration: const InputDecoration(
                  labelText: 'Danh mục', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Tên món', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá (VND)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtl,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tuỳ chọn)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu'),
                    onPressed: () async {
                      final name = nameCtl.text.trim();
                      final price = double.tryParse(priceCtl.text.trim());
                      if (categoryId == null || name.isEmpty || price == null || price < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng điền đầy đủ & hợp lệ')),
                        );
                        return;
                      }

                      const rid = 'default_restaurant';
                      final col = FirebaseFirestore.instance.collection(FP.menuItems(rid));

                      if (existing == null) {
                        await col.add({
                          'name': name,
                          'price': price,
                          'categoryId': categoryId,
                          'description': descCtl.text.trim().isEmpty ? null : descCtl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm món $name')),
                        );
                      } else {
                        await col.doc(existing.id).update({
                          'name': name,
                          'price': price,
                          'categoryId': categoryId,
                          'description': descCtl.text.trim().isEmpty ? null : descCtl.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cập nhật ${existing.name}')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// ================= TAB 3: DOANH THU =================

class _RevenueTab extends StatefulWidget {
  const _RevenueTab();

  @override
  State<_RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<_RevenueTab> {
  int _days = 14;
  RevenueGroupBy _groupBy = RevenueGroupBy.day;

  Future<List<RevenuePoint>> _load(BuildContext context) async {
    final repo = InheritedApp.of(context);
    final now = DateTime.now();
    if (_groupBy == RevenueGroupBy.day) {
      final from = now.subtract(Duration(days: _days));
      final to = now.add(const Duration(days: 1));
      return repo.fetchRevenue(from: from, to: to, groupBy: _groupBy);
    } else {
      final startMonth = DateTime(now.year, now.month - 11, 1);
      final endMonth = DateTime(now.year, now.month + 1, 1);
      return repo.fetchRevenue(from: startMonth, to: endMonth, groupBy: _groupBy);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Không cần AnimatedBuilder ở đây vì dữ liệu lấy qua Future khi đổi filter
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              DropdownButton<int>(
                value: _days,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 ngày')),
                  DropdownMenuItem(value: 14, child: Text('14 ngày')),
                  DropdownMenuItem(value: 30, child: Text('30 ngày')),
                ],
                onChanged: _groupBy == RevenueGroupBy.day
                    ? (v) => setState(() => _days = v!)
                    : null,
              ),
              const SizedBox(width: 12),
              SegmentedButton<RevenueGroupBy>(
                segments: const [
                  ButtonSegment(value: RevenueGroupBy.day, label: Text('Theo ngày')),
                  ButtonSegment(value: RevenueGroupBy.month, label: Text('Theo tháng')),
                ],
                selected: {_groupBy},
                onSelectionChanged: (s) => setState(() => _groupBy = s.first),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<RevenuePoint>>(
            future: _load(context),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data ?? const <RevenuePoint>[];
              if (data.isEmpty) {
                return const Center(child: Text('Chưa có dữ liệu doanh thu'));
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: _RevenueBarChart(points: data, groupBy: _groupBy),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<RevenuePoint> points;
  final RevenueGroupBy groupBy;
  const _RevenueBarChart({required this.points, required this.groupBy});

  @override
  Widget build(BuildContext context) {
    final fmtDay = DateFormat('dd/MM');
    final fmtMonth = DateFormat('MM/yy');

    final bars = <BarChartGroupData>[];
    double maxY = 0;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.total > maxY) maxY = p.total;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: p.total,
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    if (maxY == 0) maxY = 1;

    int step = 1;
    if (points.length > 24) step = 3;
    if (points.length > 40) step = 5;

    return BarChart(
      BarChartData(
        barGroups: bars,
        minY: 0,
        maxY: maxY * 1.15,
        gridData: FlGridData(show: true, horizontalInterval: maxY / 4),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(_abbr(v)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                if (i % step != 0) return const SizedBox.shrink();
                final dt = points[i].bucket;
                final label = groupBy == RevenueGroupBy.day
                    ? fmtDay.format(dt)
                    : fmtMonth.format(dt);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.6,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) {
              final p = points[g.x.toInt()];
              final dateStr = groupBy == RevenueGroupBy.day
                  ? DateFormat('EEE, dd/MM/yyyy').format(p.bucket)
                  : DateFormat('MM/yyyy').format(p.bucket);
              return BarTooltipItem(
                '$dateStr\n',
                const TextStyle(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Doanh thu: ${_vnd(p.total)}\n'),
                  TextSpan(text: 'Số đơn: ${p.orders}'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _abbr(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  static String _vnd(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if ((idx - 1) % 3 == 0 && i != s.length - 1) b.write('.');
    }
    return '${b.toString()} đ';
  }
}




