import 'dart:convert';
import 'dart:io';
import 'package:a_management/data/data_category.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
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

  String get backendBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
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
      version: 9,
      onCreate: (db, version) async {
        await _createTransactionTable(db);
        await _createSyncedEmailsTable(db);
        await _createAppSettingsTable(db);
        await _createCategoryTable(db);
        await _seedDefaultCategories(db);
        await _createSavingExpenditureTable(db);
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
        if (oldVersion < 7) {
          // Remove icon_code column from transactions table
          // SQLite doesn't support DROP COLUMN, so we need to recreate the table
          try {
            await db.execute(
              "ALTER TABLE transactions RENAME TO transactions_old",
            );
            await _createTransactionTable(db);
            await db.execute('''
              INSERT INTO transactions (id, user_id, title, category, amount, is_expense, is_bank, date, time)
              SELECT id, user_id, title, category, amount, is_expense, is_bank, date, time FROM transactions_old
            ''');
            await db.execute("DROP TABLE transactions_old");
          } catch (e) {
            debugPrint('Migration v7 failed: $e');
          }
        }
        if (oldVersion < 8) {
          await _createSavingExpenditureTable(db);
        }
        if (oldVersion < 9) {
          try {
            await db.execute(
                "ALTER TABLE saving_expenditure ADD COLUMN associated_categories TEXT");
            await db.execute(
                "ALTER TABLE saving_expenditure ADD COLUMN start_date TEXT");
            await db.execute(
                "ALTER TABLE saving_expenditure ADD COLUMN end_date TEXT");
            await db.execute(
                "ALTER TABLE saving_expenditure ADD COLUMN loopable INTEGER NOT NULL DEFAULT 0");
          } catch (e) {
            // Table might not exist or columns might already exist
          }
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

  //tao db saving_expenditure
  Future<void> _createSavingExpenditureTable(Database db) async {
    await db.execute('''
      CREATE TABLE saving_expenditure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type INTEGER NOT NULL CHECK(type IN (0, 1)),
        title TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        value INTEGER NOT NULL DEFAULT 0,
        current_value INTEGER NOT NULL DEFAULT 0,
        associated_categories TEXT,
        start_date TEXT,
        end_date TEXT,
        loopable INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ─── Transaction ────────────────────────────────────────────────────

  /// Thêm giao dịch mới vào DB (gửi lên API Spring Boot)
  Future<int> insertTransaction(TransactionItem item) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/v1/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': currentUserId,
          'title': item.title,
          'category': item.category,
          'amount': item.amount,
          'isExpense': item.isExpense,
          'isBank': item.isBank,
          'date': item.date.toIso8601String(),
          'time': item.time,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int;
      } else {
        throw Exception(
            'Failed to insert transaction on server (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error inserting transaction: $e');
      rethrow;
    }
  }

  // Xoá giao dịch theo ID giao dich trên API Spring Boot
  Future<int?> deleteTransaction(int? id) async {
    if (id == null) return null;
    try {
      final response = await http.delete(
        Uri.parse(
            '$backendBaseUrl/api/v1/transactions/$id?userId=$currentUserId'),
      );
      if (response.statusCode == 200) {
        return id;
      } else {
        throw Exception(
            'Failed to delete transaction on server (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Cập nhật giao dịch hiện tại theo id trên API Spring Boot
  Future<int> updateTransaction(TransactionItem item) async {
    if (item.id == null) {
      throw ArgumentError.value(
          item, 'item', 'Transaction id must not be null');
    }
    try {
      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/v1/transactions/${item.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': item.id,
          'userId': currentUserId,
          'title': item.title,
          'category': item.category,
          'amount': item.amount,
          'isExpense': item.isExpense,
          'isBank': item.isBank,
          'date': item.date.toIso8601String(),
          'time': item.time,
        }),
      );
      if (response.statusCode == 200) {
        return 1;
      } else {
        throw Exception(
            'Failed to update transaction on server (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  /// Lấy tất cả giao dịch của user hiện tại từ API Spring Boot
  Future<List<TransactionItem>> getAllTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/v1/transactions?userId=$currentUserId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((m) => TransactionItem(
                  id: m['id'] as int?,
                  title: m['title'] as String,
                  category: m['category'] as String,
                  time: m['time'] as String,
                  date: DateTime.parse(m['date'] as String),
                  amount: (m['amount'] as num).toDouble(),
                  isExpense: m['isExpense'] as bool? ?? true,
                  isBank: m['isBank'] as bool? ?? false,
                ))
            .toList();
      } else {
        throw Exception(
            'Failed to fetch transactions from server (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  /// Lấy giao dịch theo ID của user hiện tại từ danh sách server
  Future<TransactionItem?> getTransactionItem_byID(int id) async {
    try {
      final list = await getAllTransactions();
      final matches = list.where((t) => t.id == id);
      if (matches.isEmpty) return null;
      return matches.first;
    } catch (e) {
      debugPrint('Error getting transaction by ID: $e');
      return null;
    }
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

    final start = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final end = DateTime(dateTo.year, dateTo.month, dateTo.day);
    final categoriesLower =
        categories.map((c) => c.trim().toLowerCase()).toSet();

    return all.where((item) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      final itemCategoryLower = item.category.trim().toLowerCase();

      bool dateMatches = !itemDate.isBefore(start) && !itemDate.isAfter(end);
      bool categoryMatches = categoriesLower.contains(itemCategoryLower) ||
          categoriesLower.isEmpty ||
          categoriesLower.contains('all');

      return ((item.title == title || title == '') &&
          (item.amount <= amountTo && item.amount >= amountFrom) &&
          (item.isExpense == isExpense || type == 'All') &&
          dateMatches &&
          categoryMatches &&
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
    try {
      final list = await getAllTransactions();

      if (list.isEmpty) {
        // ignore: avoid_print
        print('══════════════════════════════════════════════');
        // ignore: avoid_print
        print('📋 [DB/Server] Bảng transactions: TRỐNG');
        // ignore: avoid_print
        print('══════════════════════════════════════════════');
        return;
      }

      // ignore: avoid_print
      print('\n══════════════════════════════════════════════');
      // ignore: avoid_print
      print('📋 [DB/Server] Bảng transactions – ${list.length} bản ghi');
      // ignore: avoid_print
      print('──────────────────────────────────────────────');

      for (final item in list) {
        final typeIcon = item.isExpense ? '🔴 Chi tiêu' : '🟢 Thu nhập';
        final uid = currentUserId;
        final shortUid = uid.length > 8 ? '${uid.substring(0, 8)}…' : uid;
        // ignore: avoid_print
        print(
          'ID: ${item.id}'
          ' | user: $shortUid'
          ' | ${item.title}'
          ' (${item.category})'
          ' | $typeIcon'
          ' | \$${item.amount.toStringAsFixed(2)}'
          ' | ${item.date.toIso8601String().substring(0, 10)}'
          ' ${item.time}'
          ' | 🏦 ${item.isBank ? 'Bank' : 'Manual'}',
        );
      }

      // ignore: avoid_print
      print('══════════════════════════════════════════════\n');
    } catch (e) {
      // ignore: avoid_print
      print('Error printing transactions from server: $e');
    }
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
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/v1/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': currentUserId,
          'title': item.title,
          'iconCode': item.icon.codePoint,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int;
      } else if (response.statusCode == 409) {
        throw Exception('Title already used');
      } else {
        throw Exception('Failed to insert category on server');
      }
    } catch (e) {
      debugPrint('Error inserting category: $e');
      rethrow;
    }
  }

  /// Trả về id của category có `title` thuộc user hiện tại.
  /// Nếu không tìm thấy, trả về -1.
  Future<int> getCategoryId(String title) async {
    try {
      final cats = await getCategory();
      final match = cats.firstWhere((c) => c.title.toLowerCase() == title.toLowerCase());
      return match.id ?? -1;
    } catch (e) {
      return -1;
    }
  }

  /// Sửa title và icon cho category theo id của user hiện tại.
  /// Cũng sẽ cập nhật tất cả transactions có category cũ sang title mới.
  Future<int> editCategory(int id,
      {required String title, required IconData icon}) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    // 1. Lấy category cũ để biết old title
    String oldTitle = '';
    try {
      final cats = await getCategory();
      final match = cats.firstWhere((c) => c.id == id);
      oldTitle = match.title;
    } catch (e) {
      throw StateError('Category not found');
    }

    // 2. Cập nhật category lên server
    try {
      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/v1/categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'userId': currentUserId,
          'title': trimmedTitle,
          'iconCode': icon.codePoint,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update category on server');
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }

    // 3. Update tất cả transactions có category cũ sang title mới
    if (oldTitle != trimmedTitle) {
      try {
        await http.put(
          Uri.parse(
              '$backendBaseUrl/api/v1/transactions/categories?userId=$currentUserId&oldCategory=${Uri.encodeComponent(oldTitle)}&newCategory=${Uri.encodeComponent(trimmedTitle)}'),
        );
      } catch (e) {
        debugPrint('Error updating transaction categories on server: $e');
      }
    }

    return 1;
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
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/v1/categories?userId=$currentUserId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((m) => CategoryItem(
          id: m['id'] as int?,
          userId: m['userId'] as String? ?? currentUserId,
          title: m['title'] as String,
          icon: IconData(m['iconCode'] as int, fontFamily: 'MaterialIcons'),
        )).toList();
      } else {
        throw Exception('Failed to fetch categories from server');
      }
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  // Xoá category trong DB của user hiện tại theo ID giao dich
  Future<int?> deleteCategory(
    int? id, {
    String replacementCategory = 'Others',
    String? userId,
  }) async {
    if (id == null) return null;
    final effectiveUserId = userId ?? currentUserId;

    final oldCategory = await getCategory().then((cats) => cats.firstWhere((c) => c.id == id));
    final oldTitle = oldCategory.title;

    try {
      final response = await http.delete(
        Uri.parse('$backendBaseUrl/api/v1/categories/$id?userId=$effectiveUserId'),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete category on server');
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }

    try {
      await http.put(
        Uri.parse(
            '$backendBaseUrl/api/v1/transactions/categories?userId=$effectiveUserId&oldCategory=${Uri.encodeComponent(oldTitle)}&newCategory=${Uri.encodeComponent(replacementCategory)}'),
      );
    } catch (e) {
      debugPrint(
          'Error updating transaction categories on delete on server: $e');
    }

    return id;
  }

  // Lấy Icon của khi biết title và userID
  Future<IconData> getCategoryIcon(String title) async {
    try {
      final cats = await getCategory();
      final match = cats.firstWhere((c) => c.title.toLowerCase() == title.toLowerCase());
      return match.icon;
    } catch (e) {
      return Icons.more_horiz;
    }
  }

  // ─── Saving & Expenditure Items Helper Methods ──────────────────────────

  Future<void> _checkAndProcessExpiredBudgets() async {
    final userId = currentUserId;

    List<Map<String, dynamic>> items = [];
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/v1/saving-expenditures?userId=$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        items = list.map((m) => {
          'id': m['id'] as int?,
          'user_id': m['userId'] as String,
          'type': m['type'] as int,
          'title': m['title'] as String,
          'icon_code': m['iconCode'] as int,
          'value': m['value'] as int,
          'current_value': m['currentValue'] as int,
          'associated_categories': m['associatedCategories'] as String?,
          'start_date': m['startDate'] as String?,
          'end_date': m['endDate'] as String?,
          'loopable': (m['loopable'] as bool) ? 1 : 0,
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching in _checkAndProcessExpiredBudgets: $e');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final item in items) {
      final endDateStr = item['end_date'] as String? ?? '';
      if (endDateStr.isEmpty) continue;

      final endDate = DateTime.tryParse(endDateStr);
      if (endDate == null) continue;

      final targetEnd = DateTime(endDate.year, endDate.month, endDate.day);
      if (targetEnd.isBefore(today)) {
        // Expired!
        final id = item['id'] as int;
        final loopable = (item['loopable'] as int? ?? 0) == 1;

        if (loopable) {
          // Calculate new dates
          final startDateStr = item['start_date'] as String? ?? '';
          final startDate = DateTime.tryParse(startDateStr) ?? DateTime.now();
          final start =
              DateTime(startDate.year, startDate.month, startDate.day);

          int days = targetEnd.difference(start).inDays;
          if (days < 0) days = 30; // fallback

          DateTime newStart = start;
          DateTime newEnd = targetEnd;
          while (
              !newEnd.isAfter(today) && !DateUtils.isSameDay(newEnd, today)) {
            newStart = newEnd.add(const Duration(days: 1));
            newEnd = newStart.add(Duration(days: days));
          }

          // Create new budget map
          final newBudget = {
            'user_id': userId,
            'type': item['type'],
            'title': item['title'],
            'icon_code': item['icon_code'],
            'value': item['value'],
            'current_value': 0, // Reset spent amount for the new budget period
            'associated_categories': item['associated_categories'],
            'start_date': newStart.toIso8601String(),
            'end_date': newEnd.toIso8601String(),
            'loopable': 1,
          };

          // Insert the new budget
          await insertSavingExpenditureItem(newBudget);
        }

        // Delete the expired budget
        await deleteSavingExpenditureItem(id);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getSavingExpenditureItems(
      {int? type}) async {
    await _checkAndProcessExpiredBudgets();
    try {
      String url = '$backendBaseUrl/api/v1/saving-expenditures?userId=$currentUserId';
      if (type != null) {
        url += '&type=$type';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((m) => {
          'id': m['id'] as int?,
          'user_id': m['userId'] as String,
          'type': m['type'] as int,
          'title': m['title'] as String,
          'icon_code': m['iconCode'] as int,
          'value': m['value'] as int,
          'current_value': m['currentValue'] as int,
          'associated_categories': m['associatedCategories'] as String?,
          'start_date': m['startDate'] as String?,
          'end_date': m['endDate'] as String?,
          'loopable': (m['loopable'] as bool) ? 1 : 0,
        }).toList();
      } else {
        throw Exception('Failed to fetch saving expenditure items from server');
      }
    } catch (e) {
      debugPrint('Error getting saving expenditure items: $e');
      return [];
    }
  }

  Future<int> insertSavingExpenditureItem(Map<String, dynamic> item) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/v1/saving-expenditures'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': currentUserId,
          'type': item['type'],
          'title': item['title'],
          'iconCode': item['icon_code'],
          'value': item['value'],
          'currentValue': item['current_value'] ?? 0,
          'associatedCategories': item['associated_categories'],
          'startDate': item['start_date'],
          'endDate': item['end_date'],
          'loopable': (item['loopable'] == 1 || item['loopable'] == true),
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int;
      } else {
        throw Exception('Failed to insert saving expenditure item on server');
      }
    } catch (e) {
      debugPrint('Error inserting saving expenditure item: $e');
      rethrow;
    }
  }

  Future<int> updateSavingExpenditureItem(Map<String, dynamic> item) async {
    final id = item['id'];
    try {
      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/v1/saving-expenditures/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'userId': currentUserId,
          'type': item['type'],
          'title': item['title'],
          'iconCode': item['icon_code'],
          'value': item['value'],
          'currentValue': item['current_value'],
          'associatedCategories': item['associated_categories'],
          'startDate': item['start_date'],
          'endDate': item['end_date'],
          'loopable': (item['loopable'] == 1 || item['loopable'] == true),
        }),
      );
      if (response.statusCode == 200) {
        return 1;
      } else {
        throw Exception('Failed to update saving expenditure item on server');
      }
    } catch (e) {
      debugPrint('Error updating saving expenditure item: $e');
      rethrow;
    }
  }

  Future<int> deleteSavingExpenditureItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendBaseUrl/api/v1/saving-expenditures/$id?userId=$currentUserId'),
      );
      if (response.statusCode == 200) {
        return 1;
      } else {
        throw Exception('Failed to delete saving expenditure item on server');
      }
    } catch (e) {
      debugPrint('Error deleting saving expenditure item: $e');
      rethrow;
    }
  }
}
