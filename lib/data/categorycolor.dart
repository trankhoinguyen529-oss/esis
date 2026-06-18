import 'package:flutter/material.dart';

/// `CategoryColor` quản lý bảng màu cố định cho từng danh mục giao dịch.
class CategoryColor {
  // Cache lưu các màu load từ database
  static final Map<String, Color> _dbColors = {};

  static const Map<String, Color> presetColors = {
    'Food': Color(0xFFE67E22), // Cam
    'Transport': Color(0xFF3498DB), // Xanh dương
    'Medicine': Color(0xFFE74C3C), // Đỏ
    'Groceries': Color(0xFF2ECC71), // Xanh lá
    'Rent': Color(0xFF9B59B6), // Tím
    'Gifts': Color(0xFFF1C40F), // Vàng
    'Savings': Color(0xFF1ABC9C), // Ngọc bích
    'Entertainment': Color(0xFFE84393), // Hồng
    'Salary': Color(0xFF27AE60), // Xanh lá đậm
    'Work': Color(0xFF8D6E63), // Nâu
    'Gaming': Color(0xFF3F51B5), // Chàm
    'Others': Color(0xFF7F8C8D), // Xám
  };

  static const List<Color> dynamicColors = [
    Color(0xFF16A085),
    Color(0xFF2980B9),
    Color(0xFF8E44AD),
    Color(0xFFD35400),
    Color(0xFFC0392B),
    Color(0xFFD6A2E8),
    Color(0xFF1B9CFC),
    Color(0xFFFD79A8),
    Color(0xFF00CEC9),
    Color(0xFF6C5CE7),
  ];

  /// Cập nhật cache từ database
  static void updateCache(Map<String, String> categoryColorsHex) {
    _dbColors.clear();
    categoryColorsHex.forEach((category, hexStr) {
      final color = _parseColor(hexStr);
      if (color != null) {
        _dbColors[category] = color;
      }
    });
  }

  /// Parse mã màu từ String thành Color
  static Color? _parseColor(String hexStr) {
    try {
      String cleanedHex = hexStr.trim().replaceAll('#', '');
      if (cleanedHex.startsWith('0x') || cleanedHex.startsWith('0X')) {
        cleanedHex = cleanedHex.substring(2);
      }
      if (cleanedHex.length == 6) {
        cleanedHex = 'FF$cleanedHex'; // Thêm alpha channel mặc định là FF
      }
      final intVal = int.parse(cleanedHex, radix: 16);
      return Color(intVal);
    } catch (e) {
      debugPrint('Error parsing color $hexStr: $e');
      return null;
    }
  }

  /// Trả về màu tương ứng với danh mục. Nếu danh mục lạ, tự tạo màu dựa trên mã băm.
  static Color getColor(String category) {
    if (_dbColors.containsKey(category)) {
      return _dbColors[category]!;
    }
    if (presetColors.containsKey(category)) {
      return presetColors[category]!;
    }
    final int hash = category.hashCode;
    final int index = hash.abs() % dynamicColors.length;
    return dynamicColors[index];
  }
}
