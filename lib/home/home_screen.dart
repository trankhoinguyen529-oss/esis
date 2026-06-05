import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import '../profile/edit_profile.dart';
import '../profile/profile_screen.dart';
import '../services/auth_service.dart';
import '../management/management_screen.dart';
import 'tab_icon.dart';
import '../transaction/transaction_screen.dart';
import '../data/data_transaction.dart';
import 'dart:math';

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
  final Calculatesummary calculatesummary = Calculatesummary();

  @override
  void initState() {
    calculatesummary.calculateSummary(2);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() {
            _currentPage = index;
            // if (index != 3) {
            //   _profileView = _ProfileView.profile;
            // }
          }),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHomePage(primary, surface, displayName, context),
            const TransactionScreen(),
            const ManagementScreen(),
            const ProfileScreen(),
            //_buildProfileWrapper(),
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
                      Icon(
                        Icons.trending_up,
                        color: Color(0xFF00C18A),
                        size: 30,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        calculatesummary.sIncome,
                        style: TextStyle(
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
                      Icon(
                        Icons.trending_down,
                        color: Colors.blue,
                        size: 30,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        calculatesummary.sExpense,
                        style: TextStyle(
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
                          setState(() {
                            _selectedPeriod = i;
                            calculatesummary.calculateSummary(_selectedPeriod);
                          });
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
                  child:
                      Displaytransaction().displayTransaction(_selectedPeriod),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
