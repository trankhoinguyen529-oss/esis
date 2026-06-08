import 'package:a_management/data/data_transaction.dart';
import 'package:flutter/material.dart';
import 'package:a_management/widget/widget.dart';

class Displaytransaction {
  int getDayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  bool isSameWeek(int daydiff, int weekday) {
    if (daydiff < weekday && daydiff >= 0) return true;
    if (daydiff < 0 && (-1) * daydiff <= 7 - weekday) return true;
    return false;
  }

  Widget displayTransaction(int period) {
    DateTime now = DateTime.now();
    return ListView.builder(
      itemCount: TransactionData.transactions.length,
      itemBuilder: (context, index) {
        final item = TransactionData.transactions[index];
        int daydiff = getDayOfYear(now) - getDayOfYear(item.date);
        if ((period == 0 &&
                item.date.day == now.day &&
                item.date.month == now.month) ||
            (period == 2 && item.date.month == now.month) ||
            (period == 1 && isSameWeek(daydiff, now.weekday)) ||
            period == -1) {
          return Createtransactionitem().createTransactionItem(
            item.icon,
            item.title,
            item.time,
            item.date.day,
            item.date.month,
            item.tag,
            item.amount,
            negative: item.negative,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
