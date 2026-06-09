import 'package:flutter/material.dart';

class ShowDialog {
  void showLogoutDialog(
    BuildContext context,
    String title,
    String subtitle,
    Function() ontapNo,
    Function() ontapYes,
    Function()? onConfirmed,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0), // ✅ khoảng cách với màn hình → nhỏ = dialog to hơn
        contentPadding: const EdgeInsets.fromLTRB(30, 16, 30, 8), //
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false); // ✅ đóng dialog
              ontapNo();
            },
            child: const Text('No',
                style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true); // ✅ đóng dialog, trả true
              ontapYes();
            },
            child: const Text(
              'Yes',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirmed?.call(); // ✅ gọi đúng cách
    }
  }
}
