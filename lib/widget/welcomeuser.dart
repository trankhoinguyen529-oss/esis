import 'package:flutter/material.dart';

class Welcomeuser {
  Text welcomeUser() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    String period = 'Good Evening';
    if (hour <= 12) period = 'Good Morning';
    if (hour > 12 && hour < 18) period = 'Good Afternoon';
    return Text(
      period,
      style: TextStyle(
        color: Colors.black54,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
