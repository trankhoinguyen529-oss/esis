import 'package:a_management/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class CategoryItem {
  final int? id;
  final String userId;
  final IconData icon;
  final String title;

  const CategoryItem({
    this.id,
    required this.userId,
    required this.icon,
    required this.title,
  });

  /// Chuyển từ Map (SQLite row) sang TransactionItem
  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as int?,
      userId: DatabaseService().currentUserId,
      icon: IconData(map['icon_code'] as int, fontFamily: 'MaterialIcons'),
      title: map['title'] as String,
    );
  }

  /// Chuyển TransactionItem sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'icon_code': icon.codePoint,
    };
  }
}
