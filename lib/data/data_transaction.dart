class TransactionItem {
  final int? id;
  final String title;
  final String category;
  final String time;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final bool isBank;

  const TransactionItem({
    this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.date,
    required this.amount,
    this.isExpense = true,
    this.isBank = false,
  });

  /// Chuyển từ Map (SQLite row) sang TransactionItem
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      time: map['time'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      isExpense: (map['is_expense'] as int) == 1,
      isBank: map['is_bank'] == 1,
    );
  }

  /// Chuyển TransactionItem sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'date': date.toIso8601String(),
      'time': time,
      'is_bank': isBank ? 1 : 0
    };
  }
}
