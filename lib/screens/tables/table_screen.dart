import 'package:demodidong/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import '../../data/app_repository.dart';
import '../../models/table_model.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final tables = repo.tables
        .where((t) => t.name.toLowerCase().contains(_keyword.toLowerCase()))
        .toList();

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Chọn bàn'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm bàn…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (s) => setState(() => _keyword = s),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _TableGrid(tables: tables),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableGrid extends StatelessWidget {
  final List<TableModel> tables;
  const _TableGrid({required this.tables});

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const Center(child: Text('Không có bàn phù hợp'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
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
            childAspectRatio: 1.35,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) => _TableCard(t: tables[i]),
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel t;
  const _TableCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final repo = InheritedApp.of(context);
    final hasOrder = (t.currentOrderId ?? '').isNotEmpty;

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
                  child: Text(
                    t.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                _StateChip(state: t.state),
              ],
            ),
            const SizedBox(height: 6),
            Text('Sức chứa: ${t.capacity}'),
            if (hasOrder)
              Text(
                'Order: #${t.currentOrderId!.substring(0, 6)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (t.state == TableState.vacant)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.event_seat),
                    label: const Flexible(child: Text('Nhận khách', overflow: TextOverflow.ellipsis)),
                    onPressed: () async {
                      await repo.seatTable(t);
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/menu');
                    },
                  ),
                if (t.state == TableState.occupied || t.state == TableState.billed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Flexible(child: Text('Xem order', overflow: TextOverflow.ellipsis)),
                    onPressed: () {
                      repo.selectTable(t);
                      Navigator.pushNamed(context, '/order'); // nhớ khai báo route
                    },
                  ),
                if (t.state == TableState.occupied)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Flexible(child: Text('Xin tính tiền', overflow: TextOverflow.ellipsis)),
                    onPressed: () async {
                      repo.selectTable(t);
                      await repo.requestBill();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chuyển trạng thái: chờ thanh toán')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final TableState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    String label; MaterialColor color;
    switch (state) {
      case TableState.vacant: label = 'Trống'; color = Colors.green; break;
      case TableState.occupied: label = 'Đang phục vụ'; color = Colors.orange; break;
      case TableState.billed: label = 'Chờ thanh toán'; color = Colors.red; break;
      case TableState.cleaning: label = 'Đang dọn'; color = Colors.blueGrey; break;
      case TableState.reserved: label = 'Đã đặt'; color = Colors.purple; break;
    }
    return Chip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      backgroundColor: color.withOpacity(.12),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color.shade700),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

