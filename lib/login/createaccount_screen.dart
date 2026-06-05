import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'email_verification_screen.dart';
import 'welcome_screen.dart';
import '../widget/widget.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _nameError = false;
  bool _emailError = false;
  bool _mobileError = false;
  bool _dobError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;
  bool _passwordMismatch = false;
  bool _passwordHasUpper = false;
  bool _passwordHasNumber = false;
  bool _passwordHasLength = false;
  bool _passwordHasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Validate form trước khi đăng ký
  bool _validateForm() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty;
      _emailError = _emailController.text.trim().isEmpty;
      _mobileError = _mobileController.text.trim().isEmpty;
      _dobError = _dobController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
      _passwordMismatch = !_passwordError &&
          !_confirmPasswordError &&
          _passwordController.text != _confirmPasswordController.text;
    });

    return !_nameError &&
        !_emailError &&
        !_mobileError &&
        !_dobError &&
        !_passwordError &&
        !_confirmPasswordError;
  }

  /// Xử lý đăng ký với Firebase
  Future<void> _handleSignUp() async {
    if (!_validateForm()) {
      Appsnackbar.error_snackbar(context, 'All forms must be filled');
      return;
    }

    // Kiểm tra email hợp lệ
    final email = _emailController.text.trim();
    // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    //   Appsnackbar.showError(context, 'Email is invalid');
    //   return;
    // }

    // Kiểm tra mật khẩu đủ mạnh
    if (!_passwordHasUpper ||
        !_passwordHasNumber ||
        !_passwordHasLength ||
        !_passwordHasSpecial) {
      Appsnackbar.showError(context, 'Password does not meet the requirements');
      return;
    }
    if (_passwordMismatch && !_confirmPasswordError) {
      Appsnackbar.showError(context, 'Password must match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text;

      // 1. Đăng ký tài khoản
      final credential = await _authService.registerWithEmail(email, password);

      // 2. Cập nhật displayName
      await credential.user?.updateDisplayName(_nameController.text.trim());

      // 3. Gửi email xác thực
      await _authService.sendEmailVerification();

      if (!mounted) return;

      // 4. Navigate đến Email Verification Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(email: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email is already used';
          break;
        case 'invalid-email':
          message = 'Email is invalid';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      Appsnackbar.showError(context, message);
    } catch (e) {
      if (!mounted) return;
      Appsnackbar.showError(context, 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C18A),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3FFF8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildLabel('Full Name '),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _nameController,
                      hintText: 'Enter your full name',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email '),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Mobile Number '),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _mobileController,
                      hintText: '+ 123 456 789',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Date Of Birth '),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _dobController,
                      hintText: 'DD / MM / YYYY',
                      keyboardType: TextInputType.datetime,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Password '),
                    const SizedBox(height: 12),
                    _buildPasswordInput(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onChanged: (value) {
                        setState(() {
                          _passwordHasUpper = value.contains(RegExp(r'[A-Z]'));
                          _passwordHasNumber = value.contains(RegExp(r'[0-9]'));
                          _passwordHasLength = value.length >= 8;
                          _passwordHasSpecial = value
                              .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>~-]'));
                        });
                      },
                    ),
                    if (_passwordFocusNode.hasFocus ||
                        _passwordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordRule(
                              isValid: _passwordHasUpper,
                              label: 'Password must contain a capital letter',
                            ),
                            _buildPasswordRule(
                              isValid: _passwordHasNumber,
                              label: 'Password must contain a number',
                            ),
                            _buildPasswordRule(
                              isValid: _passwordHasLength,
                              label:
                                  'Password must contain more than 8 characters',
                            ),
                            _buildPasswordRule(
                              isValid: _passwordHasSpecial,
                              label:
                                  'Password must contain a special character',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildLabel('Confirm Password '),
                    const SizedBox(height: 12),
                    _buildPasswordInput(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'By continuing, you agree to ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4D5E49),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Terms of Service ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'and ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4D5E49),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C18A),
                          disabledBackgroundColor:
                              const Color(0xFF00C18A).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?  ',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => WelcomeScreen(),
                            ),
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF167D5F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF153B2C),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFE6F8EE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required bool obscureText,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFE6F8EE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF153B2C),
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordRule({required bool isValid, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: isValid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF153B2C), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final initial = today.subtract(const Duration(days: 365 * 20));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C18A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF153B2C),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00C18A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.day.toString().padLeft(2, '0')} / '
          '${picked.month.toString().padLeft(2, '0')} / '
          '${picked.year}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }
}
