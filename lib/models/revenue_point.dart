class RevenuePoint {
  final DateTime bucket; // mốc ngày hoặc tháng
  final double total;    // tổng doanh thu (VND)
  final int orders;      // số đơn

  RevenuePoint({
    required this.bucket,
    required this.total,
    required this.orders,
  });
}

enum RevenueGroupBy { day, month }

