import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/data_transaction.dart';
import '../data/user_account.dart';
import 'database_service.dart';

class EmailAccount {
  final String id;
  final String bankName;
  final String accountNumber;

  EmailAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankName': bankName,
        'accountNumber': accountNumber,
      };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
        id: json['id'] ?? '',
        bankName: json['bankName'] ?? json['email'] ?? '',
        accountNumber: json['accountNumber'] ?? json['email'] ?? '',
      );
}

class BankEmailSyncService {
  final DatabaseService _dbService = DatabaseService();

  // Settings Keys
  static const String keyLastSyncTime = 'email_last_sync_time';
  static const String keyEmailAccountsJson = 'email_accounts_json';

  /// Get list of accounts from the backend server
  Future<List<EmailAccount>> getAccounts() async {
    try {
      final List<UserAccountItem> list = await _dbService.getUserAccounts();
      return list.map((item) => EmailAccount(
        id: item.id,
        bankName: item.bankName,
        accountNumber: item.accountNumber,
      )).toList();
    } catch (e) {
      debugPrint('Error getting accounts from server: $e. Falling back to local.');
      // Fallback to local settings
      final jsonStr = await _dbService.getSetting(keyEmailAccountsJson);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(jsonStr);
          return list.map((item) => EmailAccount.fromJson(item)).toList();
        } catch (err) {
          debugPrint('Error decoding accounts: $err');
        }
      }
      return [];
    }
  }

  /// Save list of accounts locally (fallback)
  Future<void> saveAccounts(List<EmailAccount> accounts) async {
    final list = accounts.map((a) => a.toJson()).toList();
    await _dbService.saveSetting(keyEmailAccountsJson, jsonEncode(list));
  }

  /// Save account to backend server
  Future<void> saveAccountToServer(EmailAccount account) async {
    try {
      final serverAccounts = await _dbService.getUserAccounts();
      final idx = serverAccounts.indexWhere((s) => s.id == account.id);
      if (idx != -1) {
        // Update existing
        final existing = serverAccounts[idx];
        final updated = UserAccountItem(
          id: existing.id,
          userId: _dbService.currentUserId,
          accountNumber: account.accountNumber,
          bankName: account.bankName,
          accountName: existing.accountName,
          balance: existing.balance,
          currency: existing.currency,
        );
        await _dbService.updateUserAccount(updated);
      } else {
        // Create new
        final newAcc = UserAccountItem(
          id: account.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : account.id,
          userId: _dbService.currentUserId,
          accountNumber: account.accountNumber,
          bankName: account.bankName,
          accountName: 'Linked Account',
          balance: 0.0,
          currency: 'VND',
        );
        await _dbService.createUserAccount(newAcc);
      }
    } catch (e) {
      debugPrint('Error saving account to server: $e. Saving locally.');
      // Fallback: save to local setting
      final accounts = await getAccounts();
      accounts.removeWhere((a) => a.id == account.id);
      accounts.add(account);
      await saveAccounts(accounts);
    }
  }

  /// Delete account from backend server
  Future<void> deleteAccountFromServer(String id) async {
    try {
      await _dbService.deleteUserAccount(id);
    } catch (e) {
      debugPrint('Error deleting account from server: $e. Deleting locally.');
      // Fallback: delete from local setting
      final accounts = await getAccounts();
      accounts.removeWhere((a) => a.id == id);
      await saveAccounts(accounts);
    }
  }

  /// Test connection to backend
  Future<bool> testConnection(
    String bankName,
    String accountNumber,
  ) async {
    debugPrint('Testing connection for bank=$bankName, account=$accountNumber');
    try {
      final url = Uri.parse('${_dbService.backendBaseUrl}/api/v1/bank-transactions?accountNumber=${accountNumber.trim()}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Server returned status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Test Connection Error: $e');
      rethrow;
    }
  }

  /// Run bank sync for all configured accounts
  /// Returns a count of new transactions recorded
  Future<int> syncEmails() async {
    final accounts = await getAccounts();
    if (accounts.isEmpty) {
      throw Exception('Please configure at least one bank account.');
    }

    int newTransactionsCount = 0;
    final List<String> errors = [];

    for (final account in accounts) {
      if (account.accountNumber.isEmpty) continue;

      try {
        final url = Uri.parse('${_dbService.backendBaseUrl}/api/v1/bank-transactions?accountNumber=${account.accountNumber.trim()}');
        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception('Failed to fetch transactions (Status: ${response.statusCode})');
        }

        final List<dynamic> list = jsonDecode(response.body);
        for (final item in list) {
          final String sepayId = item['sepayTransactionId'].toString();
          final messageId = 'SEPAY_$sepayId';

          // Check if already synced
          final alreadySynced = await _dbService.isEmailSynced(messageId);
          if (alreadySynced) continue;

          final String transferType = item['transferType'] ?? 'out';
          final bool isExpense = 'out' == transferType.toLowerCase();
          final double amount = (item['amount'] as num).toDouble();
          final String content = item['content'] ?? '';
          final String transactionDateStr = item['transactionDate'] ?? '';

          DateTime date = DateTime.now();
          String time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

          if (transactionDateStr.isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(transactionDateStr);
              date = parsedDate;
              time = "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
            } catch (e) {
              debugPrint('Error parsing date: $transactionDateStr');
            }
          }

          final transaction = TransactionItem(
            title: content.isNotEmpty ? content : '${account.bankName} Transaction',
            category: 'Bank',
            time: time,
            date: date,
            amount: amount,
            isExpense: isExpense,
            isBank: true,
          );

          // Save transaction & mark as synced
          await _dbService.insertTransaction(transaction);
          await _dbService.markEmailSynced(messageId);
          newTransactionsCount++;
        }
      } catch (e) {
        debugPrint('Bank Sync Error for ${account.bankName} (${account.accountNumber}): $e');
        errors.add('${account.bankName}: $e');
      }
    }

    if (errors.length == accounts.length && accounts.isNotEmpty) {
      throw Exception(
          'Bank sync failed for all accounts:\n${errors.join('\n')}');
    }

    await _dbService.saveSetting(
        keyLastSyncTime, DateTime.now().toIso8601String());
    return newTransactionsCount;
  }

  /// Simulate sync for testing
  Future<TransactionItem?> simulateSync(String bank, String rawText) async {
    // Left for compatibility / simulation testing if needed
    final mockMessageId =
        'MOCK_${bank.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';

    final transaction = TransactionItem(
        title: 'Mock $bank: $rawText',
        category: 'Bank',
        time: '12:00',
        date: DateTime.now(),
        amount: 2000.0,
        isExpense: true,
        isBank: true);

    await _dbService.insertTransaction(transaction);
    await _dbService.markEmailSynced(mockMessageId);
    return transaction;
  }
}
