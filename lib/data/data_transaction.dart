import 'package:flutter/material.dart';

class TransactionItem {
  final IconData icon;
  final String title;
  final String time;
  final DateTime date;
  final String tag;
  final String amount;
  final bool negative;

  const TransactionItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.date,
    required this.tag,
    required this.amount,
    this.negative = false,
  });
}

class TransactionData {
  static List<TransactionItem> transactions = [
    TransactionItem(
      icon: Icons.wallet,
      title: 'Salary',
      time: '18:27',
      date: DateTime(2026, 6, 30),
      tag: 'Monthly',
      amount: '\$4,000.00',
    ),
    TransactionItem(
      icon: Icons.local_grocery_store,
      title: 'Groceries',
      time: '17:00',
      date: DateTime(2026, 6, 24),
      tag: 'Pantry',
      amount: '-\$100.00',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.home,
      title: 'Rent',
      time: '8:30',
      date: DateTime(2026, 6, 5),
      tag: 'Rent',
      amount: '-\$674.40',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 5),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 6),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 7),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 8),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 9),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      date: DateTime(2026, 6, 10),
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
  ];
}
