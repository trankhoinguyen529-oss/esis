import 'package:flutter/material.dart';
import '../services/bank_email_sync_service.dart';
import '../data/data_transaction.dart';
import '../widget/appsnackbar.dart';

class BankEmailSyncScreen extends StatefulWidget {
  const BankEmailSyncScreen({super.key});

  @override
  State<BankEmailSyncScreen> createState() => _BankEmailSyncScreenState();
}

class _BankEmailSyncScreenState extends State<BankEmailSyncScreen> {
  final BankEmailSyncService _syncService = BankEmailSyncService();

  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSecure = true;

  final List<String> _availableBanks = [
    'Vietcombank',
    'TPBank',
    'Techcombank',
    'MB Bank',
    'ACB'
  ];
  final List<String> _enabledBanks = [];

  bool _loading = false;
  bool _testingConnection = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final config = await _syncService.getConfig();
    _hostController.text = config['host'] ?? 'imap.gmail.com';
    _portController.text = (config['port'] ?? 993).toString();
    _emailController.text = config['email'] ?? '';
    _passwordController.text = config['password'] ?? '';
    _isSecure = config['isSecure'] ?? true;

    _enabledBanks.clear();
    _enabledBanks.addAll(List<String>.from(config['enabledBanks']));
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await _syncService.saveConfig(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      isSecure: _isSecure,
      enabledBanks: _enabledBanks,
    );
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình đồng bộ email!'),
          backgroundColor: Color(0xFF00C18A),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _testingConnection = true);
    try {
      final success = await _syncService.testConnection(
        _hostController.text.trim(),
        int.parse(_portController.text.trim()),
        _emailController.text.trim(),
        _passwordController.text,
        _isSecure,
      );

      if (mounted) {
        _showStatusDialog(
          title: 'Kết nối thành công',
          content:
              'Ứng dụng đã kết nối và đăng nhập thành công vào hộp thư IMAP của bạn!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Kết nối thất bại',
          content:
              'Không thể kết nối đến máy chủ email.\nChi tiết lỗi: $e\n\n*Lưu ý: Nếu dùng Gmail, bạn cần bật Xác thực 2 bước và tạo "Mật khẩu ứng dụng" (App Password) để đăng nhập.*',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testingConnection = false);
      }
    }
  }

  Future<void> _runSync() async {
    await _saveSettings();
    setState(() => _syncing = true);

    try {
      final newTxns = await _syncService.syncEmails();
      if (mounted) {
        _showStatusDialog(
          title: 'Đồng bộ hoàn tất',
          content:
              'Đã hoàn thành đồng bộ email ngân hàng.\nTìm thấy và ghi nhận: $newTxns giao dịch mới vào cơ sở dữ liệu.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Lỗi đồng bộ',
          content: 'Đã xảy ra lỗi trong quá trình đồng bộ email.\nChi tiết: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
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
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? const Color(0xFF00C18A) : Colors.red,
              size: 30,
            ),
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
            child: const Text('Đồng ý',
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
      'TPBank - Chuyển khoản đến':
          'So tien GD: +1,200,000 VND luc 15/06/2026 18:20:10. Tai khoan GD: 0998877665. Noi dung: Anh Nguyen chuyen tien an toi share',
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
                  const Text(
                    'Giả Lập Email Ngân Hàng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kiểm tra tính năng tự động trích xuất giao dịch mà không cần thông tin thật.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Chọn ngân hàng
                  const Text('Chọn ngân hàng:',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        ['Vietcombank', 'TPBank', 'Techcombank'].map((bank) {
                      final isSelected = selectedBank == bank;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(bank),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00C18A),
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                selectedBank = bank;
                                // Auto-select matching preset
                                final matchingPreset = presets.keys.firstWhere(
                                  (k) => k.startsWith(bank),
                                  orElse: () => presets.keys.first,
                                );
                                selectedPreset = matchingPreset;
                                customBodyController.text =
                                    presets[selectedPreset]!;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Preset
                  const Text('Chọn mẫu email giao dịch:',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedPreset,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: presets.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child:
                              Text(key, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedPreset = value;
                            customBodyController.text = presets[value]!;
                            // Auto adjust bank based on template
                            if (value.startsWith('Vietcombank'))
                              selectedBank = 'Vietcombank';
                            else if (value.startsWith('TPBank'))
                              selectedBank = 'TPBank';
                            else if (value.startsWith('Techcombank'))
                              selectedBank = 'Techcombank';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Raw email body editor
                  const Text('Nội dung email thô (Raw Body):',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customBodyController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Simulate
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C18A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        _runSimulatedSync(
                            selectedBank, customBodyController.text);
                      },
                      child: const Text(
                        'Chạy Giả Lập Ghi Nhận',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
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
    setState(() => _loading = true);

    try {
      final txn = await _syncService.simulateSync(bank, rawText);
      if (txn == null) {
        if (mounted) {
          _showStatusDialog(
            title: 'Giả lập thất bại',
            content:
                'Không thể trích xuất giao dịch từ nội dung email trên. Vui lòng kiểm tra lại định dạng.',
            isSuccess: false,
          );
        }
      } else {
        if (mounted) {
          _showSimulationSuccessDialog(txn);
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Lỗi hệ thống',
          content: 'Không thể thực hiện giả lập. Lỗi: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSimulationSuccessDialog(TransactionItem txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF3FFF8),
        title: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF00C18A), size: 56),
            const SizedBox(height: 12),
            const Text(
              'Ghi nhận giao dịch thành công!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogDetailRow('Tiêu đề:', txn.title),
              const SizedBox(height: 8),
              _buildDialogDetailRow('Phân loại:', txn.category),
              const SizedBox(height: 8),
              _buildDialogDetailRow('Thời gian:',
                  '${txn.time}  ${txn.date.day}/${txn.date.month}/${txn.date.year}'),
              const SizedBox(height: 8),
              _buildDialogDetailRow(
                  'Loại GD:', txn.isExpense ? 'Chi tiêu (-)' : 'Thu nhập (+)'),
              const Divider(height: 24, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số tiền (quy đổi):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    txn.isExpense
                        ? '-\$${txn.amount.toStringAsFixed(2)}'
                        : '+\$${txn.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          txn.isExpense ? Colors.blue : const Color(0xFF00C18A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C18A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Trigger reload in screens
            },
            child: const Text('Tuyệt vời',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
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
                        color: surface,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Đồng Bộ Email Ngân Hàng',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Body container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: primary))
                    : Form(
                        key: _formKey,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Card Giới thiệu & Trạng thái nhanh
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, primary.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.mail_lock,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ghi nhận tự động thông minh',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Đồng bộ hóa các biến động số dư được gửi về email của bạn và tự động ghi chép vào sổ sách tài chính.',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: _openSimulationSheet,
                                    icon: const Icon(Icons.bolt, size: 18),
                                    label: const Text('Chạy Thử Giả Lập Ngay',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            const Text('CẤU HÌNH KẾT NỐI (IMAP)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.black54)),
                            const SizedBox(height: 12),

                            // IMAP Host & Port
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller: _hostController,
                                    label: 'Máy chủ IMAP',
                                    hint: 'imap.gmail.com',
                                    validator: (v) => v!.isEmpty
                                        ? 'Không được để trống'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller: _portController,
                                    label: 'Cổng',
                                    hint: '993',
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Lỗi' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Email Address
                            _buildTextField(
                              controller: _emailController,
                              label: 'Địa chỉ Email',
                              hint: 'example@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty || !v.contains('@')
                                  ? 'Địa chỉ email không hợp lệ'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // App Password
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Mật khẩu ứng dụng',
                              hint: '•••• •••• •••• ••••',
                              obscureText: true,
                              validator: (v) =>
                                  v!.isEmpty ? 'Không được để trống' : null,
                            ),
                            const SizedBox(height: 12),

                            // Instruction alert
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
                                      'Với tài khoản Gmail, bạn cần bật 2-Step Verification trong Tài khoản Google và tạo "Mật khẩu ứng dụng" (App Password) 16 ký tự để điền vào phần mật khẩu trên.',
                                      style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontSize: 12,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Secure Toggle
                            SwitchListTile(
                              activeColor: primary,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Kết nối bảo mật (SSL/TLS)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              value: _isSecure,
                              onChanged: (val) =>
                                  setState(() => _isSecure = val),
                            ),

                            const Divider(height: 32),

                            const Text('DANH SÁCH NGÂN HÀNG KÍCH HOẠT',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.black54)),
                            const SizedBox(height: 12),

                            // Banks checklist
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableBanks.map((bank) {
                                final isEnabled = _enabledBanks.contains(bank);
                                return FilterChip(
                                  label: Text(bank),
                                  selected: isEnabled,
                                  selectedColor: primary.withOpacity(0.2),
                                  checkmarkColor: primary,
                                  labelStyle: TextStyle(
                                    color: isEnabled ? primary : Colors.black87,
                                    fontWeight: isEnabled
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _enabledBanks.add(bank);
                                      } else {
                                        _enabledBanks.remove(bank);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 32),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    onPressed: _testingConnection
                                        ? null
                                        : _testConnection,
                                    icon: _testingConnection
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: primary))
                                        : const Icon(Icons.cable,
                                            color: primary),
                                    label: const Text('Thử Kết Nối',
                                        style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      elevation: 0,
                                    ),
                                    onPressed: _syncing ? null : _runSync,
                                    icon: _syncing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.sync,
                                            color: Colors.white),
                                    label: const Text('Đồng Bộ Ngay',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
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
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C18A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
