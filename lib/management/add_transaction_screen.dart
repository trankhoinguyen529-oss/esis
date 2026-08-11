import 'package:a_management/widget/icon_map.dart';
import 'package:a_management/widget/appsnackbar.dart';
import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/data_transaction.dart';
import '../data/wallet.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? category;
  final VoidCallback? onSaved;

  const AddTransactionScreen({
    super.key,
    this.category,
    this.onSaved,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  bool _showNumPad = false;

  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isSaving = false;
  Textfield textfield = Textfield();
  late String selectedCategory =
      (widget.category != null && widget.category != 'All')
          ? widget.category!
          : 'Others';

  DatabaseService db = DatabaseService();
  Map<String, IconData> itemMap = {};
  List<WalletItem> _wallets = [];
  WalletItem? _selectedWallet;
  bool _isLoadingWallets = true;

  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadWallets();
    _titleCtrl.text = selectedCategory;
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await db.getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        if (_wallets.isNotEmpty) {
          _selectedWallet = _wallets.firstWhere(
            (w) => w.isDefault,
            orElse: () => _wallets.first,
          );
        }
        _isLoadingWallets = false;
      });
    } catch (e) {
      debugPrint('Error loading wallets: $e');
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _loadCategories() async {
    final entries = await db.getCategory();
    if (!mounted) return;
    setState(() {
      itemMap = {for (final cat in entries) cat.title: cat.icon};
    });
  }

  Widget _buildWalletSelector() {
    if (_isLoadingWallets) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }
    if (_wallets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No wallets found. Please add a wallet first.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          final isSelected = _selectedWallet?.id == wallet.id;

          Gradient gradient;
          if (wallet.type.toLowerCase() == 'bank') {
            gradient = const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
          } else if (wallet.type.toLowerCase() == 'card') {
            gradient = const LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
          } else if (wallet.type.toLowerCase() == 'cash') {
            gradient = const LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
          } else {
            gradient = const LinearGradient(
              colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedWallet = wallet;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: Colors.transparent, width: 2)
                    : Border.all(color: Colors.black12, width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (wallet.isDefault)
                                Icon(
                                  Icons.star,
                                  color: isSelected ? Colors.white : Colors.orange,
                                  size: 13,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            wallet.type,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black45,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatCurrency(wallet.balance),
                        style: TextStyle(
                          color: isSelected ? Colors.white : primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (_isExpense && _selectedWallet != null && _selectedWallet!.balance < amount) {
      if (mounted) {
        Appsnackbar.error_snackbar(context, 'Số dư ví không đủ để thực hiện giao dịch!');
        setState(() => _isSaving = false);
      }
      return;
    }

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final resolvedIcon =
        await DatabaseService().getCategoryIcon(selectedCategory);

    final item = TransactionItem(
      //icon: resolvedIcon,
      title: _titleCtrl.text.trim(),
      category: selectedCategory,
      time: timeStr,
      date: _selectedDate,
      amount: amount,
      isExpense: _isExpense,
    );

    await DatabaseService().insertTransaction(item);

    if (_selectedWallet != null && _selectedWallet!.id != null) {
      try {
        await db.adjustWalletBalance(_selectedWallet!.id!, amount, _isExpense);
      } catch (e) {
        debugPrint('Error adjusting wallet balance: $e');
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onSaved?.call();
      Appsnackbar.success_snackbar(context, 'Transaction saved');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return GestureDetector(
      onTap: () => setState(() => _showNumPad = false),
      child: Scaffold(
        bottomSheet: _showNumPad
            ? NumberKeyboard(
                controller: _amountCtrl,
                confirmColor: Colors.blue,
                onConfirm: () => setState(() => _showNumPad = false),
              )
            : null,
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
          title: Text(
            'Add Transaction',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: (widget.category != 'All') ? 20 : 32,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: (widget.category != 'All')
                  ? Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: surface,
                            shape: BoxShape.circle,
                          ),
                          child: FutureBuilder<IconData>(
                            future: DatabaseService()
                                .getCategoryIcon(selectedCategory),
                            builder: (context, snapshot) {
                              final icon = snapshot.data ?? Icons.category;
                              return Icon(icon, color: primary, size: 36);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedCategory,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
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
                      textfield.buildLabel('Select Wallet'),
                      const SizedBox(height: 8),
                      _buildWalletSelector(),
                      const SizedBox(height: 16),
                      // Category field
                      textfield.buildLabel('Category'),
                      const SizedBox(height: 8),
                      textfield.buildFormField_1(
                        context: context,
                        items: itemMap,
                        excludedItems: {'All', 'Bank'},
                        ifSelected: (selected) {
                          setState(() => selectedCategory = selected);
                        },
                        selectedKey: selectedCategory,
                      ),
                      const SizedBox(height: 16),
                      // Title field
                      textfield.buildLabel('Title'),
                      const SizedBox(height: 8),
                      textfield.buildTextField(
                        controller: _titleCtrl,
                        hint: 'Enter Title',
                        icon: Icons.edit_note,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please Enter Title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Amount field
                      textfield.buildLabel('Amount (đ)'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showNumPad = true), // ✅ mở numpad
                        child: AbsorbPointer(
                          // ✅ chặn bàn phím hệ thống
                          child: textfield.buildTextField(
                            controller: _amountCtrl,
                            hint: '0.00',
                            icon: Icons.attach_money,
                            keyboardType:
                                TextInputType.none, // ✅ tắt bàn phím hệ thống
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date picker
                      textfield.buildLabel('Date'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
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
                        height: 56,
                        width: 160,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
