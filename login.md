# Firebase Authentication – Hướng dẫn tích hợp

## Flow

```
Register (createUserWithEmailAndPassword)
    ↓
Email Verification (sendEmailVerification)
    ↓
Login (signInWithEmailAndPassword) – chỉ cho phép nếu email đã verified
    ↓
Home Screen
```

---

## 1. Setup Firebase

### 1.1 Dependencies – `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^3.13.0
  firebase_auth: ^5.6.0
```

### 1.2 Android – `android/settings.gradle.kts`

Thêm Google Services plugin:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false  // THÊM DÒNG NÀY
}
```

### 1.3 Android – `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // THÊM DÒNG NÀY
    id("dev.flutter.flutter-gradle-plugin")
}
```

### 1.4 FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
curl -sL https://firebase.tools | bash
firebase login
flutterfire configure
# → Chọn Firebase project → chọn platforms → tự tạo firebase_options.dart
```

### 1.5 Firebase Console

Vào Firebase Console → Authentication → Get started → Bật **Email/Password**

---

## 2. `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C18A)),
      ),
      home: const SplashScreen(),
    );
  }
}
```

---

## 3. `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser!.emailVerified;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

---

## 4. `lib/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _navigateBasedOnAuthState();
    });
  }

  Future<void> _navigateBasedOnAuthState() async {
    final user = _authService.currentUser;
    Widget destination;

    if (user == null) {
      destination = const LoginScreen();
    } else if (!user.emailVerified) {
      destination = EmailVerificationScreen(email: user.email ?? '');
    } else {
      destination = const MyHomePage(title: 'ESIS Home');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00D09E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('lib/assets/svgs/Vector.svg', width: 170, height: 170),
            const SizedBox(height: 20),
            const Text('ESIS',
              style: TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
```
---

## 5. `lib/createaccount_screen.dart` (Register + Firebase)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'email_verification_screen.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate form trước khi đăng ký
  String? _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty) return 'Vui lòng nhập họ tên';
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    if (password != confirmPassword) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  /// Xử lý đăng ký với Firebase
  Future<void> _handleSignUp() async {
    final error = _validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
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
          message = 'Email này đã được sử dụng';
          break;
        case 'weak-password':
          message = 'Mật khẩu quá yếu';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Đã xảy ra lỗi: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C18A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C18A),
        automaticallyImplyLeading: true,
        title: const Text('Create Account',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(),
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
                    _buildInput(controller: _nameController, hintText: 'Nguyễn Văn A', keyboardType: TextInputType.name),
                    const SizedBox(height: 20),
                    _buildLabel('Email '),
                    const SizedBox(height: 12),
                    _buildInput(controller: _emailController, hintText: 'example@example.com', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildLabel('Mobile Number '),
                    const SizedBox(height: 12),
                    _buildInput(controller: _mobileController, hintText: '+ 123 456 789', keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    _buildLabel('Date Of Birth '),
                    const SizedBox(height: 12),
                    _buildInput(controller: _dobController, hintText: 'DD / MM / YYYY', keyboardType: TextInputType.datetime),
                    const SizedBox(height: 20),
                    _buildLabel('Password '),
                    const SizedBox(height: 12),
                    _buildPasswordInput(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Confirm Password '),
                    const SizedBox(height: 12),
                    _buildPasswordInput(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 24),
                    // Terms of Service text...
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C18A),
                          disabledBackgroundColor: const Color(0xFF00C18A).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Sign Up',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Log In',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF167D5F))),
                      ),
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
    return Row(children: [
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF153B2C))),
      const Text('*', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.red)),
    ]);
  }

  Widget _buildInput({required TextEditingController controller, required String hintText, required TextInputType keyboardType}) {
    return TextField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText, filled: true, fillColor: const Color(0xFFE6F8EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPasswordInput({required TextEditingController controller, required bool obscureText, required VoidCallback onToggle}) {
    return TextField(
      controller: controller, obscureText: obscureText,
      decoration: InputDecoration(
        hintText: 'Enter your password', filled: true, fillColor: const Color(0xFFE6F8EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF153B2C)),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}
```

---

## 6. `lib/email_verification_screen.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'welcome_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});
  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() { _cooldownTimer?.cancel(); super.dispose(); }

  void _startCooldown() {
    setState(() { _canResend = false; _resendCooldown = 60; });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() { _resendCooldown--; if (_resendCooldown <= 0) { _canResend = true; timer.cancel(); } });
    });
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    try {
      await _authService.sendEmailVerification();
      _startCooldown();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email xác thực đã được gửi lại!'), backgroundColor: Color(0xFF00C18A)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      final verified = await _authService.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        await _authService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email đã xác thực! Vui lòng đăng nhập.'), backgroundColor: Color(0xFF00C18A)));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email chưa xác thực. Kiểm tra hộp thư.'), backgroundColor: Colors.orange));
      }
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  // UI: Hiển thị email, nút "Tôi đã xác thực Email", nút "Gửi lại Email" (cooldown 60s)
  // và "Quay lại Đăng nhập"
}
```

---

## 7. `lib/welcome_screen.dart` (Login + Firebase)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'createaccount_screen.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';

// Trong _WelcomeScreenState:
final AuthService _authService = AuthService();
bool _isLoading = false;

Future<void> _handleLogin() async {
  final email = _usernameController.text.trim();
  final password = _passwordController.text;
  if (email.isEmpty || password.isEmpty) { /* show error */ return; }

  setState(() => _isLoading = true);
  try {
    await _authService.signInWithEmail(email, password);
    final verified = await _authService.isEmailVerified();
    if (!mounted) return;

    if (verified) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyHomePage(title: 'ESIS Home')), (route) => false);
    } else {
      _showEmailNotVerifiedDialog(email);
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    String message;
    switch (e.code) {
      case 'user-not-found': message = 'Không tìm thấy tài khoản'; break;
      case 'wrong-password': message = 'Mật khẩu không đúng'; break;
      case 'invalid-credential': message = 'Email hoặc mật khẩu không đúng'; break;
      default: message = 'Lỗi: ${e.message}';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  } finally { if (mounted) setState(() => _isLoading = false); }
}

void _showEmailNotVerifiedDialog(String email) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Row(children: [
      Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('Email chưa xác thực')]),
    content: const Text('Bạn cần xác thực email trước khi đăng nhập.'),
    actions: [
      TextButton(onPressed: () { Navigator.of(ctx).pop(); _authService.signOut(); }, child: const Text('Đóng')),
      ElevatedButton(onPressed: () {
        Navigator.of(ctx).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email)));
      }, child: const Text('Xác thực')),
    ],
  ));
}
```

