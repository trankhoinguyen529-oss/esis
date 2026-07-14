import 'package:flutter/material.dart';

class Appsnackbar {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void error_snackbar(BuildContext context, String message) {
    showError(context, message);
  }

  static void success_snackbar(BuildContext context, String message) {
    showSuccess(context, message);
  }
}
