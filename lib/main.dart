import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(
        // nextPage: LoginScreen(
        //   nextPage: WelcomeScreen(
        //     nextPage: const MyHomePage(title: 'Hello, World!'),
        //   ),
        // ),
      ),
    );
  }
}
