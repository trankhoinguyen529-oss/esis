import 'package:flutter/material.dart';
import 'createaccount_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  Widget? nextPage;

  WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C18A),
      body: Column(
        children: [
          const SizedBox(height: 100),
          const Center(
            child: Text(
              'Welcome',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 70),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3FFF8),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Username Or Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF153B2C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'example@example.com',
                        filled: true,
                        fillColor: const Color(0xFFE6F8EE),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF153B2C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: const Color(0xFFE6F8EE),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF153B2C),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => MyHomePage(title:'title'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C18A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF153B2C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 56,
                    //   child: OutlinedButton(
                    //    onPressed: () {
                    //       Navigator.of(context).push(
                    //         MaterialPageRoute(
                    //           builder: (context) => CreateAccountScreen(),
                    //         ),
                    //       );
                    //     },
                    //     style: OutlinedButton.styleFrom(
                    //       backgroundColor: const Color(0xFFE7F8EE),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //       side: BorderSide.none,
                    //     ),
                    //     child: const Text(
                    //       'Sign Up',
                    //       style: TextStyle(
                    //         fontSize: 20,
                    //         fontWeight: FontWeight.w700,
                    //         color: Color(0xFF153B2C),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 24),
                    const Center(
                      // child: Text.rich(
                      //   TextSpan(
                      //     text: 'Use ',
                      //     style: TextStyle(color: Color(0xFF153B2C), fontSize: 14),
                      //     children: [
                      //       TextSpan(
                      //         text: 'Fingerprint',
                      //         style: TextStyle(color: Color(0xFF167D5F), fontWeight: FontWeight.w700),
                      //       ),
                      //       TextSpan(text: ' To Access'),
                      //     ],
                      //   ),
                      // ),
                    ),
                    const SizedBox(height: 120),
                    const Center(
                      child: Text(
                        'or sign up with',
                        style: TextStyle(
                          color: Color(0xFF3B5543),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(icon: Icons.facebook),
                        const SizedBox(width: 18),
                        _SocialButton(icon: Icons.g_mobiledata),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Color(0xFF153B2C), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateAccountScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Color(0xFF167D5F), fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // if (_usernameController.text.isNotEmpty || _passwordController.text.isNotEmpty)
                    //   Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       const SizedBox(height: 20),
                    //       const Text(
                    //         'Entered values',
                    //         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text('Username: ${_usernameController.text}'),
                    //       const SizedBox(height: 6),
                    //       Text('Password: ${_passwordController.text}'),
                    //     ],
                    //   ),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;

  const _SocialButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8EE),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF153B2C), size: 28),
    );
  }
}


