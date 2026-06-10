import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/widget/appsnackbar.dart';
import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/icon_map.dart';
import '../services/database_service.dart';

class TransactionFilterScreen extends StatefulWidget {
  const TransactionFilterScreen({
    super.key,
  });

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _textfield = Textfield();
  final _pickdate = Pickdate();

  DateTime selectedDateFrom = DateTime.now();
  DateTime selectedDateTo = DateTime.now();
  bool _isExpense = true;
  bool _isSaving = false;
  String selectedCategory = '';
  String selectedTitle = '';
  String selectedType = '';
  double selectedAmountFrom = 0.00;
  double selectedAmountTo = 0.00;
  late DatabaseService db;
  TransactionItem? item;

  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  @override
  void initState() {}

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${selectedDateTo.day.toString().padLeft(2, '0')}/${selectedDateTo.month.toString().padLeft(2, '0')}/${selectedDateTo.year}';

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black87, size: 18),
          ),
        ),
        title: const Text(
          'Transaction Filter',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 30,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category header
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    // // Income/Expense field
                    _textfield.buildLabel('Type'),
                    const SizedBox(height: 8),
                    _textfield.buildFormField(
                      context: context,
                      icons: TypeItem.icons,
                      ifSelected: (selected) {
                        setState(() => selectedType = selected);
                      },
                      selectedKey: selectedType,
                    ),
                    const SizedBox(height: 8),
                    // Category field
                    _textfield.buildLabel('Category'),
                    const SizedBox(height: 8),
                    _textfield.buildFormField(
                      context: context,
                      icons: CategoryItem.icons,
                      ifSelected: (selected) {
                        setState(() => selectedCategory = selected);
                      },
                      selectedKey: selectedCategory,
                    ),
                    const SizedBox(height: 8),
                    // Title field
                    _textfield.buildLabel('Title'),
                    const SizedBox(height: 8),
                    _textfield.buildTextField(
                      controller: _titleCtrl,
                      hint: selectedTitle,
                      icon: Icons.edit_note,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please Enter Title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Amount field from
                    _textfield.buildLabel('From(\$)'),
                    const SizedBox(height: 8),
                    _textfield.buildTextField(
                      controller: _amountCtrl,
                      hint: '',
                      icon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please Enter Amount';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid Amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Amount field up to
                    _textfield.buildLabel('Up To(\$)'),
                    const SizedBox(height: 8),
                    _textfield.buildTextField(
                      controller: _amountCtrl,
                      hint: '',
                      icon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please Enter Amount';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid Amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date picker from
                    _textfield.buildLabel('From'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickdate.PickDate(
                        context: context,
                        selectedDate: selectedDateTo,
                        ifPicked: (picked) {
                          setState(() => selectedDateTo = picked);
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: primary, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date picker uo to
                    _textfield.buildLabel('Up To'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickdate.PickDate(
                        context: context,
                        selectedDate: selectedDateTo,
                        ifPicked: (picked) {
                          setState(() => selectedDateTo = picked);
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: primary, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
