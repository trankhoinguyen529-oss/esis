import 'package:flutter/material.dart';
import 'package:a_management/services/database_service.dart';

class DisplayBudget extends StatefulWidget {
  final Function(Map<String, dynamic> budget, double spentAmount)? onTap;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const DisplayBudget({
    super.key,
    this.onTap,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  State<DisplayBudget> createState() => _DisplayBudgetState();
}

class _DisplayBudgetState extends State<DisplayBudget> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _budgets = [];
  Map<int, double> _spentAmounts = {};

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final budgets = await _db.getSavingExpenditureItems(type: 1);
      final transactions = await _db.getAllTransactions();

      final Map<int, double> spent = {};
      for (final budget in budgets) {
        final id = budget['id'] as int;
        final associatedCatsStr = budget['associated_categories'] as String? ?? '';
        final cats = associatedCatsStr
            .split(',')
            .map((c) => c.trim().toLowerCase())
            .where((c) => c.isNotEmpty)
            .toList();

        final startDateStr = budget['start_date'] as String? ?? '';
        final endDateStr = budget['end_date'] as String? ?? '';

        final start = DateTime.tryParse(startDateStr);
        final end = DateTime.tryParse(endDateStr);

        double totalSpent = 0.0;
        for (final t in transactions) {
          if (!t.isExpense) continue;

          // Check category
          if (cats.isNotEmpty && !cats.contains(t.category.trim().toLowerCase())) {
            continue;
          }

          // Check date
          bool dateMatches = true;
          if (start != null) {
            dateMatches = dateMatches && (t.date.isAfter(start) || DateUtils.isSameDay(t.date, start));
          }
          if (end != null) {
            dateMatches = dateMatches && (t.date.isBefore(end) || DateUtils.isSameDay(t.date, end));
          }

          if (dateMatches) {
            totalSpent += t.amount;
          }
        }
        spent[id] = totalSpent;
      }

      if (mounted) {
        setState(() {
          _budgets = budgets;
          _spentAmounts = spent;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double val) {
    return formatCurrency(val);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00C18A);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No expenditure item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        final id = budget['id'] as int;
        final title = budget['title'] as String? ?? 'Budget';
        final iconCode = budget['icon_code'] as int? ?? Icons.star.codePoint;
        final budgetVal = (budget['value'] as num? ?? 0.0).toDouble();
        final spentVal = _spentAmounts[id] ?? 0.0;
        final endDateStr = budget['end_date'] as String? ?? '';

        final iconData = IconData(iconCode, fontFamily: 'MaterialIcons');

        // Remaining value = total - spent
        final remainingVal = budgetVal - spentVal;

        // Calculate days left
        String daysLeftText = '';
        if (endDateStr.isNotEmpty) {
          final end = DateTime.tryParse(endDateStr);
          if (end != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final target = DateTime(end.year, end.month, end.day);
            final diff = target.difference(today).inDays;
            if (diff < 0) {
              daysLeftText = 'Expired';
            } else if (diff == 0) {
              daysLeftText = 'Ends today';
            } else {
              daysLeftText = '$diff days remaining';
            }
          }
        } else {
          daysLeftText = 'No expiration';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap != null ? () => widget.onTap!(budget, spentVal) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon on the left
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Middle: Title & Days remaining
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          daysLeftText,
                          style: TextStyle(
                            fontSize: 12,
                            color: daysLeftText == 'Expired' ? Colors.redAccent : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: Remaining & Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCurrency(remainingVal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: remainingVal < 0 ? Colors.redAccent : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Limit: ${_formatCurrency(budgetVal)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
