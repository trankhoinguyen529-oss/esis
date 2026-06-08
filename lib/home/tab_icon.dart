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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);

    Widget buildIcon(int index, IconData icon, VoidCallback? onPressed) {
      final selected = selectedIndex == index;
      if (selected) {
        return GestureDetector(
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
        );
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
            buildIcon(0, Icons.home, onHome),
            //buildIcon(1, Icons.bar_chart, onAnalytics),
            buildIcon(2, Icons.compare_arrows, onTransaction),
            buildIcon(3, Icons.layers, onManagement),
            buildIcon(4, Icons.person, onProfile),
          ],
        ),
      ),
    );
  }
}
