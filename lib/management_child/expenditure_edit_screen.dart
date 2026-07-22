import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/data/data_category.dart';
import 'package:a_management/assets/icon/categoryIcon.dart';
import 'package:a_management/widget/widget.dart';

class ExpenditureEditScreen extends StatefulWidget {
  final Map<String, dynamic> budget;
  final double spentAmount;

  const ExpenditureEditScreen({
    super.key,
    required this.budget,
    required this.spentAmount,
  });

  @override
  State<ExpenditureEditScreen> createState() => _ExpenditureEditScreenState();
}

class _ExpenditureEditScreenState extends State<ExpenditureEditScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _textfield = Textfield();

  late TextEditingController _titleController;
  late TextEditingController _valueController;

  late IconData _selectedIcon;
  late Set<String> _selectedCategories;
  Map<String, IconData> _categoryItemMap = {};
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _loopable;
  late double _spentAmount;

  List<CategoryItem> _categories = [];
  bool _isLoadingCategories = true;

  static const Color primaryColor = Color(0xFF00C18A);
  static const Color scaffoldBg = Color(0xFFF6F9F8);

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _titleController = TextEditingController(text: b['title'] as String? ?? '');
    _valueController =
        TextEditingController(text: (b['value'] as num? ?? 0).toString());

    final iconCode = b['icon_code'] as int? ?? Icons.star.codePoint;
    _selectedIcon = IconData(iconCode, fontFamily: 'MaterialIcons');

    final catsStr = b['associated_categories'] as String? ?? '';
    _selectedCategories = catsStr
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet();

    _startDate =
        DateTime.tryParse(b['start_date'] as String? ?? '') ?? DateTime.now();
    _endDate = DateTime.tryParse(b['end_date'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 30));
    _loopable = (b['loopable'] as int? ?? 0) == 1;
    _spentAmount = widget.spentAmount;

    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _db.getCategory();
      setState(() {
        _categories = cats;
        _categoryItemMap = {for (final cat in cats) cat.title: cat.icon};
        _isLoadingCategories = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category.')),
      );
      return;
    }

    final value = int.tryParse(_valueController.text) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a budget greater than 0.')),
      );
      return;
    }

    final updatedItem = {
      'id': widget.budget['id'],
      'user_id': _db.currentUserId,
      'type': 1,
      'title': _titleController.text.trim(),
      'icon_code': _selectedIcon.codePoint,
      'value': value,
      'current_value': widget.budget['current_value'] ?? 0,
      'associated_categories': _selectedCategories.join(', '),
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'loopable': _loopable ? 1 : 0,
    };

    await _db.updateSavingExpenditureItem(updatedItem);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Budget'),
        content:
            const Text('Are you sure you want to delete this budget? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _db.deleteSavingExpenditureItem(widget.budget['id'] as int);
    if (!mounted) return;
    Navigator.pop(context);
  }

  String _formatCurrency(double val) {
    if (val == val.toInt()) {
      return '\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '\$${val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final budgetVal = (int.tryParse(_valueController.text) ?? 0).toDouble();
    final remainingVal = budgetVal - _spentAmount;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Edit Budget',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingCategories
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 1. Title & Icon ───────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_selectedIcon,
                                color: primaryColor, size: 40),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Budget Icon',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Icon selector horizontal scroll
                    SizedBox(
                      height: 55,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: CategoryIcon.categoryIcons.length,
                        itemBuilder: (context, idx) {
                          final icon = CategoryIcon.categoryIcons[idx];
                          final isSelected = icon == _selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    const Text(
                      'Budget Title',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly Food, Gym Budget',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ─── 2. Corresponding Category ─────────────────
                    _textfield.buildLabel('Corresponding Category'),
                    const SizedBox(height: 8),
                    _categories.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                                'No categories available. Please create categories first.'),
                          )
                        : _textfield.buildFormField_M(
                            context: context,
                            items: _categoryItemMap,
                            excludedItems: const {'Bank'},
                            ifSelected: (selected) {
                              setState(() {
                                _selectedCategories = selected;
                              });
                            },
                            selectedKeys: _selectedCategories,
                          ),
                    const SizedBox(height: 20),

                    // ─── 3. Duration ───────────────────────────────
                    const Text(
                      'Duration Period',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Start Date
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Start Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500)),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  dateFmt.format(_startDate),
                                  style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: _selectStartDate,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // End Date
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('End Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500)),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  dateFmt.format(_endDate),
                                  style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: _selectEndDate,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // Today (read-only)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(
                                dateFmt.format(DateTime.now()),
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── 4. Budget Limit ───────────────────────────
                    const Text(
                      'Budget Limit',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Remaining / Total display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatCurrency(remainingVal),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: remainingVal < 0
                                      ? Colors.redAccent
                                      : primaryColor,
                                ),
                              ),
                              Text(
                                ' / ${_formatCurrency(budgetVal)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remaining',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          // Budget value text field
                          TextFormField(
                            controller: _valueController,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: false),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Enter budget amount',
                              fillColor: scaffoldBg,
                              filled: true,
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter a value';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid integer';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── 5. Transactions ───────────────────────────
                    const Text(
                      'Transactions',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Displaytransaction().displayTransaction(
                        period: -1,
                        type: 'Expense',
                        bank: 'All',
                        categories: _selectedCategories,
                        title: '',
                        amountFrom: 0,
                        amountTo: double.maxFinite,
                        dateFrom: _startDate,
                        dateTo: _endDate,
                        ontap: (_) {},
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        physics:
                            const ClampingScrollPhysics(),
                        shrinkWrap: false,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── 6. Repeat ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile.adaptive(
                        title: const Text(
                          'Repeat budget automatically',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            const Text('Restart limit when period ends'),
                        activeColor: primaryColor,
                        value: _loopable,
                        onChanged: (val) {
                          setState(() {
                            _loopable = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── 7. Save & Delete ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Delete Budget',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
