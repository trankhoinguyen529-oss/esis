import 'package:flutter/material.dart';
import '../services/bank_email_sync_service.dart';

class BankEmailSyncScreen extends StatefulWidget {
  const BankEmailSyncScreen({super.key});

  @override
  State<BankEmailSyncScreen> createState() => _BankEmailSyncScreenState();
}

class _BankEmailSyncScreenState extends State<BankEmailSyncScreen> {
  final BankEmailSyncService _syncService = BankEmailSyncService();
  List<EmailAccount> _accounts = [];

  bool _loading = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    _accounts = await _syncService.getAccounts();
    setState(() => _loading = false);
  }

  Future<void> _deleteAccount(EmailAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete bank account "${account.bankName} - ${account.accountNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await _syncService.deleteAccountFromServer(account.id);
        _accounts = await _syncService.getAccounts();
      } catch (e) {
        debugPrint('Error deleting account: $e');
      } finally {
        setState(() => _loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted bank account successfully!'),
            backgroundColor: Color(0xFF00C18A),
          ),
        );
      }
    }
  }

  void _openAccountSheet({EmailAccount? account}) {
    final isEdit = account != null;
    final formKey = GlobalKey<FormState>();
    final bankNameController = TextEditingController(text: account?.bankName ?? '');
    final accountNumberController =
        TextEditingController(text: account?.accountNumber ?? '');
    bool testing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF3FFF8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Bank Account' : 'Add Bank Account',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: bankNameController,
                      label: 'Bank Name',
                      hint: 'e.g. MBBank, Vietcombank',
                      validator: (v) =>
                          v!.isEmpty ? 'Cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: accountNumberController,
                      label: 'Account Number',
                      hint: 'e.g. 0381000123456',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'Cannot be empty' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF00C18A), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: testing
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setModalState(() => testing = true);
                                    try {
                                      await _syncService.testConnection(
                                        bankNameController.text.trim(),
                                        accountNumberController.text.trim(),
                                      );
                                      if (context.mounted) {
                                        _showStatusDialog(
                                          title: 'Connection successful',
                                          content:
                                              'Connected to bank sync endpoint successfully!',
                                          isSuccess: true,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        _showStatusDialog(
                                          title: 'Connection failed',
                                          content: 'Error: $e',
                                          isSuccess: false,
                                        );
                                      }
                                    } finally {
                                      setModalState(() => testing = false);
                                    }
                                  },
                            icon: testing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00C18A)))
                                : const Icon(Icons.cable,
                                    color: Color(0xFF00C18A)),
                            label: const Text('Test Connection',
                                style: TextStyle(
                                    color: Color(0xFF00C18A),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C18A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final newAccount = EmailAccount(
                                id: account?.id ??
                                    DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                bankName: bankNameController.text.trim(),
                                accountNumber: accountNumberController.text.trim(),
                              );

                              try {
                                await _syncService.saveAccountToServer(newAccount);
                                final refreshed = await _syncService.getAccounts();
                                if (mounted) {
                                  setState(() {
                                    _accounts = refreshed;
                                  });
                                }
                              } catch (e) {
                                debugPrint('Error saving account: $e');
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit
                                        ? 'Updated bank account successfully!'
                                        : 'Added new bank account successfully!'),
                                    backgroundColor: const Color(0xFF00C18A),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('Save configuration',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runSync() async {
    if (_accounts.isEmpty) {
      _showStatusDialog(
        title: 'Need Setup',
        content: 'Please add at least one bank account before syncing.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final newTxns = await _syncService.syncEmails();
      if (mounted) {
        _showStatusDialog(
          title: 'Sync Completed',
          content:
              'Bank transactions sync completed.\nFound and recorded: $newTxns new transactions.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Sync Failed',
          content: 'An error occurred during bank transactions sync.\nDetails: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showStatusDialog(
      {required String title,
      required String content,
      required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? const Color(0xFF00C18A) : Colors.red,
                size: 30),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
        content:
            Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF00C18A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: surface, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black87)),
                  ),
                  const Expanded(
                      child: Center(
                          child: Text('Bank Account Sync',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(36))),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: primary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('BANK ACCOUNT LIST',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Colors.black54)),
                                    IconButton(
                                        icon: const Icon(Icons.add_circle,
                                            color: primary, size: 28),
                                        onPressed: () => _openAccountSheet()),
                                  ],
                                ),
                                if (_accounts.isEmpty)
                                  Container(
                                      padding: const EdgeInsets.all(32),
                                      alignment: Alignment.center,
                                      child: const Text(
                                          'No bank accounts configured'))
                                else
                                  ..._accounts.map((account) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.black12)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.account_balance,
                                              color: primary),
                                          const SizedBox(width: 14),
                                          Expanded(
                                              child: Text("${account.bankName} - ${account.accountNumber}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
                                          IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue, size: 20),
                                              onPressed: () =>
                                                  _openAccountSheet(
                                                      account: account)),
                                          IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              onPressed: () =>
                                                  _deleteAccount(account)),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                onPressed: _syncing ? null : _runSync,
                                icon: _syncing
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Icon(Icons.sync,
                                        color: Colors.white),
                                label: const Text('Sync Now',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00C18A), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
