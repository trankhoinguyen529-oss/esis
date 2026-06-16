import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'login/splash_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // In bảng transactions ra debug console nếu đã có user đăng nhập
  if (FirebaseAuth.instance.currentUser != null) {
    await DatabaseService().printAllTransactions();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // ✅ chỉ cho phép dọc
  ]);

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
