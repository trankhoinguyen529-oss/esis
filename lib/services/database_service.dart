import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/data_transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'transactions.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            icon_code INTEGER NOT NULL,
            amount REAL NOT NULL,
            is_expense INTEGER NOT NULL DEFAULT 1,
            date TEXT NOT NULL,
            time TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Thêm giao dịch mới vào DB
  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    return await db.insert('transactions', item.toMap());
  }

  /// Lấy tất cả giao dịch (không lọc) – dùng cho Transaction screen filter = -1
  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, time DESC',
    );
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  /// Lấy giao dịch theo kỳ: 0=Daily, 1=Weekly, 2=Monthly
  Future<List<TransactionItem>> getTransactionsByPeriod(int period) async {
    final all = await getAllTransactions();
    return _filterByPeriod(all, period);
  }

  /// Tính income và expense theo kỳ
  Future<Map<String, double>> getSummaryByPeriod(int period) async {
    final items =
        period == -1 ? await getAllTransactions() : await getTransactionsByPeriod(period);
    double income = 0;
    double expense = 0;
    for (final item in items) {
      if (item.isExpense) {
        expense += item.amount;
      } else {
        income += item.amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  List<TransactionItem> _filterByPeriod(List<TransactionItem> all, int period) {
    final now = DateTime.now();
    return all.where((item) {
      if (period == 0) {
        // Daily: cùng ngày
        return item.date.year == now.year &&
            item.date.month == now.month &&
            item.date.day == now.day;
      } else if (period == 1) {
        // Weekly: trong vòng 7 ngày của tuần hiện tại
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final d = DateTime(item.date.year, item.date.month, item.date.day);
        final s = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final e = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return !d.isBefore(s) && !d.isAfter(e);
      } else {
        // Monthly: cùng tháng & năm
        return item.date.year == now.year && item.date.month == now.month;
      }
    }).toList();
  }
}
