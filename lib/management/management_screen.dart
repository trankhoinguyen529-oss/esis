import 'package:a_management/assets/icon/categoryIcon.dart';
import 'package:a_management/management/bankdetailscreen.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/widget/bottomsheet.dart';
import 'package:a_management/management/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:a_management/widget/widget.dart';

import '../data/data_category.dart';

class ManagementScreen extends StatefulWidget {
  final VoidCallback? onTransactionAdded;
  const ManagementScreen({super.key, this.onTransactionAdded});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  String newCategoryTitle = '';
  IconData newCategoryIcon = Icons.category;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);
    final DatabaseService db = DatabaseService();
    final double tileSize =
        (MediaQuery.of(context).size.width - 18 * 2 - 12 * 2) / 3;

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
                    FutureBuilder<List<CategoryItem>>(
                      future: db.getCategory(),
                      builder: (context, snapshot) {
                        final entries = snapshot.data ?? [];
                        // hide built-in 'Bank' and 'All' categories from the grid
                        final visibleEntries = entries
                            .where((e) =>
                                e.title.toLowerCase() != 'bank' &&
                                e.title.toLowerCase() != 'all')
                            .toList();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: visibleEntries.length,
                          itemBuilder: (context, index) {
                            final cat = visibleEntries[index];
                            return CategoryTile().build(
                              context,
                              cat.icon,
                              cat.title,
                              () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        Categorydetail(category: cat.title),
                                  ),
                                );
                                if (result == true) {
                                  widget.onTransactionAdded?.call();
                                }
                              },
                            );
                          },
                        );
                      },
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
                    //Nút giao dịch qua Bank
                    Row(
                      children: [
                        SizedBox(
                          width: tileSize,
                          height: tileSize,
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
                                if (result == true)
                                  widget.onTransactionAdded?.call();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //Nút Add Category
                        SizedBox(
                          width: tileSize,
                          height: tileSize,
                          child: CategoryTile().build(
                            context,
                            Icons.add,
                            'Add Category',
                            () async {
                              final result = await showCustomBottomSheet(
                                context: context,
                                iconList: CategoryIcon.categoryIcons,
                              );
                              if (result != null) {
                                setState(() {
                                  newCategoryTitle =
                                      (result['title'] as String?) ?? '';
                                  newCategoryIcon =
                                      (result['icon'] as IconData?) ??
                                          Icons.category;
                                });

                                // persist into DB
                                try {
                                  final db = DatabaseService();
                                  final item = CategoryItem(
                                    userId: db.currentUserId,
                                    icon: newCategoryIcon,
                                    title: newCategoryTitle,
                                  );
                                  await db.insertCategory(item);
                                  // refresh UI to include the newly inserted category
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Category saved')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Save failed: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
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
