import 'package:a_management/services/database_service.dart';

class Calculatesummary {
  double income = 0.00;
  double expense = 0.00;
  String sIncome = '0đ';
  String sExpense = '0đ';

  /// Tải summary từ SQLite theo kỳ: 0=Daily, 1=Weekly, 2=Monthly
  Future<void> loadSummary(int period) async {
    final summary = await DatabaseService().getSummaryByPeriod(period);
    income = summary['income'] ?? 0;
    expense = summary['expense'] ?? 0;
    sIncome = formatCurrency(income);
    sExpense = formatCurrency(expense);
  }
}
