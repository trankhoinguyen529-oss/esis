import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../services/auth_service.dart';
import '../management/management_screen.dart';
import 'tab_icon.dart';
import '../transaction/transaction_screen.dart';
import '../services/database_service.dart';
import '../services/bank_email_sync_service.dart';
import '../profile/bank_email_sync_screen.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  int _selectedPeriod = 2; // 0: Daily, 1: Weekly, 2: Monthly
  int _currentPage = 0;
  Timer? _timer;

  double _income = 0;
  double _expense = 0;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    // _startAutoSync();
    _loadSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncEmails();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
    _timer?.cancel();
  }

  void _startAutoSync() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _syncBankEmails();
    });
  }

  Future<void> _autoSyncEmails() async {
    try {
      final newTxns = await BankEmailSyncService().syncEmails();
      if (newTxns > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Automatic synchronization: Added new $newTxns transaction from email!'),
            backgroundColor: const Color(0xFF00C18A),
          ),
        );
        _loadSummary();
      }
    } catch (e) {
      debugPrint('Auto sync failed silently: $e');
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    final summary = await DatabaseService().getSummaryByPeriod(_selectedPeriod);
    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0;
        _expense = summary['expense'] ?? 0;
        _summaryLoading = false;
      });
    }
  }

  Future<void> _syncBankEmails() async {
    try {
      final newTxns = await BankEmailSyncService().syncEmails();
      if (mounted) {
        // Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //         'Automatic synchronization: Added new $newTxns transaction from email!'),
        //     backgroundColor: const Color(0xFF00C18A),
        //   ),
        // );
        _loadSummary();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('No email account configured',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'You need to set up your email login information before the system can connect to synchronize.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black54)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BankEmailSyncScreen()),
                  ).then((_) => _loadSummary());
                },
                child: const Text('Setup now',
                    style: TextStyle(
                        color: Color(0xFF00C18A), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int get _selectedIconIndex {
    switch (_currentPage) {
      case 0:
        return 0;
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF00C18A);
    final Color surface = const Color(0xFFF3FFF8);
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'User';
    debugPrint('');

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() {
            _currentPage = index;
          }),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHomePage(primary, surface, displayName, context),
            TransactionScreen(
              onTransactionAdded: _loadSummary,
              selectedType: 'All',
              selectedCategories: {'All'},
              selectedTitle: '',
              selectedAmountFrom: 0.00,
              selectedAmountTo: 1000000000000.00,
              selectedDateFrom: DateTime(2020, 1, 1),
              selectedDateTo: DateTime(2030, 1, 1),
            ),
            ManagementScreen(onTransactionAdded: _loadSummary),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: TabIcon(
        selectedIndex: _selectedIconIndex,
        onHome: () => _goToPage(0),
        onAnalytics: () {},
        onTransaction: () => _goToPage(1),
        onManagement: () => _goToPage(2),
        onProfile: () => _goToPage(3),
      ),
    );
  }

  Widget _buildHomePage(
      Color primary, Color surface, String displayName, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $displayName',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Welcomeuser().welcomeUser(),
                  ],
                ),
              ),
              // GestureDetector(
              //   onTap: _syncBankEmails,
              //   child: Container(
              //     width: 40,
              //     height: 40,
              //     decoration: BoxDecoration(
              //       color: surface,
              //       shape: BoxShape.circle,
              //     ),
              //     child: const Icon(Icons.sync, color: Colors.black87),
              //   ),
              // ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Color(0xFF00C18A),
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _summaryLoading
                          ? const SizedBox(
                              height: 20,
                              width: 60,
                              child: LinearProgressIndicator(),
                            )
                          : Text(
                              '\$${_income.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.trending_down,
                        color: Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _summaryLoading
                          ? const SizedBox(
                              height: 20,
                              width: 60,
                              child: LinearProgressIndicator(),
                            )
                          : Text(
                              '\$${_expense.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(36),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (i) {
                      final labels = ['Daily', 'Weekly', 'Monthly'];
                      final selected = _selectedPeriod == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPeriod = i);
                          _loadSummary();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 18,
                              color: selected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _HomeTransactionList(period: _selectedPeriod),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget riêng để rebuild danh sách khi period thay đổi
class _HomeTransactionList extends StatelessWidget {
  final int period;
  const _HomeTransactionList({required this.period});

  @override
  Widget build(BuildContext context) {
    return Displaytransaction().displayTransaction(
      period: period,
      type: '',
      categories: {},
      title: '',
      amountFrom: 0.00,
      amountTo: 100000000000000.00,
      dateFrom: DateTime(2025, 1, 1),
      dateTo: DateTime(2027, 1, 1),
      ontap: (int i) {},
    );
  }
}
