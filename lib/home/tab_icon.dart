import 'package:flutter/material.dart';

class TabIcon extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onHome;
  final VoidCallback? onAnalytics;
  final VoidCallback? onTransaction;
  final VoidCallback? onManagement;
  final VoidCallback? onProfile;

  const TabIcon({
    super.key,
    required this.selectedIndex,
    this.onHome,
    this.onAnalytics,
    this.onTransaction,
    this.onManagement,
    this.onProfile,
  });

  static const primary = Color(0xFF00C18A);

  @override
  Widget build(BuildContext context) {
    Widget buildIcon(
        int index, IconData icon, VoidCallback? onPressed, String title) {
      final selected = selectedIndex == index;
      if (selected) {
        return tabTooltip(title, icon, onPressed);
      }

      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 32),
      );
    }

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildIcon(0, Icons.home, onHome, 'Home'),
            //buildIcon(1, Icons.bar_chart, onAnalytics),
            buildIcon(2, Icons.compare_arrows, onTransaction, 'Transactions'),
            buildIcon(3, Icons.layers, onManagement, 'Management'),
            buildIcon(4, Icons.person, onProfile, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget tabTooltip(String title, IconData icon, VoidCallback? onPressed) {
    return Tooltip(
      message: title, // nội dung hiện ra
      preferBelow: false, // hiện phía trên
      decoration: BoxDecoration(
        color: Colors.white, // màu nền tooltip
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20,
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primary, size: 32),
        ),
      ),
    );
  }
}
