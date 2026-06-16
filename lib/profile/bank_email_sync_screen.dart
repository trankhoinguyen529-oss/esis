import 'package:flutter/material.dart';
import '../services/bank_email_sync_service.dart';
import '../data/data_transaction.dart';

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
            'Are you sure you want to delete this email account "${account.email}"?'),
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
      setState(() {
        _accounts.removeWhere((a) => a.id == account.id);
      });
      await _syncService.saveAccounts(_accounts);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delete email account successfully!'),
            backgroundColor: Color(0xFF00C18A),
          ),
        );
      }
    }
  }

  void _openAccountSheet({EmailAccount? account}) {
    final isEdit = account != null;
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: account?.email ?? '');
    final passwordController =
        TextEditingController(text: account?.password ?? '');
    final hostController =
        TextEditingController(text: account?.host ?? 'imap.gmail.com');
    final portController =
        TextEditingController(text: account?.port.toString() ?? '993');
    bool isSecure = account?.isSecure ?? true;
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
                      isEdit ? 'Edit Email Account' : 'Add Email Account',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: hostController,
                            label: 'IMAP Server',
                            hint: 'imap.gmail.com',
                            validator: (v) =>
                                v!.isEmpty ? 'Cannot be empty' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: portController,
                            label: 'Port',
                            hint: '993',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Error' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: emailController,
                      label: 'Email Address',
                      hint: 'example@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? 'Invalid email address'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: passwordController,
                      label: 'App Password',
                      hint: '•••• •••• •••• ••••',
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Cannot be empty' : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'For Gmail accounts, you need to enable 2-Step Verification in your Google Account and create a 16-character "App Password" to fill in the password field above.',
                              style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      activeColor: const Color(0xFF00C18A),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Secure connection (SSL/TLS)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      value: isSecure,
                      onChanged: (val) => setModalState(() => isSecure = val),
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
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setModalState(() => testing = true);
                                    try {
                                      await _syncService.testConnection(
                                        hostController.text.trim(),
                                        int.parse(portController.text.trim()),
                                        emailController.text.trim(),
                                        passwordController.text,
                                        isSecure,
                                      );
                                      if (context.mounted) {
                                        _showStatusDialog(
                                          title: 'Connection successful',
                                          content:
                                              'Connected to email successfully!',
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
                                email: emailController.text.trim(),
                                password: passwordController.text,
                                host: hostController.text.trim(),
                                port: int.parse(portController.text.trim()),
                                isSecure: isSecure,
                              );

                              setState(() {
                                if (isEdit) {
                                  final idx = _accounts
                                      .indexWhere((a) => a.id == account.id);
                                  if (idx != -1) {
                                    _accounts[idx] = newAccount;
                                  }
                                } else {
                                  _accounts.add(newAccount);
                                }
                              });

                              await _syncService.saveAccounts(_accounts);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit
                                        ? 'Updated email account successfully!'
                                        : 'Added new email account successfully!'),
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
        content: 'Please add at least one email account before syncing.',
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
              'Bank email sync completed.\nFound and recorded: $newTxns new transactions.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Sync Failed',
          content: 'An error occurred during email sync.\nDetails: $e',
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

  void _openSimulationSheet() {
    String selectedBank = 'Vietcombank';
    String selectedPreset = 'Vietcombank - Nhận lương';
    final customBodyController = TextEditingController();

    final presets = {
      'Vietcombank - Nhận lương':
          'VCB Digibank: Tai khoan 1012345678 thay doi +15,000,000 VND vao luc 15/06/2026 08:30:00. ND: Cong ty Tra luong thang 06',
      'Vietcombank - Mua sắm Shopee':
          'VCB Digibank: Tai khoan 1012345678 thay doi -250,000 VND vao luc 15/06/2026 12:15:30. ND: Thanh toan don hang Shopee 23412356',
      'TPBank - Ăn sáng Cafe':
          'So tien GD: -65,000 VND luc 15/06/2026 07:45:00. Tai khoan GD: 0998877665. Noi dung: Thanh toan an sang cafe Highlands',
      'Techcombank - Thanh toán điện nước':
          'Giao dich Techcombank: TK 190876543210 -350,000 VND luc 15/06/2026 14:00:25. ND: Thanh toan tien dien sinh hoat thang 05',
    };

    customBodyController.text = presets[selectedPreset]!;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SizedBox(width: 50, height: 5)),
                  const Text('Simulate Bank Email',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                      'Test the automatic transaction extraction feature without needing real information.',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  const Text('Chọn mẫu Email có sẵn:',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12)),
                    child: DropdownButton<String>(
                      value: selectedPreset,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: presets.keys.map((presetName) {
                        return DropdownMenuItem<String>(
                          value: presetName,
                          child: Text(presetName,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedPreset = value;
                            customBodyController.text = presets[value]!;
                            selectedBank = value.split(' - ')[0];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: customBodyController, maxLines: 4),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C18A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      onPressed: () {
                        Navigator.pop(context);
                        _runSimulatedSync(
                            selectedBank, customBodyController.text);
                      },
                      child: const Text('Run Simulated Record',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runSimulatedSync(String bank, String rawText) async {
    try {
      final txn = await _syncService.simulateSync(bank, rawText);
      if (txn != null && mounted) _showSimulationSuccessDialog(txn);
    } catch (e) {
      if (mounted)
        _showStatusDialog(
            title: 'System Error', content: 'Error: $e', isSuccess: false);
    }
  }

  void _showSimulationSuccessDialog(TransactionItem txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text('Successfully recorded: ${txn.title} - ${txn.amount}'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
                          child: Text('Bank Email Sync',
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        primary,
                                        primary.withAlpha(204)
                                      ]),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(children: [
                                        Icon(Icons.mail_lock,
                                            color: Colors.white, size: 24),
                                        SizedBox(width: 8),
                                        Text('Automatic Recording',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold))
                                      ]),
                                      const SizedBox(height: 8),
                                      const Text(
                                          'Sync balance changes sent to your email.',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: primary),
                                          onPressed: _openSimulationSheet,
                                          icon:
                                              const Icon(Icons.bolt, size: 18),
                                          label: const Text('Run Test')),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('EMAIL ACCOUNT LIST',
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
                                          'No email accounts configured'))
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
                                          const Icon(Icons.email,
                                              color: primary),
                                          const SizedBox(width: 14),
                                          Expanded(
                                              child: Text(account.email,
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
