import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/data/data_category.dart';
import 'package:a_management/assets/icon/categoryIcon.dart';
import 'package:a_management/widget/textfield.dart';

class AddExpenditureScreen extends StatefulWidget {
  const AddExpenditureScreen({super.key});

  @override
  State<AddExpenditureScreen> createState() => _AddExpenditureScreenState();
}

class _AddExpenditureScreenState extends State<AddExpenditureScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _textfield = Textfield();

  final _titleController = TextEditingController();
  final _valueController = TextEditingController();

  IconData _selectedIcon = CategoryIcon.categoryIcons.first;
  Set<String> _selectedCategories = {};
  Map<String, IconData> _categoryItemMap = {};
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _loopable = false;

  List<CategoryItem> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _db.getCategory();
      setState(() {
        _categories = cats;
        _categoryItemMap = {for (final cat in cats) cat.title: cat.icon};
        if (cats.isNotEmpty) {
          _selectedCategories = {cats.first.title};
        }
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
              primary: Color(0xFF00C18A),
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
              primary: Color(0xFF00C18A),
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
        const SnackBar(content: Text('Please enter a budget greater than 0.')),
      );
      return;
    }

    final newItem = {
      'type': 1, // 1 is expenditure
      'title': _titleController.text.trim(),
      'icon_code': _selectedIcon.codePoint,
      'value': value,
      'current_value': 0,
      'associated_categories': _selectedCategories.join(', '),
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'loopable': _loopable ? 1 : 0,
    };

    await _db.insertSavingExpenditureItem(newItem);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00C18A);
    const scaffoldBg = Color(0xFFF6F9F8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Add Expenditure Budget',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Selector Container
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
                            'Select Budget Icon',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Horizontal scrollable Icons
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
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
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

                    // Title Field
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

                    // Category Selection
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

                    // Budget Value
                    const Text(
                      'Budget Limit Value (\$)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      decoration: InputDecoration(
                        hintText: 'Enter budget amount',
                        fillColor: Colors.white,
                        filled: true,
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a value';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid integer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Duration Card
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: _selectStartDate,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                  style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: _selectEndDate,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Loopable Repeat Switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile.adaptive(
                        title: const Text(
                          'Repeat budget automatically',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Restart limit when period ends'),
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

                    // Save Button
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
                          'Save Budget',
                          style: TextStyle(
                              color: Colors.white,
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
