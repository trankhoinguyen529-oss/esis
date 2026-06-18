import 'package:flutter/material.dart';

class Calendarcompare {
  int getDayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  bool isSameWeek(int daydiff, int weekday) {
    if (daydiff < weekday && daydiff >= 0) return true;
    if (daydiff < 0 && (-1) * daydiff <= 7 - weekday) return true;
    return false;
  }
}
