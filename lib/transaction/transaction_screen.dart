import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:a_management/widget/widget.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/widget/category_item_icon.dart';
import 'package:a_management/widget/displaytransaction.dart';
import 'package:a_management/management/edit_transaction_screen.dart';

enum TransactionFilterType { all, income, expense }

class TransactionScreen extends StatefulWidget {
  final VoidCallback? onTransactionAdded;
  const TransactionScreen({super.key, this.onTransactionAdded});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<TransactionItem> _allTransactions = [];
  List<TransactionItem> _filteredTransactions = [];
  bool _isLoading = true;

  // Filter criteria state
  TransactionFilterType _filterType = TransactionFilterType.all;
  Set<String> _selectedCategories = {};
  DateTimeRange? _selectedDateRangeFilter;
  DateTime? _selectedSingleDate;
  bool _isRangeDateMode = true; // true = Date Range, false = Single Date
  double? _minAmount;
  double? _maxAmount;

  double _income = 0;
  double _expense = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(covariant TransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final list = await DatabaseService().getAllTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = list;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<TransactionItem> temp = List.from(_allTransactions);

    // 1. Filter by Type
    if (_filterType != TransactionFilterType.all) {
      final isExpense = _filterType == TransactionFilterType.expense;
      temp = temp.where((item) => item.isExpense == isExpense).toList();
    }

    // 2. Filter by Categories (multichoice)
    if (_selectedCategories.isNotEmpty) {
      temp = temp.where((item) => _selectedCategories.contains(item.category)).toList();
    }

    // 3. Filter by Date (Một ngày hoặc Khoảng ngày)
    if (_isRangeDateMode) {
      if (_selectedDateRangeFilter != null) {
        temp = temp.where((item) {
          final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
          final startDate = DateTime(
            _selectedDateRangeFilter!.start.year,
            _selectedDateRangeFilter!.start.month,
            _selectedDateRangeFilter!.start.day,
          );
          final endDate = DateTime(
            _selectedDateRangeFilter!.end.year,
            _selectedDateRangeFilter!.end.month,
            _selectedDateRangeFilter!.end.day,
          );
          return !itemDate.isBefore(startDate) && !itemDate.isAfter(endDate);
        }).toList();
      }
    } else {
      if (_selectedSingleDate != null) {
        temp = temp.where((item) =>
            item.date.year == _selectedSingleDate!.year &&
            item.date.month == _selectedSingleDate!.month &&
            item.date.day == _selectedSingleDate!.day).toList();
      }
    }

    // 4. Filter by Price (above / below amount)
    if (_minAmount != null) {
      temp = temp.where((item) => item.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      temp = temp.where((item) => item.amount <= _maxAmount!).toList();
    }

    _filteredTransactions = temp;

    // Recalculate summary from filtered list
    _income = 0;
    _expense = 0;
    for (final item in _filteredTransactions) {
      if (item.isExpense) {
        _expense += item.amount;
      } else {
        _income += item.amount;
      }
    }
  }

  bool get _hasActiveFilters {
    return _filterType != TransactionFilterType.all ||
        _selectedCategories.isNotEmpty ||
        (_isRangeDateMode ? _selectedDateRangeFilter != null : _selectedSingleDate != null) ||
        _minAmount != null ||
        _maxAmount != null;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet(
          initialType: _filterType,
          initialCategories: _selectedCategories,
          initialDateRange: _selectedDateRangeFilter,
          initialSingleDate: _selectedSingleDate,
          initialIsRangeMode: _isRangeDateMode,
          initialMinAmount: _minAmount,
          initialMaxAmount: _maxAmount,
          onApply: (type, categories, dateRange, singleDate, isRangeMode, minAmount, maxAmount) {
            setState(() {
              _filterType = type;
              _selectedCategories = categories;
              _selectedDateRangeFilter = dateRange;
              _selectedSingleDate = singleDate;
              _isRangeDateMode = isRangeMode;
              _minAmount = minAmount;
              _maxAmount = maxAmount;
              _applyFilters();
            });
          },
        );
      },
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final List<Widget> chips = [];

    // Type chip
    if (_filterType != TransactionFilterType.all) {
      chips.add(
        _ActiveChip(
          label: _filterType == TransactionFilterType.income ? 'Thu nhập' : 'Chi tiêu',
          onDelete: () {
            setState(() {
              _filterType = TransactionFilterType.all;
              _applyFilters();
            });
          },
        ),
      );
    }

    // Categories chips
    for (final cat in _selectedCategories) {
      chips.add(
        _ActiveChip(
          label: cat,
          onDelete: () {
            setState(() {
              _selectedCategories.remove(cat);
              _applyFilters();
            });
          },
        ),
      );
    }

    // Date Range / Single Date chip
    if (_isRangeDateMode) {
      if (_selectedDateRangeFilter != null) {
        final startStr =
            '${_selectedDateRangeFilter!.start.day}/${_selectedDateRangeFilter!.start.month}/${_selectedDateRangeFilter!.start.year}';
        final endStr =
            '${_selectedDateRangeFilter!.end.day}/${_selectedDateRangeFilter!.end.month}/${_selectedDateRangeFilter!.end.year}';
        chips.add(
          _ActiveChip(
            label: '$startStr - $endStr',
            onDelete: () {
              setState(() {
                _selectedDateRangeFilter = null;
                _applyFilters();
              });
            },
          ),
        );
      }
    } else {
      if (_selectedSingleDate != null) {
        final dateStr =
            '${_selectedSingleDate!.day}/${_selectedSingleDate!.month}/${_selectedSingleDate!.year}';
        chips.add(
          _ActiveChip(
            label: dateStr,
            onDelete: () {
              setState(() {
                _selectedSingleDate = null;
                _applyFilters();
              });
            },
          ),
        );
      }
    }

    // Min amount chip
    if (_minAmount != null) {
      chips.add(
        _ActiveChip(
          label: '>= \$${_minAmount!.toStringAsFixed(0)}',
          onDelete: () {
            setState(() {
              _minAmount = null;
              _applyFilters();
            });
          },
        ),
      );
    }

    // Max amount chip
    if (_maxAmount != null) {
      chips.add(
        _ActiveChip(
          label: '<= \$${_maxAmount!.toStringAsFixed(0)}',
          onDelete: () {
            setState(() {
              _maxAmount = null;
              _applyFilters();
            });
          },
        ),
      );
    }

    return chips
        .map((widget) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget,
            ))
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 64, color: Color(0xFFB0C4BE)),
          SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8FA89C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
          // Income / Expense summary cards
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
                        _isLoading
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
                        _isLoading
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
                  // Title and Filter button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sử giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: Color(0xFF00C18A),
                              size: 24,
                            ),
                            if (_hasActiveFilters)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scrollable Active Filter Chips
                  if (_hasActiveFilters) ...[
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: _buildActiveFilterChips(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Filtered transaction list view
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredTransactions.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: _filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredTransactions[index];
                                  return TransactionItemWidget(
                                    item: item,
                                    ontap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditTransactionScreen(
                                            id: item.id!,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadTransactions();
                                        widget.onTransactionAdded?.call();
                                      }
                                    },
                                  );
                                },
                              ),
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

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _ActiveChip({
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 14,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final TransactionFilterType initialType;
  final Set<String> initialCategories;
  final DateTimeRange? initialDateRange;
  final DateTime? initialSingleDate;
  final bool initialIsRangeMode;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final Function(TransactionFilterType, Set<String>, DateTimeRange?, DateTime?, bool, double?, double?) onApply;

  const _FilterBottomSheet({
    required this.initialType,
    required this.initialCategories,
    this.initialDateRange,
    this.initialSingleDate,
    required this.initialIsRangeMode,
    this.initialMinAmount,
    this.initialMaxAmount,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TransactionFilterType _type;
  late Set<String> _categories;
  DateTimeRange? _dateRange;
  DateTime? _singleDate;
  late bool _isRangeMode;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  static const Color primary = Color(0xFF00C18A);

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categories = Set.from(widget.initialCategories);
    _dateRange = widget.initialDateRange;
    _singleDate = widget.initialSingleDate;
    _isRangeMode = widget.initialIsRangeMode;
    if (widget.initialMinAmount != null) {
      _minCtrl.text = widget.initialMinAmount!.toStringAsFixed(0);
    }
    if (widget.initialMaxAmount != null) {
      _maxCtrl.text = widget.initialMaxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _singleDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _singleDate = picked);
    }
  }

  void _resetAll() {
    setState(() {
      _type = TransactionFilterType.all;
      _categories.clear();
      _dateRange = null;
      _singleDate = null;
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _isRangeMode
        ? (_dateRange == null
            ? 'Chọn khoảng ngày'
            : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}')
        : (_singleDate == null
            ? 'Chọn ngày'
            : '${_singleDate!.day}/${_singleDate!.month}/${_singleDate!.year}');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc giao dịch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _resetAll,
                  child: const Text(
                    'Thiết lập lại',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Type selector
            _buildSectionLabel('Loại giao dịch'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeChip('Tất cả', TransactionFilterType.all),
                const SizedBox(width: 8),
                _buildTypeChip('Thu nhập', TransactionFilterType.income),
                const SizedBox(width: 8),
                _buildTypeChip('Chi tiêu', TransactionFilterType.expense),
              ],
            ),
            const SizedBox(height: 20),

            // Categories list (wrap)
            _buildSectionLabel('Danh mục'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryItem.icons.entries.map((entry) {
                final categoryName = entry.key;
                final categoryIcon = entry.value;
                final isSelected = _categories.contains(categoryName);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _categories.remove(categoryName);
                      } else {
                        _categories.add(categoryName);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : const Color(0xFFE8F8F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primary : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 16,
                          color: isSelected ? Colors.white : primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Toggle date mode
            _buildSectionLabel('Chọn ngày giao dịch theo'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildModeChip('Một ngày', false),
                const SizedBox(width: 8),
                _buildModeChip('Khoảng ngày', true),
              ],
            ),
            const SizedBox(height: 12),

            // Date picker field
            GestureDetector(
              onTap: _isRangeMode ? _pickDateRange : _pickSingleDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FFF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isRangeMode ? _dateRange != null : _singleDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_isRangeMode) {
                              _dateRange = null;
                            } else {
                              _singleDate = null;
                            }
                          });
                        },
                        child: const Icon(Icons.clear, color: Colors.black45, size: 20),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Price filters
            _buildSectionLabel('Số tiền giao dịch (\$)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAmountField(
                    controller: _minCtrl,
                    hint: 'Trên bao nhiêu',
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAmountField(
                    controller: _maxCtrl,
                    hint: 'Dưới bao nhiêu',
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final minAmount = double.tryParse(_minCtrl.text.trim());
                  final maxAmount = double.tryParse(_maxCtrl.text.trim());
                  widget.onApply(_type, _categories, _dateRange, _singleDate, _isRangeMode, minAmount, maxAmount);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildTypeChip(String label, TransactionFilterType type) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary : const Color(0xFFE8F8F3),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, bool isRange) {
    final isSelected = _isRangeMode == isRange;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRangeMode = isRange),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary : const Color(0xFFE8F8F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        prefixIcon: Icon(icon, color: primary, size: 18),
        filled: true,
        fillColor: const Color(0xFFF3FFF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
