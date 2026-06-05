import 'package:flutter/material.dart';

class TransactionItem {
  final IconData icon;
  final String title;
  final String time;
  final int day;
  final int month;
  final int year;
  final String tag;
  final String amount;
  final bool negative;

  const TransactionItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.day,
    required this.month,
    required this.year,
    required this.tag,
    required this.amount,
    this.negative = false,
  });
}

class TransactionData {
  static const List<TransactionItem> transactions = [
    TransactionItem(
      icon: Icons.wallet,
      title: 'Salary',
      time: '18:27',
      day: 30,
      month: 6,
      year: 2026,
      tag: 'Monthly',
      amount: '\$4,000.00',
    ),
    TransactionItem(
      icon: Icons.local_grocery_store,
      title: 'Groceries',
      time: '17:00',
      day: 24,
      month: 6,
      year: 2026,
      tag: 'Pantry',
      amount: '-\$100.00',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.home,
      title: 'Rent',
      time: '8:30',
      day: 5,
      month: 6,
      year: 2026,
      tag: 'Rent',
      amount: '-\$674.40',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 5,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 6,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 7,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 8,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 9,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      time: '9:30',
      day: 10,
      month: 6,
      year: 2026,
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
  ];
}
