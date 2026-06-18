import 'package:a_management/management/bankdetailscreen.dart';
import 'package:a_management/widget/icon_map.dart';
import 'package:a_management/management/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:a_management/widget/widget.dart';

class ManagementScreen extends StatelessWidget {
  final VoidCallback? onTransactionAdded;
  const ManagementScreen({super.key, this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);
    final entries = CategoryItem.icons.entries
        .where((e) => e.key != 'All' && e.key != 'Bank') // ✅ lọc trước
        .toList();

    return Container(
      color: primary,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Management',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: SingleChildScrollView(
                // ✅
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to view and add transactions',
                      style: TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final cat = entries[index];
                        return CategoryTile().build(
                          context,
                          cat.value,
                          cat.key,
                          () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    Categorydetail(category: cat.key),
                              ),
                            );
                            if (result == true) onTransactionAdded?.call();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              18 * 2 -
                              12 * 2) /
                          3, // ✅ cùng size với GridView tile
                      height: (MediaQuery.of(context).size.width -
                              18 * 2 -
                              12 * 2) /
                          3,
                      child: GestureDetector(
                        onTap: () {},
                        child: CategoryTile().build(
                          context,
                          Icons.add,
                          'Add',
                          () async {
                            // final result = await Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (_) => Bankdetail(),
                            //   ),
                            // );
                            // if (result == true) onTransactionAdded?.call();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'More',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              18 * 2 -
                              12 * 2) /
                          3, // ✅ cùng size với GridView tile
                      height: (MediaQuery.of(context).size.width -
                              18 * 2 -
                              12 * 2) /
                          3,
                      child: GestureDetector(
                        onTap: () {},
                        child: CategoryTile().build(
                          context,
                          Icons.account_balance_rounded,
                          'Bank',
                          () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Bankdetail(),
                              ),
                            );
                            if (result == true) onTransactionAdded?.call();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
