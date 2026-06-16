import 'package:a_management/data/data_transaction.dart';
import 'package:a_management/services/database_service.dart';
import 'package:flutter/material.dart';

class Displaytransaction {
  //int transactionId = 0;

  /// Trả về Widget FutureBuilder hiển thị danh sách giao dịch theo kỳ.
  /// period: 0=Daily, 1=Weekly, 2=Monthly, -1=All
  Widget displayTransaction({
    required int period,
    required String type,
    required String bank,
    required Set<String> categories,
    required String title,
    required double amountFrom,
    required double amountTo,
    required DateTime dateFrom,
    required DateTime dateTo,
    required Function(int) ontap,
  }) {
    final Future<List<TransactionItem>> future;
    if (period == -1) {
      future = DatabaseService().getTransactionsByFilter(
          type: type,
          categories: categories,
          title: title,
          amountFrom: amountFrom,
          amountTo: amountTo,
          dateFrom: dateFrom,
          dateTo: dateTo,
          bank: bank);
    } else
      future = DatabaseService().getTransactionsByPeriod(period);

    return FutureBuilder<List<TransactionItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.receipt_long, size: 64, color: Color(0xFFB0C4BE)),
                SizedBox(height: 12),
                Text(
                  'No Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8FA89C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final item = transactions[index];
            //transactionId = item.id!;
            //debugPrint('******Result: $transactionId');
            return _TransactionItemWidget(
                item: item, ontap: () => ontap(item.id!));
          },
        );
      },
    );
  }
}

class _TransactionItemWidget extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback ontap;
  const _TransactionItemWidget({required this.item, required this.ontap});
  @override
  Widget stackContainer(IconData? icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Container lớn 56x56
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon,
              size: 28, color: const Color(0xFF00C18A)), // ✅ icon nhỏ lại
        ),
        // Container nhỏ góc dưới phải
        Positioned(
          bottom: -8,
          right: -8,
          child: Container(
            width: 27, // ✅ tăng lên chút để icon vừa
            height: 27,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 15, // ✅ icon nhỏ vừa với container
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    final isExpense = item.isExpense;
    final isBank = item.isBank;
    return GestureDetector(
      onTap: ontap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            (isBank)
                ? stackContainer(item.icon)
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon,
                        color: const Color(0xFF00C18A), size: 28),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.time}  ${item.date.day}/${item.date.month}/${item.date.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  isExpense
                      ? '-\$${item.amount.toStringAsFixed(2)}'
                      : '+\$${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isExpense ? Colors.blue : const Color(0xFF00C18A),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
