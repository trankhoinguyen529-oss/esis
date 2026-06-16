import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import '../data/data_transaction.dart';
import 'database_service.dart';
import 'email_parser_service.dart';

class EmailAccount {
  final String id;
  final String email;
  final String password;
  final String host;
  final int port;
  final bool isSecure;

  EmailAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.host,
    required this.port,
    required this.isSecure,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'host': host,
        'port': port,
        'isSecure': isSecure,
      };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        host: json['host'] ?? 'imap.gmail.com',
        port: json['port'] ?? 993,
        isSecure: json['isSecure'] ?? true,
      );
}

class BankEmailSyncService {
  final DatabaseService _dbService = DatabaseService();

  // Settings Keys
  static const String keyImapHost = 'email_imap_host';
  static const String keyImapPort = 'email_imap_port';
  static const String keyEmailAddress = 'email_address';
  static const String keyAppPassword = 'email_app_password';
  static const String keyIsSecure = 'email_is_secure';
  static const String keyEnabledBanks = 'email_enabled_banks';
  static const String keyLastSyncTime = 'email_last_sync_time';
  static const String keyEmailAccountsJson = 'email_accounts_json';

  /// Save sync configuration (Legacy - kept for compatibility)
  Future<void> saveConfig({
    required String host,
    required int port,
    required String email,
    required String password,
    required bool isSecure,
    required List<String> enabledBanks,
  }) async {
    await _dbService.saveSetting(keyImapHost, host);
    await _dbService.saveSetting(keyImapPort, port.toString());
    await _dbService.saveSetting(keyEmailAddress, email);
    await _dbService.saveSetting(keyAppPassword, password);
    await _dbService.saveSetting(keyIsSecure, isSecure ? '1' : '0');
    await _dbService.saveSetting(keyEnabledBanks, enabledBanks.join(','));
  }

  /// Get current sync configuration (Legacy - kept for compatibility)
  Future<Map<String, dynamic>> getConfig() async {
    final host = await _dbService.getSetting(keyImapHost) ?? 'imap.gmail.com';
    final portStr = await _dbService.getSetting(keyImapPort) ?? '993';
    final email = await _dbService.getSetting(keyEmailAddress) ?? '';
    final password = await _dbService.getSetting(keyAppPassword) ?? '';
    final isSecureStr = await _dbService.getSetting(keyIsSecure) ?? '1';
    final banksStr = await _dbService.getSetting(keyEnabledBanks) ??
        'Vietcombank,TPBank,Techcombank,MB Bank,ACB';

    return {
      'host': host,
      'port': int.tryParse(portStr) ?? 993,
      'email': email,
      'password': password,
      'isSecure': isSecureStr == '1',
      'enabledBanks': banksStr.split(',').where((s) => s.isNotEmpty).toList(),
    };
  }

  /// Get list of accounts with auto-migration from legacy config
  Future<List<EmailAccount>> getAccounts() async {
    final jsonStr = await _dbService.getSetting(keyEmailAccountsJson);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list.map((item) => EmailAccount.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding accounts: $e');
      }
    }

