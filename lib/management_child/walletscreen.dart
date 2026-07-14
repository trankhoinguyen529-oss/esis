import 'package:flutter/material.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/widget/widget.dart';
import 'package:a_management/assets/icon/categoryIcon.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isSaving = true; // true for Saving, false for Expense

  // Values for Saving
  double _savingAsset = 0.0;
  double _savingLiabilities = 0.0;
  double _savingNetWorth = 0.0;

  // Values for Expense
  double _expenseAsset = 0.0;
  double _expenseLiabilities = 0.0;
  double _expenseNetWorth = 0.0;

  bool _isLoading = true;
  final List<Map<String, dynamic>> _expenditureItems = [];

  @override
  void initState() {
    super.initState();
    _loadWalletValues();
  }

  Future<void> _loadWalletValues() async {
    setState(() {
      _isLoading = true;
    });

    final savingAssetStr = await _db.getSetting('wallet_saving_asset') ?? '0.0';
    final savingLiabilitiesStr =
        await _db.getSetting('wallet_saving_liabilities') ?? '0.0';
    final savingNetWorthStr =
        await _db.getSetting('wallet_saving_net_worth') ?? '0.0';

    final expenseAssetStr =
        await _db.getSetting('wallet_expense_asset') ?? '0.0';
    final expenseLiabilitiesStr =
        await _db.getSetting('wallet_expense_liabilities') ?? '0.0';
    final expenseNetWorthStr =
        await _db.getSetting('wallet_expense_net_worth') ?? '0.0';

    setState(() {
      _savingAsset = double.tryParse(savingAssetStr) ?? 0.0;
      _savingLiabilities = double.tryParse(savingLiabilitiesStr) ?? 0.0;
      _savingNetWorth = double.tryParse(savingNetWorthStr) ?? 0.0;

      _expenseAsset = double.tryParse(expenseAssetStr) ?? 0.0;
      _expenseLiabilities = double.tryParse(expenseLiabilitiesStr) ?? 0.0;
      _expenseNetWorth = double.tryParse(expenseNetWorthStr) ?? 0.0;

      _isLoading = false;
    });
  }

  Future<void> _updateValue(String key, double value) async {
    await _db.saveSetting(key, value.toString());
  }

  void _showEditDialog(String title, String key, double currentValue,
      Function(double) onUpdated) {
    final controller = TextEditingController(
        text: currentValue == 0.0 ? '' : currentValue.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Edit $title',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFF00C18A), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? 0.0;
                onUpdated(newValue);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C18A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double val) {
    if (val == val.toInt()) {
      return '\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '\$${val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _buildToggleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _isSaving ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isSaving = true;
                    });
                  },
                  child: Center(
                    child: Text(
                      'Saving',
                      style: TextStyle(
                        color:
                            _isSaving ? const Color(0xFF00C18A) : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isSaving = false;
                    });
                  },
                  child: Center(
                    child: Text(
                      'Expenditure',
                      style: TextStyle(
                        color:
                            !_isSaving ? const Color(0xFF00C18A) : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required double value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 10, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final currentAsset = _isSaving ? _savingAsset : _expenseAsset;
    final currentLiabilities =
        _isSaving ? _savingLiabilities : _expenseLiabilities;
    final currentNetWorth = _isSaving ? _savingNetWorth : _expenseNetWorth;

    return Row(
      children: [
        _buildMetricCard(
          label: 'Asset',
          value: currentAsset,
          color: const Color(0xFF00C18A),
          onTap: () {
            final prefix = _isSaving ? 'wallet_saving' : 'wallet_expense';
            _showEditDialog('Asset', '${prefix}_asset', currentAsset, (val) {
              setState(() {
                if (_isSaving) {
                  _savingAsset = val;
                  _savingNetWorth = _savingAsset - _savingLiabilities;
                  _updateValue('wallet_saving_asset', _savingAsset);
                  _updateValue('wallet_saving_net_worth', _savingNetWorth);
                } else {
                  _expenseAsset = val;
                  _expenseNetWorth = _expenseAsset - _expenseLiabilities;
                  _updateValue('wallet_expense_asset', _expenseAsset);
                  _updateValue('wallet_expense_net_worth', _expenseNetWorth);
                }
              });
            });
          },
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          label: 'Liabilities',
          value: currentLiabilities,
          color: Colors.redAccent,
          onTap: () {
            final prefix = _isSaving ? 'wallet_saving' : 'wallet_expense';
            _showEditDialog(
                'Liabilities', '${prefix}_liabilities', currentLiabilities,
                (val) {
              setState(() {
                if (_isSaving) {
                  _savingLiabilities = val;
                  _savingNetWorth = _savingAsset - _savingLiabilities;
                  _updateValue('wallet_saving_liabilities', _savingLiabilities);
                  _updateValue('wallet_saving_net_worth', _savingNetWorth);
                } else {
                  _expenseLiabilities = val;
                  _expenseNetWorth = _expenseAsset - _expenseLiabilities;
                  _updateValue(
                      'wallet_expense_liabilities', _expenseLiabilities);
                  _updateValue('wallet_expense_net_worth', _expenseNetWorth);
                }
              });
            });
          },
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          label: 'Net worth',
          value: currentNetWorth,
          color: Colors.blueAccent,
          onTap: () {
            final prefix = _isSaving ? 'wallet_saving' : 'wallet_expense';
            _showEditDialog('Net worth', '${prefix}_net_worth', currentNetWorth,
                (val) {
              setState(() {
                if (_isSaving) {
                  _savingNetWorth = val;
                  _updateValue('wallet_saving_net_worth', _savingNetWorth);
                } else {
                  _expenseNetWorth = val;
                  _updateValue('wallet_expense_net_worth', _expenseNetWorth);
                }
              });
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddExpenditureBar() {
    return GestureDetector(
      onTap: () async {
        final result = await showCustomBottomSheet(
          context: context,
          iconList: CategoryIcon.categoryIcons,
        );
        if (result != null) {
          final title = result['title'] as String?;
          final icon = result['icon'] as IconData?;
          if (title != null && title.isNotEmpty && icon != null) {
            setState(() {
              _expenditureItems.add({
                'title': title,
                'icon': icon,
              });
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF00C18A), size: 24),
            const SizedBox(width: 12),
            const Text(
              'add expenditure item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditExpenditureBar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.settings, color: Colors.blueAccent, size: 24),
                SizedBox(width: 12),
                Text(
                  'edit expenditure',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Wallet',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                _buildToggleBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricsRow(),
                          const SizedBox(height: 28),
                          if (!_isSaving) ...[
                            _buildAddExpenditureBar(),
                            const SizedBox(height: 12),
                            _buildEditExpenditureBar(),
                            const SizedBox(height: 20),
                            ..._expenditureItems.map((item) {
                              return Displayexpenditure().displayExpenditure(
                                item['icon'] as IconData,
                                item['title'] as String,
                              );
                            }).toList(),
                          ],
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
