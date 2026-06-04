import 'package:flutter/material.dart';

class TransactionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final String amount;
  final bool negative;

  const TransactionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
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
      subtitle: '18:27 - April 30',
      tag: 'Monthly',
      amount: '\$4,000.00',
    ),
    TransactionItem(
      icon: Icons.local_grocery_store,
      title: 'Groceries',
      subtitle: '17:00 - April 24',
      tag: 'Pantry',
      amount: '-\$100.00',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.home,
      title: 'Rent',
      subtitle: '8:30 - April 15',
      tag: 'Rent',
      amount: '-\$674.40',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 08',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 09',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 10',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 11',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 12',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
    TransactionItem(
      icon: Icons.directions_bus,
      title: 'Transport',
      subtitle: '9:30 - April 13',
      tag: 'Fuel',
      amount: '-\$4.13',
      negative: true,
    ),
  ];
}