    // Migration from old single config
    final config = await getConfig();
    final String email = config['email'] ?? '';
    if (email.isNotEmpty) {
      final oldAccount = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        password: config['password'] ?? '',
        host: config['host'] ?? 'imap.gmail.com',
        port: config['port'] ?? 993,
        isSecure: config['isSecure'] ?? true,
      );
      final accounts = [oldAccount];
      await saveAccounts(accounts);
      // Clean up old settings to prevent running migration again
      await _dbService.deleteSetting(keyEmailAddress);
      await _dbService.deleteSetting(keyAppPassword);
      return accounts;
    }

    return [];
  }

  /// Save list of accounts
  Future<void> saveAccounts(List<EmailAccount> accounts) async {
    final list = accounts.map((a) => a.toJson()).toList();
    await _dbService.saveSetting(keyEmailAccountsJson, jsonEncode(list));
  }

  /// Test connection to IMAP server
  Future<bool> testConnection(
    String host,
    int port,
    String email,
    String password,
    bool isSecure,
  ) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(host, port, isSecure: isSecure);
      await client.login(email, password);
      await client.logout();
      return true;
    } catch (e) {
      debugPrint('IMAP Test Connection Error: $e');
      rethrow;
    }
  }

  /// Run email sync for all configured accounts
  /// Returns a count of new transactions recorded
  Future<int> syncEmails() async {
    final accounts = await getAccounts();
    if (accounts.isEmpty) {
      throw Exception('Please configure at least one email account.');
    }

    int newTransactionsCount = 0;
    final List<String> errors = [];

    for (final account in accounts) {
      if (account.email.isEmpty || account.password.isEmpty) continue;

      final client = ImapClient(isLogEnabled: false);
      try {
        await client.connectToServer(account.host, account.port,
            isSecure: account.isSecure);
        await client.login(account.email, account.password);
        await client.selectInbox();

        // Fetch the last 20 messages
        final fetchResult = await client.fetchRecentMessages(
          messageCount: 20,
          criteria: 'BODY.PEEK[]',
        );

        for (final message in fetchResult.messages) {
          final from = message.from != null && message.from!.isNotEmpty
              ? message.from!.first.email
              : '';
          final subject = message.decodeSubject() ?? '';
          final body = message.decodeTextPlainPart() ??
              message.decodeTextHtmlPart() ??
              '';
          String? messageId;
          if (message.headers != null) {
            for (final h in message.headers!) {
              if (h.name.toLowerCase() == 'message-id') {
                messageId = h.value;
                break;
              }
            }
          }
          messageId ??=
              '${from}_${subject}_${message.envelope?.date?.millisecondsSinceEpoch}';

          // Check if already synced
          final alreadySynced = await _dbService.isEmailSynced(messageId);
          if (alreadySynced) continue;

          // Parse email
          final parsed = EmailParserService.parse(from, subject, body);
          if (parsed == null) continue;

          // Mapping to IconData
          IconData categoryIcon = Icons.more_horiz;
          if (parsed.category == 'Food')
            categoryIcon = Icons.restaurant;
          else if (parsed.category == 'Transport')
            categoryIcon = Icons.directions_bus;
          else if (parsed.category == 'Medicine')
            categoryIcon = Icons.medical_services;
          else if (parsed.category == 'Groceries')
            categoryIcon = Icons.local_grocery_store;
          else if (parsed.category == 'Rent')
            categoryIcon = Icons.home;
          else if (parsed.category == 'Gifts')
            categoryIcon = Icons.card_giftcard;
          else if (parsed.category == 'Savings')
            categoryIcon = Icons.savings;
          else if (parsed.category == 'Entertainment')
            categoryIcon = Icons.movie;
          else if (parsed.category == 'Salary')
            categoryIcon = Icons.wallet;
          else if (parsed.category == 'Work')
            categoryIcon = Icons.work;
          else if (parsed.category == 'Gaming')
            categoryIcon = Icons.sports_esports;

          final transaction = TransactionItem(
            icon: categoryIcon,
            title: parsed.description,
            category: parsed.category,
            time: parsed.time,
            date: parsed.date,
            amount: parsed.amount,
            isExpense: parsed.isExpense,
          );

          // Save transaction & mark email as synced
          await _dbService.insertTransaction(transaction);
          await _dbService.markEmailSynced(messageId);
          newTransactionsCount++;
        }

        await client.logout();
      } catch (e) {
        debugPrint('Email Sync Error for ${account.email}: $e');
        errors.add('${account.email}: $e');
      }
    }

    if (errors.length == accounts.length && accounts.isNotEmpty) {
      throw Exception(
          'Email sync failed for all accounts:\n${errors.join('\n')}');
    }

    await _dbService.saveSetting(
        keyLastSyncTime, DateTime.now().toIso8601String());
    return newTransactionsCount;
  }

  /// Simulate an email sync for testing purposes without needing actual IMAP details
  Future<TransactionItem?> simulateSync(String bank, String rawText) async {
    String from = 'notification@bank.com.vn';
    String subject = 'Thong bao bien dong so du';

    if (bank == 'Vietcombank') {
      from = 'no-reply@vietcombank.com.vn';
      subject = 'VCB Digibank - Thong bao bien dong so du';
    } else if (bank == 'TPBank') {
      from = 'ebank@tpb.com.vn';
      subject = 'TPBank - Thong bao bien dong so du tai khoan';
    } else if (bank == 'Techcombank') {
      from = 'no-reply@techcombank.com.vn';
      subject = 'Thong bao giao dich Techcombank';
    }

    final parsed = EmailParserService.parse(from, subject, rawText);
    if (parsed == null) return null;

    final mockMessageId =
        'MOCK_${bank.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';

    // Map categories
    IconData categoryIcon = Icons.more_horiz;
    if (parsed.category == 'Food')
      categoryIcon = Icons.restaurant;
    else if (parsed.category == 'Transport')
      categoryIcon = Icons.directions_bus;
    else if (parsed.category == 'Medicine')
      categoryIcon = Icons.medical_services;
    else if (parsed.category == 'Groceries')
      categoryIcon = Icons.local_grocery_store;
    else if (parsed.category == 'Rent')
      categoryIcon = Icons.home;
    else if (parsed.category == 'Gifts')
      categoryIcon = Icons.card_giftcard;
    else if (parsed.category == 'Savings')
      categoryIcon = Icons.savings;
    else if (parsed.category == 'Entertainment')
      categoryIcon = Icons.movie;
    else if (parsed.category == 'Salary')
      categoryIcon = Icons.wallet;
    else if (parsed.category == 'Work')
      categoryIcon = Icons.work;
    else if (parsed.category == 'Gaming') categoryIcon = Icons.sports_esports;

    final transaction = TransactionItem(
      icon: categoryIcon,
      title: parsed.description,
      category: parsed.category,
      time: parsed.time,
      date: parsed.date,
      amount: parsed.amount,
      isExpense: parsed.isExpense,
    );

    // Save and record as synced
    await _dbService.insertTransaction(transaction);
    await _dbService.markEmailSynced(mockMessageId);
    return transaction;
  }
}
