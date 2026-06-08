import 'package:flutter/material.dart';
import 'widget.dart';
import 'package:a_management/data/data_transaction.dart';

class Calculatesummary {
  double income = 0.00;
  double expense = 0.00;
  String sIncome = '';
  String sExpense = '';
  //int selectedPeriod = 1;

  void calculateSummary(int selectedperiod) {
    income = 0;
    expense = 0;

    DateTime now = DateTime.now();

    for (final item in TransactionData.transactions) {
      bool match = false;

      if (selectedperiod == 0) {
        match = item.date.day == now.day && item.date.month == now.month;
      } else if (selectedperiod == 1) {
        int daydiff = Calendarcompare().getDayOfYear(now) -
            Calendarcompare().getDayOfYear(item.date);

        match = Calendarcompare().isSameWeek(daydiff, now.weekday);
      } else {
        match = item.date.month == now.month;
      }

      if (match) {
        if (item.negative) {
          expense += item.amount;
        } else {
          income += item.amount;
        }
      }
    }

    this.sIncome = '\$${this.income.toStringAsFixed(2)}';
    this.sExpense = '\$${this.expense.toStringAsFixed(2)}';
  }
}
