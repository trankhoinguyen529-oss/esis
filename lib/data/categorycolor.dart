import 'package:flutter/material.dart';

/// `CategoryColor` quản lý bảng màu cố định cho từng danh mục giao dịch.
class CategoryColor {
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

  /// Trả về màu tương ứng với danh mục. Nếu danh mục lạ, tự tạo màu dựa trên mã băm.
  static Color getColor(String category) {
    if (presetColors.containsKey(category)) {
      return presetColors[category]!;
    }
    final int hash = category.hashCode;
    final int index = hash.abs() % dynamicColors.length;
    return dynamicColors[index];
  }
}
