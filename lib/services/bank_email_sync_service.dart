import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import '../data/data_transaction.dart';
import 'database_service.dart';
import 'email_parser_service.dart';

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

  /// Save sync configuration
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

  /// Get current sync configuration
  Future<Map<String, dynamic>> getConfig() async {
    final host = await _dbService.getSetting(keyImapHost) ?? 'imap.gmail.com';
    final portStr = await _dbService.getSetting(keyImapPort) ?? '993';
    final email = await _dbService.getSetting(keyEmailAddress) ?? '';
    final password = await _dbService.getSetting(keyAppPassword) ?? '';
    final isSecureStr = await _dbService.getSetting(keyIsSecure) ?? '1';
    final banksStr = await _dbService.getSetting(keyEnabledBanks) ??
        'Vietcombank,TPBank,Techcombank';

    return {
      'host': host,
      'port': int.tryParse(portStr) ?? 993,
      'email': email,
      'password': password,
      'isSecure': isSecureStr == '1',
      'enabledBanks': banksStr.split(',').where((s) => s.isNotEmpty).toList(),
    };
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

  /// Run email sync
  /// Returns a count of new transactions recorded
  Future<int> syncEmails() async {
    final config = await getConfig();
    final String email = config['email'];
    final String password = config['password'];
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Vui lòng cấu hình tài khoản email trước khi đồng bộ.');
    }

    final String host = config['host'];
    final int port = config['port'];
    final bool isSecure = config['isSecure'];
    final List<String> enabledBanks = List<String>.from(config['enabledBanks']);

    final client = ImapClient(isLogEnabled: false);
    int newTransactionsCount = 0;

    try {
      await client.connectToServer(host, port, isSecure: isSecure);
      await client.login(email, password);
      await client.selectInbox();

      // Fetch the last 20 messages
      final fetchResult = await client.fetchRecentMessages(
        messageCount: 20,
        criteria: 'BODY.PEEK[]',
      );

      for (final message in fetchResult.messages) {
        final from = message.from != null && message.from!.isNotEmpty
            ? (message.from!.first.email ?? '')
            : '';
        final subject = message.decodeSubject() ?? '';
        final body =
            message.decodeTextPlainPart() ?? message.decodeTextHtmlPart() ?? '';
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

        // Verify if the parsed bank is in enabled list
        bool bankEnabled = from.toLowerCase().contains('manh');
        if (!bankEnabled) {
          for (final bank in enabledBanks) {
            if (parsed.title.toLowerCase().contains(bank.toLowerCase())) {
              bankEnabled = true;
              break;
            }
          }
        }
        if (!bankEnabled) continue;

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
      await _dbService.saveSetting(
          keyLastSyncTime, DateTime.now().toIso8601String());
      return newTransactionsCount;
    } catch (e) {
      debugPrint('Email Sync Error: $e');
      rethrow;
    }
  }

  /// Simulate an email sync for testing purposes without needing actual IMAP details
  Future<TransactionItem?> simulateSync(String bank, String rawText) async {
    String from = 'notification@bank.com.vn';
    String subject = 'Biến động số dư tài khoản';

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
