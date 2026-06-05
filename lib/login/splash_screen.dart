import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import '../home/home_screen.dart';

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
      // Chưa đăng nhập → Login
      destination = const LoginScreen();
    } else if (_authService.isGoogleUser) {
      // Đăng nhập bằng Google → luôn verified, vào Home ngay
      destination = const Home();
    } else if (!user.emailVerified) {
      // Email/Password user chưa verify email
      destination = EmailVerificationScreen(email: user.email ?? '');
    } else {
      // Đã đăng nhập bằng email và đã verify → Home
      destination = const Home();
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
            SvgPicture.asset(
              'lib/assets/svgs/Vector.svg',
              width: 170,
              height: 170,
            ),
            const SizedBox(height: 20),
            const Text(
              'ESIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
