import 'package:a_management/widget/category_item_icon.dart';
import 'package:a_management/management/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'package:a_management/widget/widget.dart';

class ManagementScreen extends StatelessWidget {
  final VoidCallback? onTransactionAdded;
  const ManagementScreen({super.key, this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);
    final entries = CategoryItem.icons.entries.toList();

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
                  Expanded(
                    child: GridView.builder(
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
                        CategoryTile categoryTile = CategoryTile();
                        return categoryTile.build(
                          context,
                          cat.value as IconData,
                          cat.key as String,
                          () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Categorydetail(
                                  category: cat.key as String,
                                ),
                              ),
                            );
                            if (result == true) {
                              onTransactionAdded?.call();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
