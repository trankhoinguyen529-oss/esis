import 'package:a_management/management_child/expenditure_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/widget/widget.dart';
import 'package:a_management/management_child/expenditure_management_screen.dart';
import '../data/user_account.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isSaving = true; // true for Saving, false for Expense
  Key _budgetKey = UniqueKey();

  // Global Metrics
  double _asset = 0.0;
  double _liabilities = 0.0;
  double _netWorth = 0.0;

  bool _isLoading = true;
  double _savingWalletBalance = 0.0;
  double _expenditureWalletBalance = 0.0;
  List<UserAccountItem> _linkedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadWalletValues();
  }

  Future<void> _loadWalletValues() async {
    setState(() {
      _isLoading = true;
    });

    final liabilitiesStr = await _db.getSetting('wallet_global_liabilities') ??
        await _db.getSetting('wallet_saving_liabilities') ??
        '0.0';
    final netWorthStr = await _db.getSetting('wallet_global_net_worth') ??
        await _db.getSetting('wallet_saving_net_worth') ??
        '0.0';

    _liabilities = double.tryParse(liabilitiesStr) ?? 0.0;
    _netWorth = double.tryParse(netWorthStr) ?? 0.0;
    _asset = _netWorth + _liabilities;

    try {
      final accounts = await _db.getUserAccounts();

      UserAccountItem? savingAcc;
      UserAccountItem? expAcc;

      for (final acc in accounts) {
        if (acc.accountNumber == 'saving_${_db.currentUserId}') {
          savingAcc = acc;
        } else if (acc.accountNumber == 'expenditure_${_db.currentUserId}') {
          expAcc = acc;
        }
      }

      if (savingAcc == null) {
        final localSavingStr = await _db.getSetting('wallet_saving_balance') ?? '0.0';
        savingAcc = UserAccountItem(
          id: 'saving_${_db.currentUserId}',
          userId: _db.currentUserId,
          accountNumber: 'saving_${_db.currentUserId}',
          bankName: 'Saving',
          accountName: 'Saving Wallet',
          balance: double.tryParse(localSavingStr) ?? 0.0,
          currency: 'VND',
        );
        await _db.createUserAccount(savingAcc);
      }

      if (expAcc == null) {
        final localExpStr = await _db.getSetting('wallet_expenditure_balance') ?? '0.0';
        expAcc = UserAccountItem(
          id: 'expenditure_${_db.currentUserId}',
          userId: _db.currentUserId,
          accountNumber: 'expenditure_${_db.currentUserId}',
          bankName: 'Expenditure',
          accountName: 'Expenditure Wallet',
          balance: double.tryParse(localExpStr) ?? 0.0,
          currency: 'VND',
        );
        await _db.createUserAccount(expAcc);
      }

      _savingWalletBalance = savingAcc.balance;
      _expenditureWalletBalance = expAcc.balance;

      _linkedAccounts = accounts
          .where((acc) =>
              acc.accountNumber != 'saving_${_db.currentUserId}' &&
              acc.accountNumber != 'expenditure_${_db.currentUserId}')
          .toList();
    } catch (e) {
      debugPrint('Error loading wallet accounts from server: $e');
      final savingBalanceStr =
          await _db.getSetting('wallet_saving_balance') ?? '0.0';
      final expenditureBalanceStr =
          await _db.getSetting('wallet_expenditure_balance') ?? '0.0';

      _savingWalletBalance = double.tryParse(savingBalanceStr) ?? 0.0;
      _expenditureWalletBalance = double.tryParse(expenditureBalanceStr) ?? 0.0;
      _linkedAccounts = [];
    }

    setState(() {
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
    required VoidCallback? onTap,
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
              Visibility(
                visible: onTap != null,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetricCard(
          label: 'Asset',
          value: _asset,
          color: const Color(0xFF00C18A),
          onTap: null,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          label: 'Liabilities',
          value: _liabilities,
          color: Colors.redAccent,
          onTap: null,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          label: 'Net worth',
          value: _netWorth,
          color: Colors.blueAccent,
          onTap: () {
            _showEditDialog('Net worth', 'wallet_global_net_worth', _netWorth,
                (val) {
              setState(() {
                _netWorth = val;
                _asset = _netWorth + _liabilities;
                _updateValue('wallet_global_net_worth', _netWorth);
                _updateValue('wallet_global_asset', _asset);
              });
            });
          },
        ),
      ],
    );
  }

  Widget _buildMainWalletInfoSection() {
    final walletName = _isSaving ? 'Saving Wallet' : 'Expenditure Wallet';
    final balance =
        _isSaving ? _savingWalletBalance : _expenditureWalletBalance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                walletName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (!_isSaving)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit,
                      color: Color(0xFF00C18A), size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ExpenditureManagementScreen(),
                      ),
                    ).then((_) => _loadWalletValues());
                  },
                )
              else
                const Icon(Icons.wallet, color: Color(0xFF00C18A), size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(balance),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showEditWalletBalanceDialog,
                icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                label: const Text('Edit Balance',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C18A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditWalletBalanceDialog() {
    final type = _isSaving ? 'saving' : 'expenditure';
    final currentVal =
        _isSaving ? _savingWalletBalance : _expenditureWalletBalance;
    final controller = TextEditingController(
        text: currentVal == 0.0 ? '' : currentVal.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Edit ${_isSaving ? "Saving" : "Expenditure"} Balance',
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
                  labelText: 'Balance',
                  hintText: 'Enter balance amount',
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
              onPressed: () async {
                final newValue = double.tryParse(controller.text) ?? 0.0;
                try {
                  final acc = UserAccountItem(
                    id: '${type}_${_db.currentUserId}',
                    userId: _db.currentUserId,
                    accountNumber: '${type}_${_db.currentUserId}',
                    bankName: type == 'saving' ? 'Saving' : 'Expenditure',
                    accountName: type == 'saving' ? 'Saving Wallet' : 'Expenditure Wallet',
                    balance: newValue,
                    currency: 'VND',
                  );
                  await _db.updateUserAccount(acc);
                } catch (e) {
                  debugPrint('Error updating wallet account on server: $e');
                }
                await _db.saveSetting(
                    'wallet_${type}_balance', newValue.toString());
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadWalletValues();
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

  Widget _buildLinkedBankAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Linked Bank Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00C18A), size: 26),
              onPressed: _showLinkBankAccountDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_linkedAccounts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: Text(
                'No linked bank accounts',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _linkedAccounts.length,
            itemBuilder: (context, index) {
              final acc = _linkedAccounts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FFF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFF00C18A)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.bankName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A/C: ${acc.accountNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (acc.accountName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              acc.accountName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(acc.balance),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF00C18A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _confirmUnlinkAccount(acc),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showLinkBankAccountDialog() {
    final formKey = GlobalKey<FormState>();
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Link Bank Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g. MBBank, VCB',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      hintText: 'e.g. 0381000123456',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNameController,
                    decoration: InputDecoration(
                      labelText: 'Account Holder Name',
                      hintText: 'e.g. NGUYEN VAN A',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Initial Balance',
                      hintText: '0.0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final initialBalance = double.tryParse(balanceController.text) ?? 0.0;
                  final newAcc = UserAccountItem(
                    id: '',
                    userId: _db.currentUserId,
                    accountNumber: accountNumberController.text.trim(),
                    bankName: bankNameController.text.trim(),
                    accountName: accountNameController.text.trim(),
                    balance: initialBalance,
                    currency: 'VND',
                  );

                  try {
                    await _db.createUserAccount(newAcc);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadWalletValues();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to link account: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C18A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmUnlinkAccount(UserAccountItem acc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Unlink Account', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to unlink the bank account "${acc.bankName} - ${acc.accountNumber}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _db.deleteUserAccount(acc.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadWalletValues();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                }
              },
              child: const Text('Unlink', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMetricsRow(),
                ),
                const SizedBox(height: 16),
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
                          _buildMainWalletInfoSection(),
                          const SizedBox(height: 28),
                          _buildLinkedBankAccountsSection(),
                          const SizedBox(height: 28),
                          if (!_isSaving) ...[
                            DisplayBudget(
                              key: _budgetKey,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              onTap: (budget, spentAmount) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpenditureEditScreen(
                                      budget: budget,
                                      spentAmount: spentAmount,
                                    ),
                                  ),
                                ).then((_) => setState(() {
                                  _budgetKey = UniqueKey();
                                }));
                              },
                            ),
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
