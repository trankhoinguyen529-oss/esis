import 'package:a_management/management/add_transaction_screen.dart';
import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../services/auth_service.dart';
import '../management/management_screen.dart';
import 'tab_icon.dart';
import '../transaction/transaction_screen.dart';
import '../services/database_service.dart';
import '../services/bank_email_sync_service.dart';
import 'dart:async';
import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/data/pie_chart_data.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.onTransactionAdded});
  final VoidCallback? onTransactionAdded;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool addButton = true;
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  int _selectedPeriod = 2; // 0: Daily, 1: Weekly, 2: Monthly
  int _currentPage = 0;
  Timer? _timer;

  double _income = 0;
  double _expense = 0;
  bool _summaryLoading = true;
  List<TransactionItem> _periodTransactions = [];

  @override
  void initState() {
    super.initState();
    _startAutoSync();
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
        _loadSummary(silent: true);
      }
    } catch (e) {
      debugPrint('Auto sync failed silently: $e');
    }
  }

  Future<void> _loadSummary({bool silent = false}) async {
    if (!silent) {
      setState(() => _summaryLoading = true);
    }
    final summaryFuture = DatabaseService().getSummaryByPeriod(_selectedPeriod);
    final txnsFuture =
        DatabaseService().getTransactionsByPeriod(_selectedPeriod);

    final summary = await summaryFuture;
    final txns = await txnsFuture;

    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0;
        _expense = summary['expense'] ?? 0;
        _periodTransactions = txns;
        _summaryLoading = false;
      });
    }
  }

  Future<void> _syncBankEmails() async {
    try {
      final newTxns = await BankEmailSyncService().syncEmails();
      if (mounted && newTxns > 0) {
        _loadSummary(silent: true);
      }
    } catch (e) {
      debugPrint('Auto sync failed silently: $e');
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
        onHome: () {
          _goToPage(0);
          addButton = true;
        },
        onAnalytics: () {},
        onTransaction: () {
          _goToPage(1);
          addButton = false;
        },
        onManagement: () {
          _goToPage(2);
          addButton = false;
        },
        onProfile: () {
          _goToPage(3);
          addButton = false;
        },
      ),
      // nút add
      floatingActionButton: addButton
          ? SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(category: 'All'),
                    ),
                  );
                  if (result == true) {
                    widget.onTransactionAdded?.call();
                    _loadSummary();
                  }
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 32),
              ),
            )
          : null, // ✅ null = không hiện
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
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
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
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: primary,
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
                                    Icon(
                                      Icons.trending_down,
                                      color: Colors.red[400],
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
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.red[400],
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
                      //thanh biểu đồ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SwipeablePieCharts(
                            transactions: _periodTransactions,
                            isLoading: _summaryLoading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    primary: primary,
                    surface: surface,
                    selectedPeriod: _selectedPeriod,
                    onPeriodSelected: (i) {
                      setState(() => _selectedPeriod = i);
                      _loadSummary();
                    },
                    onViewAll: () {
                      _goToPage(1);
                      addButton = false;
                    },
                  ),
                ),
              ];
            },
            body: Container(
              color: surface,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _HomeTransactionList(
                transactions: _periodTransactions,
                isLoading: _summaryLoading,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget riêng để rebuild danh sách khi period thay đổi
class _HomeTransactionList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final bool isLoading;

  const _HomeTransactionList({
    required this.transactions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Displaytransaction().displayTransactionSync(
      transactions: transactions,
      ontap: (int i) {},
      padding: const EdgeInsets.only(top: 8, bottom: 80),
    );
  }
}

//chặn header trong scrollview
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color primary;
  final Color surface;
  final int selectedPeriod;
  final ValueChanged<int> onPeriodSelected;
  final VoidCallback onViewAll;

  _HomeHeaderDelegate({
    required this.primary,
    required this.surface,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.onViewAll,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: 135.0,
      child: Container(
        color: primary,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    final selected = selectedPeriod == i;
                    return GestureDetector(
                      onTap: () => onPeriodSelected(i),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.refresh_rounded, size: 24),
                      SizedBox(width: 2),
                      Text('Recent transactions')
                    ],
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View all'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 135.0;

  @override
  double get minExtent => 135.0;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.selectedPeriod != selectedPeriod ||
        oldDelegate.primary != primary ||
        oldDelegate.surface != surface;
  }
}

// ─── CUSTOM PIE CHART WIDGETS FOR CATEGORY EXPENSES ────────────────

class SwipeablePieCharts extends StatefulWidget {
  final List<TransactionItem> transactions;
  final bool isLoading;

  const SwipeablePieCharts({
    super.key,
    required this.transactions,
    required this.isLoading,
  });

  @override
  State<SwipeablePieCharts> createState() => _SwipeablePieChartsState();
}

class _SwipeablePieChartsState extends State<SwipeablePieCharts> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 175,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C18A)),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SizedBox(
            height: 150,
            child: PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                CategoryPieChart(
                  transactions: widget.transactions,
                  isExpense: true,
                ),
                CategoryPieChart(
                  transactions: widget.transactions,
                  isExpense: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 12 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00C18A) : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  final List<TransactionItem> transactions;
  final bool isExpense;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTransactions =
        transactions.where((t) => t.isExpense == isExpense).toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline,
                size: 48, color: Colors.black26),
            const SizedBox(height: 8),
            Text(
              isExpense ? 'No expenses recorded' : 'No income recorded',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, double> categoryAmounts = {};
    for (final tx in filteredTransactions) {
      categoryAmounts[tx.category] =
          (categoryAmounts[tx.category] ?? 0) + tx.amount;
    }

    // Map categories to PieChartData for CustomPieChart
    final List<PieChartData> pieData = categoryAmounts.entries.map((entry) {
      return PieChartData(
        name: entry.key,
        value: entry.value,
      );
    }).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Right side: Scrollable Category List (vẽ trước, nằm dưới)
        Positioned.fill(
          left: 170, // 150 (pie width) + 20 (gap)
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 2.0),
            child: ScrollList(
              categories: categoryAmounts,
              isExpense: isExpense,
            ),
          ),
        ),
        // Left side: Pie Chart (vẽ sau, nằm đè lên trên)
        Positioned(
          left: 0,
          top: 0,
          width: 150,
          height: 150,
          child: CustomPieChart(
            data: pieData,
            title: isExpense ? 'Expense' : 'Income',
          ),
        ),
      ],
    );
  }
}
