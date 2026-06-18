import 'package:flutter/material.dart';

class Createtransactionitem {
  Widget createTransactionItem(
    IconData icon,
    String title,
    String time,
    int day,
    int month,
    String tag,
    double amount, {
    bool negative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.transparent),
            child: Icon(icon, color: const Color(0xFF4DD0C1), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$time  $day/$month",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tag, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                (negative) ? '-\$$amount' : '+\$$amount',
                style: TextStyle(
                  color: negative ? Colors.blue : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
