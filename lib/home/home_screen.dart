import 'package:a_management/management/add_transaction_screen.dart';
import 'package:a_management/management/categorydetail_screen.dart';
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
import 'dart:math';
import 'package:a_management/data/data_transaction.dart';

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
    //_startAutoSync();
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
    final txns =
        await DatabaseService().getTransactionsByPeriod(_selectedPeriod);
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
              child: _HomeTransactionList(period: _selectedPeriod),
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
      type: 'All',
      bank: 'All',
      categories: {},
      title: '',
      amountFrom: 0.00,
      amountTo: 100000000000000.00,
      dateFrom: DateTime(2025, 1, 1),
      dateTo: DateTime(2027, 1, 1),
      ontap: (int i) {},
      padding: const EdgeInsets.only(top: 8, bottom: 80),
    );
  }
}

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

class CategoryPieData {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  CategoryPieData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        const SizedBox(height: 8),
        Row(
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFE67E22); // Orange
      case 'Transport':
        return const Color(0xFF3498DB); // Blue
      case 'Medicine':
        return const Color(0xFFE74C3C); // Red
      case 'Groceries':
        return const Color(0xFF2ECC71); // Green
      case 'Rent':
        return const Color(0xFF9B59B6); // Purple
      case 'Gifts':
        return const Color(0xFFF1C40F); // Yellow/Gold
      case 'Savings':
        return const Color(0xFF1ABC9C); // Turquoise
      case 'Entertainment':
        return const Color(0xFFE84393); // Pink
      case 'Salary':
        return const Color(0xFF27AE60); // Dark Green
      case 'Work':
        return const Color(0xFF8D6E63); // Brown
      case 'Gaming':
        return const Color(0xFF3F51B5); // Indigo
      case 'Others':
        return const Color(0xFF7F8C8D); // Slate Grey
      default:
        // Use a fixed palette of 10 more colors for dynamic categories
        final List<Color> dynamicColors = [
          const Color(0xFF16A085), // Dark turquoise
          const Color(0xFF2980B9), // Dark blue
          const Color(0xFF8E44AD), // Dark purple
          const Color(0xFFD35400), // Dark orange
          const Color(0xFFC0392B), // Dark red
          const Color(0xFFD6A2E8), // Light lavender
          const Color(0xFF1B9CFC), // Clear blue
          const Color(0xFFFD79A8), // Light pink
          const Color(0xFF00CEC9), // Robin egg blue
          const Color(0xFF6C5CE7), // Slate blue
        ];
        final int hash = category.hashCode;
        final int index = hash.abs() % dynamicColors.length;
        return dynamicColors[index];
    }
  }

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
    double totalAmount = 0;
    for (final tx in filteredTransactions) {
      categoryAmounts[tx.category] =
          (categoryAmounts[tx.category] ?? 0) + tx.amount;
      totalAmount += tx.amount;
    }

    final List<CategoryPieData> pieData = [];
    categoryAmounts.forEach((cat, amt) {
      pieData.add(CategoryPieData(
        category: cat,
        amount: amt,
        percentage: totalAmount > 0 ? (amt / totalAmount) * 100 : 0,
        color: _getCategoryColor(cat),
      ));
    });

    // Sort by amount descending
    pieData.sort((a, b) => b.amount.compareTo(a.amount));

    return Row(
      children: [
        // Left side: Pie Chart (Enlarged size)
        SizedBox(
          width: 150,
          height: 150,
          child: PieChartWidget(
            data: pieData,
            title: isExpense ? 'Expense' : 'Income',
            isExpense: isExpense,
          ),
        ),
        const SizedBox(width: 20), // gap to shift list to the right
        // Right side: Scrollable Category List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 2.0),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: pieData.length,
              itemBuilder: (context, index) {
                final item = pieData[index];
                final sign = isExpense ? '-' : '+';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Color indicator
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category Name
                      Expanded(
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Dollar Amount
                      Text(
                        '$sign\$${item.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isExpense
                              ? Colors.red[400]
                              : const Color(0xFF00C18A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class PieChartWidget extends StatefulWidget {
  final List<CategoryPieData> data;
  final String title;
  final bool isExpense;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
    required this.isExpense,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int? _selectedIndex;

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Leaving a 12px margin on the radius
    final radius = (size.width / 2) - 12;

    // Check if touch is within the pie chart area (donut boundary)
    if (distance > radius + 10 || distance < radius * 0.2) {
      if (_selectedIndex != null) {
        setState(() {
          _selectedIndex = null;
        });
      }
      return;
    }

    double angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    // Adjust for startAngle = -pi/2
    double adjustedAngle = angle - (-pi / 2);
    if (adjustedAngle < 0) {
      adjustedAngle += 2 * pi;
    }
    adjustedAngle = adjustedAngle % (2 * pi);

    double currentAngle = 0;
    int? foundIndex;
    for (int i = 0; i < widget.data.length; i++) {
      final sweepAngle = (widget.data[i].percentage / 100) * 2 * pi;
      if (adjustedAngle >= currentAngle &&
          adjustedAngle < currentAngle + sweepAngle) {
        foundIndex = i;
        break;
      }
      currentAngle += sweepAngle;
    }

    if (foundIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = foundIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final selectedItem =
            _selectedIndex != null ? widget.data[_selectedIndex!] : null;

        // Dynamic center hole diameter matching the 12px margin and 0.60 ratio
        final innerDiameter = (size.width - 24) * 0.60;

        return GestureDetector(
          onPanDown: (details) => _handleTouch(details.localPosition, size),
          onPanUpdate: (details) => _handleTouch(details.localPosition, size),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          onPanCancel: () => setState(() => _selectedIndex = null),
          onTapDown: (details) => _handleTouch(details.localPosition, size),
          onTapUp: (_) => setState(() => _selectedIndex = null),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: size,
                painter: PieChartPainter(
                  data: widget.data,
                  selectedIndex: _selectedIndex,
                ),
              ),
              // Center hole content
              IgnorePointer(
                child: Container(
                  width: innerDiameter,
                  height: innerDiameter,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedItem != null
                                ? selectedItem.category
                                : widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (selectedItem != null) ...[
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${selectedItem.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedItem.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<CategoryPieData> data;
  final int? selectedIndex;

  PieChartPainter({required this.data, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Leave 12px margin on the radius to prevent clipping on enlargement (+6) and offset (+4)
    final double radius = (size.width / 2) - 12;
    final Offset center = Offset(size.width / 2, size.height / 2);

    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.percentage / 100) * 2 * pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final isSelected = selectedIndex == i;
      final double sliceRadius = isSelected ? radius + 6 : radius;

      if (isSelected) {
        final double middleAngle = startAngle + sweepAngle / 2;
        final Offset offset =
            Offset(cos(middleAngle) * 4, sin(middleAngle) * 4);
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sliceRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      if (isSelected) {
        canvas.restore();
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}