---

## 8. `lib/home_screen.dart` (Logout)

```dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AuthService _authService = AuthService();

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Đăng xuất', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
      ]),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (user != null) ...[
          Text('Xin chào, ${user.displayName ?? user.email ?? "User"}!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(user.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ])),
    );
  }
}
```

---

## Cấu trúc thư mục

```
lib/
├── main.dart                        (Firebase init)
├── firebase_options.dart            (auto-generated by flutterfire configure)
├── services/
│   └── auth_service.dart            (Firebase Auth wrapper)
├── splash_screen.dart               (auth state check)
├── login_screen.dart                (landing page - không thay đổi)
├── welcome_screen.dart              (login form + Firebase)
├── createaccount_screen.dart        (register form + Firebase)
├── email_verification_screen.dart   (verify email)
└── home_screen.dart                 (logout)
```

---

## 9. Google Sign-In

### 9.1 Dependencies – `pubspec.yaml`

```yaml
dependencies:
  google_sign_in: ^6.2.2
```

### 9.2 Firebase Console

Vào Firebase Console → Authentication → Sign-in method → Bật **Google**

### 9.3 iOS – `ios/Runner/Info.plist`

Lấy `REVERSED_CLIENT_ID` từ file `ios/Runner/GoogleService-Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 9.4 `lib/services/auth_service.dart`

```dart
import 'package:google_sign_in/google_sign_in.dart';

// Trong class AuthService:
final GoogleSignIn _googleSignIn = GoogleSignIn();

/// Kiểm tra user hiện tại đăng nhập bằng Google không
bool get isGoogleUser {
  final user = _auth.currentUser;
  if (user == null) return false;
  return user.providerData.any((info) => info.providerId == 'google.com');
}

/// Đăng nhập bằng Google (không cần verify email)
Future<UserCredential?> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null; // user huỷ

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return await _auth.signInWithCredential(credential);
}

/// Đăng xuất (Firebase + Google session)
Future<void> signOut() async {
  await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
}
```

### 9.5 Flow Google Sign-In

```
Nhấn "Continue with Google"
    ↓
GoogleSignIn().signIn() – hiện Google account picker
    ↓
Lấy idToken + accessToken
    ↓
Firebase signInWithCredential(GoogleAuthProvider.credential(...))
    ↓
Home Screen (không cần verify email – Google đã verify)
```
