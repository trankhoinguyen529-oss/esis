import 'package:flutter/material.dart';
import 'package:a_management/widget/widget.dart';
import 'package:a_management/services/database_service.dart';

class TransactionScreen extends StatefulWidget {
  final VoidCallback? onTransactionAdded;
  const TransactionScreen({super.key, this.onTransactionAdded});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  int _selectedPeriod = -1; // -1 = All, 0=Daily, 1=Weekly, 2=Monthly

  double _income = 0;
  double _expense = 0;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);

    return Container(
      color: primary,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Transaction',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Income / Expense summary
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
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                children: [
                  // Bộ lọc All / Daily / Weekly / Monthly
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedPeriod == -1,
                          onTap: () {
                            setState(() => _selectedPeriod = -1);
                            _loadSummary();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Daily',
                          selected: _selectedPeriod == 0,
                          onTap: () {
                            setState(() => _selectedPeriod = 0);
                            _loadSummary();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Weekly',
                          selected: _selectedPeriod == 1,
                          onTap: () {
                            setState(() => _selectedPeriod = 1);
                            _loadSummary();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Monthly',
                          selected: _selectedPeriod == 2,
                          onTap: () {
                            setState(() => _selectedPeriod = 2);
                            _loadSummary();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _TransactionListView(period: _selectedPeriod),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : const Color(0xFFE0F5EE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TransactionListView extends StatelessWidget {
  final int period;
  const _TransactionListView({required this.period});

  @override
  Widget build(BuildContext context) {
    return Displaytransaction().displayTransaction(period, 'all', (int i) {});
  }
}
