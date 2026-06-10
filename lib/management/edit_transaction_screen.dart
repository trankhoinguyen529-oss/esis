import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/widget/appsnackbar.dart';
import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/icon_map.dart';
import '../services/database_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final int id;
  final VoidCallback? onSaved;

  const EditTransactionScreen({
    super.key,
    required this.id,
    this.onSaved,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _textField = Textfield();
  final _pickdate = Pickdate();

  DateTime selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isSaving = false;
  String selectedCategory = '';
  String selectedTitle = '';
  double selectedAmount = 0.00;
  late DatabaseService db;
  TransactionItem? item;

  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  @override
  void initState() {
    // ✅ bỏ async
    super.initState();
    db = DatabaseService();
    _loadData(); // gọi hàm async riêng
  }

  Future<void> _loadData() async {
    final result = await db.getTransactionItem_byID(widget.id);
    if (result == null) {
      if (mounted) {
        Appsnackbar.success_snackbar(
          context,
          'No Transaction Founded.',
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      item = result;
      _isExpense = item!.isExpense;
      selectedCategory = item!.category;
      selectedAmount = item!.amount;
      selectedTitle = item!.title;
      selectedDate = item!.date;
      _titleCtrl.text = item!.title;
      _amountCtrl.text = item!.amount.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (item == null) return;

    setState(() => _isSaving = true);

    final timeStr = item!.time;
    final updatedItem = TransactionItem(
      id: item!.id,
      icon:
          CategoryItem.icons[selectedCategory] ?? CategoryItem.icons['Others']!,
      title: _titleCtrl.text.trim(),
      category: selectedCategory,
      time: timeStr,
      date: selectedDate,
      amount: double.parse(_amountCtrl.text.trim()),
      isExpense: _isExpense,
    );

    await db.updateTransaction(updatedItem);

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onSaved?.call();
      Appsnackbar.success_snackbar(context, 'Changes Saved');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    //if (!_formKey.currentState!.validate()) return;
    // if (item == null) return;

    setState(() => _isSaving = true);

    // final timeStr = item!.time;
    // final updatedItem = TransactionItem(
    //   id: item!.id,
    //   icon: icons[selectedCategory] ?? icons['Others']!,
    //   title: _titleCtrl.text.trim(),
    //   category: selectedCategory,
    //   time: timeStr,
    //   date: selectedDate,
    //   amount: double.parse(_amountCtrl.text.trim()),
    //   isExpense: _isExpense,
    // );

    await db.deleteTransaction(item!.id);

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onSaved?.call();
      Appsnackbar.success_snackbar(context, 'Transaction Deleted');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

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
          'Edit Transaction',
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
                    // Income / Expense toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isExpense = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isExpense
                                      ? primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: !_isExpense
                                          ? Colors.white
                                          : Colors.black54,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        color: !_isExpense
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isExpense = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isExpense
                                      ? Colors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.trending_down,
                                      color: _isExpense
                                          ? Colors.white
                                          : Colors.black54,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: _isExpense
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title field
                    _textField.buildLabel('Category'),
                    const SizedBox(height: 8),
                    _textField.buildFormField(
                      context: context,
                      icons: CategoryItem.icons,
                      ifSelected: (selected) {
                        setState(() => selectedCategory = selected);
                      },
                      selectedKey: selectedCategory,
                    ),
                    const SizedBox(height: 8),
                    _textField.buildLabel('Title'),
                    const SizedBox(height: 8),
                    _textField.buildTextField(
                      controller: _titleCtrl,
                      hint: selectedTitle,
                      icon: Icons.edit_note,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please Enter Title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Amount field
                    _textField.buildLabel('Amount (\$)'),
                    const SizedBox(height: 8),
                    _textField.buildTextField(
                      controller: _amountCtrl,
                      hint: '$selectedAmount',
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
                    // Date picker
                    _textField.buildLabel('Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickdate.PickDate(
                        context: context,
                        selectedDate: selectedDate,
                        ifPicked: (picked) {
                          setState(() => selectedDate = picked);
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
                        onPressed: _isSaving ? null : _save,
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
                                'Save',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                ShowDialog().showLogoutDialog(
                                  context,
                                  'Delete',
                                  'Are you sure to delete',
                                  () {},
                                  () {},
                                  () {
                                    _delete();
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
                                'Delete',
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
