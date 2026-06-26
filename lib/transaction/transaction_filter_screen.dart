import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/icon_map.dart';
import '../services/database_service.dart';

class TransactionFilterScreen extends StatefulWidget {
  DateTime selectedDateFrom = DateTime(2020, 1, 1);
  DateTime selectedDateTo = DateTime(2030, 1, 1);
  Set<String> selectedCategories = {'All'};
  String selectedTitle = '';
  String selectedType = 'All';
  String selectedBank = 'All';
  double selectedAmountFrom = 0.00;
  double selectedAmountTo = 1000000000000.00;
  TransactionFilterScreen({
    super.key,
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.selectedTitle,
    required this.selectedCategories,
    required this.selectedType,
    required this.selectedBank,
    required this.selectedAmountFrom,
    required this.selectedAmountTo,
  });

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountFromCtrl = TextEditingController();
  final _amountToCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _textfield = Textfield();
  final _pickdateFrom = Pickdate();
  final _pickdateTo = Pickdate();
  bool _showNumPad = false;
  TextEditingController? _activeCtrl;

  bool _isSaving = false;
  late DatabaseService db;
  TransactionItem? item;

  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  @override
  void initState() {
    super.initState();
    // ✅ set sẵn giá trị vào controller
    _titleCtrl.text = widget.selectedTitle;
    _amountFromCtrl.text = widget.selectedAmountFrom == 0.00
        ? ''
        : widget.selectedAmountFrom.toStringAsFixed(2);
    _amountToCtrl.text = widget.selectedAmountTo >= 1000000000000.00
        ? ''
        : widget.selectedAmountTo.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountFromCtrl.dispose();
    _amountToCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Thêm dateStr riêng
    final dateStrFrom =
        '${widget.selectedDateFrom.day.toString().padLeft(2, '0')}/${widget.selectedDateFrom.month.toString().padLeft(2, '0')}/${widget.selectedDateFrom.year}';
    final dateStrTo =
        '${widget.selectedDateTo.day.toString().padLeft(2, '0')}/${widget.selectedDateTo.month.toString().padLeft(2, '0')}/${widget.selectedDateTo.year}';

    return GestureDetector(
      onTap: () => setState(() => _showNumPad = false),
      child: Scaffold(
        bottomSheet: _showNumPad && _activeCtrl != null
            ? NumberKeyboard(
                controller: _activeCtrl!,
                confirmColor: Colors.blue,
                onConfirm: () => setState(() {
                  _showNumPad = false;
                  _activeCtrl = null;
                }),
              )
            : null,
        backgroundColor: primary,
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop({
              'type': widget.selectedType,
              'bank': widget.selectedBank,
              'categories': widget.selectedCategories,
              'title': _titleCtrl.text.trim(), // ✅
              'amountFrom':
                  double.tryParse(_amountFromCtrl.text.trim()) ?? 0.00, // ✅
              'amountTo': double.tryParse(_amountToCtrl.text.trim()) ??
                  1000000000000.00, // ✅
              'dateFrom': widget.selectedDateFrom,
              'dateTo': widget.selectedDateTo,
            }),
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
              fontSize: 24,
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
                      _textfield.buildLabel('Income/Expense'),
                      const SizedBox(height: 8),
                      _textfield.buildFormField_1(
                        context: context,
                        icons: TypeItem.icons,
                        excludedIcon: {},
                        ifSelected: (selected) {
                          setState(() => widget.selectedType = selected);
                        },
                        selectedKey: widget.selectedType,
                      ),
                      const SizedBox(height: 8),
                      //Bank/Manual field
                      _textfield.buildLabel('Bank/Manual'),
                      const SizedBox(height: 8),
                      _textfield.buildFormField_1(
                        context: context,
                        icons: BankItem.icons,
                        excludedIcon: {},
                        ifSelected: (selected) {
                          setState(() => widget.selectedBank = selected);
                        },
                        selectedKey: widget.selectedBank,
                      ),
                      const SizedBox(height: 8),

                      // Category field
                      _textfield.buildLabel('Category'),
                      const SizedBox(height: 8),
                      _textfield.buildFormField_M(
                        context: context,
                        icons: CategoryItem1.icons,
                        excludedIcon: {'Bank'},
                        ifSelected: (selected) {
                          setState(() => widget.selectedCategories = selected);
                        },
                        selectedKeys: widget.selectedCategories,
                      ),
                      const SizedBox(height: 8),
                      // Title field
                      _textfield.buildLabel('Title'),
                      const SizedBox(height: 8),
                      _textfield.buildTextField(
                        controller: _titleCtrl,
                        hint: '',
                        icon: Icons.edit_note,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please Enter Title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Amount field from
                      _textfield.buildLabel('From(\$)'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showNumPad = true;
                          _activeCtrl = _amountFromCtrl;
                        }), // ✅ mở numpad
                        child: AbsorbPointer(
                          // ✅ chặn bàn phím hệ thống
                          child: _textfield.buildTextField(
                            controller: _amountFromCtrl,
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
                      // Amount field up to
                      _textfield.buildLabel('Up To(\$)'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showNumPad = true;
                          _activeCtrl = _amountToCtrl;
                        }), // ✅ mở numpad
                        child: AbsorbPointer(
                          // ✅ chặn bàn phím hệ thống
                          child: _textfield.buildTextField(
                            controller: _amountToCtrl,
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
                      // Date picker from
                      _textfield.buildLabel('From'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickdateFrom.PickDate(
                          context: context,
                          selectedDate: widget.selectedDateFrom,
                          ifPicked: (picked) {
                            setState(() => widget.selectedDateFrom = picked);
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
                                dateStrFrom,
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
                      // Date picker up to
                      _textfield.buildLabel('Up To'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickdateTo.PickDate(
                          context: context,
                          selectedDate: widget.selectedDateTo,
                          ifPicked: (picked) {
                            setState(() => widget.selectedDateTo = picked);
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
                                dateStrTo,
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

                      Row(
                        children: [
                          //Reset filter button
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    widget.selectedDateFrom =
                                        DateTime(2020, 1, 1);
                                    widget.selectedDateTo =
                                        DateTime(2030, 1, 1);
                                    widget.selectedAmountFrom = 0.00;
                                    widget.selectedAmountTo = 1000000000000.00;
                                    widget.selectedCategories = {'All'};
                                    widget.selectedTitle = '';
                                    widget.selectedType = 'All';
                                  });
                                  // ✅ reset controller riêng
                                  _titleCtrl.clear();
                                  _amountFromCtrl.clear();
                                  _amountToCtrl.clear();
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
                                        'Reset Filter',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 32),
                          // Save button
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop({
                                    'type': widget.selectedType,
                                    'bank': widget.selectedBank,
                                    'categories': widget.selectedCategories,
                                    'title': _titleCtrl.text.trim(), // ✅
                                    'amountFrom': double.tryParse(
                                            _amountFromCtrl.text.trim()) ??
                                        0.00, // ✅
                                    'amountTo': double.tryParse(
                                            _amountToCtrl.text.trim()) ??
                                        1000000000000.00, // ✅
                                    'dateFrom': widget.selectedDateFrom,
                                    'dateTo': widget.selectedDateTo,
                                  });
                                },
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
                          ),
                        ],
                      ),
                      SizedBox(height: 300),
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
