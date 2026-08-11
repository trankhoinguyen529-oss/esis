import 'package:flutter/material.dart';
import '../data/categorycolor.dart';
import 'package:a_management/services/database_service.dart';

/// `ScrollList` nhận dữ liệu là một `Map<String, double>` đại diện cho tên danh mục và giá trị của nó.
/// Khi build, nó vẽ ra danh sách các danh mục có thể cuộn được, theo thứ tự: hình tròn màu, tên danh mục, và giá trị số tiền.
class ScrollList extends StatelessWidget {
  final Map<String, double> categories;
  final bool isExpense;

  const ScrollList({
    super.key,
    required this.categories,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    // Sắp xếp các danh mục theo giá trị giảm dần
    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final name = entry.key;
        final value = entry.value;
        final color = CategoryColor.getColor(name);
        final sign = isExpense ? '-' : '+';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              // Icon màu (Hình tròn màu sắc đại diện)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Tên danh mục
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Giá trị số tiền
              Text(
                '$sign${formatCurrency(value)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? Colors.red[400] : const Color(0xFF00C18A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
