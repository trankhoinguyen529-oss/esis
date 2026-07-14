import 'package:flutter/material.dart';

class Pickdate {
  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);

  Future<void> PickDate({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(DateTime) ifPicked,
    bool disabled = false,
  }) async {
    if (disabled) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) ifPicked(picked);
  }
}
