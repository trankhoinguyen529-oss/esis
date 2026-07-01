import 'package:a_management/data/data_category.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/data_transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // ─── Lấy UID của người dùng hiện tại ───────────────────────
  String get currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No user is currently logged in.');
    return uid;
  }

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
      version: 6,
      onCreate: (db, version) async {
        await _createTransactionTable(db);
        await _createSyncedEmailsTable(db);
        await _createAppSettingsTable(db);
        await _createCategoryTable(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          // ✅ thêm cột is_bank cho DB cũ chưa có
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN is_bank INTEGER NOT NULL DEFAULT 0",
          );
        }
        if (oldVersion < 5) {
          if (oldVersion >= 3) {
            // Migrate synced_emails table
            await db.execute(
                "ALTER TABLE synced_emails RENAME TO synced_emails_old");
            await _createSyncedEmailsTable(db);
            await db.execute('''
              INSERT OR IGNORE INTO synced_emails (message_id, user_id, synced_at)
              SELECT message_id, user_id, synced_at FROM synced_emails_old
            ''');
            await db.execute("DROP TABLE synced_emails_old");

            // Migrate app_settings table
            await db
                .execute("ALTER TABLE app_settings RENAME TO app_settings_old");
            await _createAppSettingsTable(db);
            final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
            await db.execute('''
              INSERT OR IGNORE INTO app_settings (key, user_id, value)
              SELECT key, '$currentUid', value FROM app_settings_old
            ''');
            await db.execute("DROP TABLE app_settings_old");
          } else {
            // Fresh tables for users coming from version < 3
            await _createSyncedEmailsTable(db);
            await _createAppSettingsTable(db);
          }
        }
        if (oldVersion < 6) {
          // ⬅️ tạo bảng category + seed default cho user cũ
          await _createCategoryTable(db);
          await _seedDefaultCategories(db);
        }
      },
    );
  }

  //tao db transaction
  Future<void> _createTransactionTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL DEFAULT 1,
        is_bank INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  //tao db category
  Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');
  }

  //tao db sync email
  Future<void> _createSyncedEmailsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS synced_emails (
        message_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        synced_at TEXT NOT NULL,
        PRIMARY KEY (message_id, user_id)
      )
    ''');
  }

  //tao db setting
  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT NOT NULL,
        user_id TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (key, user_id)
      )
    ''');
  }

  // ─── Transaction ────────────────────────────────────────────────────

  /// Thêm giao dịch mới vào DB (tự gắn user_id hiện tại)
  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    final map = item.toMap();
    map['user_id'] = currentUserId;
    final id = await db.insert('transactions', map);
    // In lại toàn bộ bảng sau mỗi lần thêm để debug
    await printAllTransactions();
    return id;
  }

  // Xoá giao dịch trong DB của user hiện tại theo ID giao dich
  Future<int?> deleteTransaction(int? id) async {
    final db = await database;
    await db.delete(
      'transactions', // tên bảng
      where: 'id = ?', // điều kiện
      whereArgs: [id], // giá trị thay vào ?
    );
    // In lại toàn bộ bảng sau mỗi lần thêm để debug
    await printAllTransactions();
    return id;
  }

  /// Cập nhật giao dịch hiện tại theo id và user hiện tại
  Future<int> updateTransaction(TransactionItem item) async {
    if (item.id == null) {
      throw ArgumentError.value(
          item, 'item', 'Transaction id must not be null');
    }
    final db = await database;
    final map = item.toMap();
    map['user_id'] = currentUserId;
    final count = await db.update(
      'transactions',
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [item.id, currentUserId],
    );
    await printAllTransactions();
    return count;
  }

  /// Lấy tất cả giao dịch của user hiện tại
  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [currentUserId],
      orderBy: 'date DESC, time DESC',
    );
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  /// Lấy giao dịch theo ID của user hiện tại
  Future<TransactionItem?> getTransactionItem_byID(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, currentUserId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionItem.fromMap(maps.first);
  }

  /// Lấy giao dịch theo kỳ: 0=Daily, 1=Weekly, 2=Monthly
  Future<List<TransactionItem>> getTransactionsByPeriod(int period) async {
    final all = await getAllTransactions();
    return _filterByPeriod(all, period);
  }

  // Lấy giao dịch theo category
  Future<List<TransactionItem>> getTransactionsByCategory(
      String category) async {
    final all = await getAllTransactions();
    return all.where((item) {
      return (item.category == category);
    }).toList();
  }

  // Lấy giao dịch theo bộ lọc
  Future<List<TransactionItem>> getTransactionsByFilter({
    required String type, //income_expense
    required String bank, // bank?
    required Set<String> categories,
    required String title,
    required double amountFrom,
    required double amountTo,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final all = await getAllTransactions();
    bool isExpense = (type == 'Expense') ? true : false;
    bool isBank = (bank == 'Bank') ? true : false;
    return all.where((item) {
      return ((item.title == title || title == '') &&
          (item.amount <= amountTo && item.amount >= amountFrom) &&
          (item.isExpense == isExpense || type == 'All') &&
          (!(item.date).isBefore(dateFrom) && !(item.date).isAfter(dateTo)) &&
          (categories.contains(item.category) ||
              categories.isEmpty ||
              categories.contains('All')) &&
          (item.isBank == isBank || bank == 'All'));
    }).toList();
  }

  /// Tính income và expense theo kỳ
  Future<Map<String, double>> getSummaryByPeriod(int period) async {
    final items = period == -1
        ? await getAllTransactions()
        : await getTransactionsByPeriod(period);
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

  //Tính income và expense theo bộ lọc
  Future<Map<String, double>> getSummaryByFilter(
    String type,
    String bank,
    Set<String> categories,
    String title,
    double amountFrom,
    double amountTo,
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    final items = await getTransactionsByFilter(
      type: type,
      categories: categories,
      title: title,
      amountFrom: amountFrom,
      amountTo: amountTo,
      dateFrom: dateFrom,
      dateTo: dateTo,
      bank: bank,
    );

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
        final s =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final e = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return !d.isBefore(s) && !d.isAfter(e);
      } else {
        // Monthly: cùng tháng & năm
        return item.date.year == now.year && item.date.month == now.month;
      }
    }).toList();
  }

  // ─────────────────────────────────────────────
  // DEBUG ONLY – in toàn bộ bảng transactions ra console
  // ─────────────────────────────────────────────
  Future<void> printAllTransactions() async {
    final db = await database;

    // Lấy raw rows (tất cả user) để thấy đầy đủ khi debug
    final rows = await db.query('transactions', orderBy: 'id ASC');

    if (rows.isEmpty) {
      // ignore: avoid_print
      print('══════════════════════════════════════════════');
      // ignore: avoid_print
      print('📋 [DB] Bảng transactions: TRỐNG');
      // ignore: avoid_print
      print('══════════════════════════════════════════════');
      return;
    }

    // ignore: avoid_print
    print('\n══════════════════════════════════════════════');
    // ignore: avoid_print
    print('📋 [DB] Bảng transactions – ${rows.length} bản ghi');
    // ignore: avoid_print
    print('──────────────────────────────────────────────');

    for (final row in rows) {
      final isExpense = (row['is_expense'] as int) == 1;
      final typeIcon = isExpense ? '🔴 Chi tiêu' : '🟢 Thu nhập';
      final uid = (row['user_id'] as String);
      final shortUid = uid.length > 8 ? '${uid.substring(0, 8)}…' : uid;
      // ignore: avoid_print
      print(
        'ID: ${row['id']}'
        ' | user: $shortUid'
        ' | ${row['title']}'
        ' (${row['category']})'
        ' | $typeIcon'
        ' | \$${(row['amount'] as num).toStringAsFixed(2)}'
        ' | ${(row['date'] as String).substring(0, 10)}'
        ' ${row['time']}'
        ' | 🏦 ${(row['is_bank'] as int?) == 1 ? 'Bank' : 'Manual'}', // ✅ thêm vào đây
      );
    }

    // ignore: avoid_print
    print('══════════════════════════════════════════════\n');
  }

  // ─── Synced Emails Helper ──────────────────────────────────

  Future<bool> isEmailSynced(String messageId) async {
    final db = await database;
    final maps = await db.query(
      'synced_emails',
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<void> markEmailSynced(String messageId) async {
    final db = await database;
    await db.insert(
      'synced_emails',
      {
        'message_id': messageId,
        'user_id': currentUserId,
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Settings Helper ────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ? AND user_id = ?',
      whereArgs: [key, currentUserId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'user_id': currentUserId,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'app_settings',
      where: 'key = ? AND user_id = ?',
      whereArgs: [key, currentUserId],
    );
  }

  // ─── Category ────────────────────────────────────────────────────

  // Category default
  Future<void> _seedDefaultCategories(Database db) async {
    const Map<String, IconData> icons = {
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
      'Bank': Icons.account_balance_rounded,
      'All': Icons.menu,
    };

    final batch = db.batch();
    int id = 1;
    for (final entry in icons.entries) {
      batch.insert('category', {
        'id': id,
        'user_id': '0',
        'title': entry.key,
        'icon_code': entry.value.codePoint,
      });
      id++;
    }
    await batch.commit(noResult: true);
  }

  /// Thêm category mới vào DB (tự gắn user_id hiện tại)
  Future<int> insertCategory(CategoryItem item) async {
    final db = await database;
    final map = item.toMap();
    map['user_id'] = currentUserId;
    final id = await db.insert('category', map);
    // In lại toàn bộ bảng sau mỗi lần thêm để debug
    await printAllTransactions();
    return id;
  }

  /// Xoá toàn bộ category của user không phải user mặc định (user_id != '0')
  Future<void> clearUserCategories() async {
    final db = await database;
    await db.delete(
      'category',
      where: 'user_id != ?',
      whereArgs: ['0'],
    );
  }

  /// Reset category về dữ liệu mặc định cho user 0
  Future<void> resetCategoryDatabase() async {
    final db = await database;
    await clearUserCategories();
    await db.delete('category', where: 'user_id = ?', whereArgs: ['0']);
    await _seedDefaultCategories(db);
  }

  /// Lấy category theo ID của user hiện tại
  Future<List<CategoryItem>> getCategory() async {
    final db = await database;
    final maps = await db.query(
      'category',
      where: 'user_id = ? OR user_id = ?',
      whereArgs: [0, currentUserId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => CategoryItem.fromMap(m)).toList();
  }

  // Xoá category trong DB của user hiện tại theo ID giao dich
  Future<int?> deleteCategory(int? id) async {
    final db = await database;
    await db.delete(
      'category', // tên bảng
      where: 'id = ?', // điều kiện
      whereArgs: [id], // giá trị thay vào ?
    );
    // In lại toàn bộ bảng sau mỗi lần thêm để debug
    await printAllTransactions();
    return id;
  }
}
