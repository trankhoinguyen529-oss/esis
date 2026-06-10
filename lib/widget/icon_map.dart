import 'package:flutter/material.dart';

class CategoryItem {
  static const Map<String, IconData> icons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Medicine': Icons.medical_services,
    'Groceries': Icons.local_grocery_store,
    'Rent': Icons.home,
    'Gifts': Icons.card_giftcard,
    'Savings': Icons.savings,
    'Entertainment': Icons.movie,
    'Salary': Icons.wallet,
    'Work': Icons.work,
    'Gaming': Icons.sports_esports,
    'Others': Icons.more_horiz,
  };
}

class TypeItem {
  static const Map<String, IconData> icons = {
    'All': Icons.menu,
    'Income': Icons.trending_up,
    'Expense': Icons.trending_down,
  };
}
