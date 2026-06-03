import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  //final Widget nextPage;

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00D09E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
                  'lib/assets/svgs/Vector.svg',
                  width : 170,
                  height: 170,
                  
                ),
            SizedBox(height: 20),
            Text(
              'ESIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w700,
              ),
            ),
            // SizedBox(height: 180),
            // Text(
            //   '   Loading...',
            //   style: TextStyle(
            //     color: Colors.white70,
            //     fontSize: 24,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
