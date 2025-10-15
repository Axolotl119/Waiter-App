class V {
  static String? notEmpty(String? v, [String label = 'Trường này']) {
    if (v == null || v.trim().isEmpty) return '$label không được để trống';
    return null;
  }

  static String? positiveInt(String? v, [String label = 'Giá trị']) {
    final n = int.tryParse(v ?? '');
    if (n == null || n <= 0) return '$label phải > 0';
    return null;
  }

  static String? positiveDouble(String? v, [String label = 'Giá trị']) {
    final n = double.tryParse(v ?? '');
    if (n == null || n <= 0) return '$label phải > 0';
    return null;
  }
}
