import 'package:a_management/widget/appsnackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/data_transaction.dart';
import '../services/database_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final String category;
  final VoidCallback? onSaved;

  const EditTransactionScreen({
    super.key,
    required this.category,
    this.onSaved,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  static const Map<String, IconData> icons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Medicine': Icons.medical_services,
    'Groceries': Icons.local_grocery_store,
    'Rent': Icons.home,
    'Gifts': Icons.card_giftcard,
    'Savings': Icons.savings,
    'Entertainment': Icons.movie,
    'Salary': Icons.wallet,
    'Work': Icons.work,
    'Gaming': Icons.sports_esports,
    'Others': Icons.more_horiz,
  };
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isSaving = false;

  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.category;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final item = TransactionItem(
      icon: icons[widget.category]!,
      title: _titleCtrl.text.trim(),
      category: widget.category,
      time: timeStr,
      date: _selectedDate,
      amount: double.parse(_amountCtrl.text.trim()),
      isExpense: _isExpense,
    );

    await DatabaseService().insertTransaction(item);

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
                    _buildLabel('Category'),
                    const SizedBox(height: 8),
                    CategoryField('Food'),
                    const SizedBox(height: 8),
                    _buildLabel('Tiêu đề'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleCtrl,
                      hint: 'Nhập tiêu đề giao dịch',
                      icon: Icons.edit_note,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tiêu đề'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Amount field
                    _buildLabel('Số tiền (\$)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _amountCtrl,
                      hint: '0.00',
                      icon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Số tiền không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    _buildLabel('Ngày giao dịch'),
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
                                'Lưu giao dịch',
                                style: TextStyle(
                                  fontSize: 17,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  DropdownButtonFormField<String> CategoryField(String selected) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      items: icons.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                entry.value,
                color: const Color(0xFF14C38E),
              ),
              const SizedBox(width: 12),
              Text(entry.key),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selected = value!;
        });
      },
    );
  }

  // void showCategoryPicker(String selected) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return DraggableScrollableSheet(
  //         expand: false,
  //         initialChildSize: 0.45,
  //         minChildSize: 0.3,
  //         maxChildSize: 0.8,
  //         builder: (context, scrollController) {
  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(
  //                 top: Radius.circular(24),
  //               ),
  //             ),
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 12),
  //                 Container(
  //                   width: 50,
  //                   height: 5,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey,
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   "Chọn danh mục",
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Expanded(
  //                   child: GridView.builder(
  //                     controller: scrollController,
  //                     padding: const EdgeInsets.all(16),
  //                     itemCount: icons.length,
  //                     gridDelegate:
  //                         const SliverGridDelegateWithFixedCrossAxisCount(
  //                       crossAxisCount: 3,
  //                       childAspectRatio: 1,
  //                       crossAxisSpacing: 12,
  //                       mainAxisSpacing: 12,
  //                     ),
  //                     itemBuilder: (context, index) {
  //                       final entry = icons.entries.elementAt(index);

  //                       return InkWell(
  //                         borderRadius: BorderRadius.circular(16),
  //                         onTap: () {
  //                           setState(() {
  //                             selected = entry.key;
  //                           });

  //                           Navigator.pop(context);
  //                         },
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(16),
  //                             color: selected == entry.key
  //                                 ? Colors.green.shade50
  //                                 : Colors.grey.shade100,
  //                             border: Border.all(
  //                               color: selected == entry.key
  //                                   ? Colors.green
  //                                   : Colors.transparent,
  //                             ),
  //                           ),
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Icon(
  //                                 entry.value,
  //                                 size: 32,
  //                                 color: Colors.green,
  //                               ),
  //                               const SizedBox(height: 8),
  //                               Text(entry.key),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}
