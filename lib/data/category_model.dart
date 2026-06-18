import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final String colorCode;

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorCode,
  });

  /// Chuyển từ Map (SQLite row) sang CategoryModel
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorCode: map['color_code'] as String,
    );
  }

  /// Chuyển CategoryModel sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_code': colorCode,
    };
  }

  /// Trả về đối tượng Color từ mã màu hex (e.g. "FFE67E22" hoặc "#E67E22")
  Color get color {
    try {
      String cleanedHex = colorCode.trim().replaceAll('#', '');
      if (cleanedHex.startsWith('0x') || cleanedHex.startsWith('0X')) {
        cleanedHex = cleanedHex.substring(2);
      }
      if (cleanedHex.length == 6) {
        cleanedHex = 'FF$cleanedHex'; // Thêm alpha channel mặc định
      }
      final intVal = int.parse(cleanedHex, radix: 16);
      return Color(intVal);
    } catch (e) {
      debugPrint('Error parsing color $colorCode: $e');
      return Colors.grey;
    }
  }

  /// Trả về đối tượng IconData từ codePoint
  IconData get icon {
    return IconData(iconCode, fontFamily: 'MaterialIcons');
  }
}
