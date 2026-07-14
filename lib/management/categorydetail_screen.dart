import 'package:a_management/management/edit_transaction_screen.dart';
import 'package:a_management/services/database_service.dart';
import 'package:a_management/widget/bottomsheet.dart';

import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'package:a_management/widget/widget.dart';

class Categorydetail extends StatefulWidget {
  final String category;
  const Categorydetail({super.key, required this.category});

  @override
  State<Categorydetail> createState() => _CategorydetailState();
}

class _CategorydetailState extends State<Categorydetail> {
  late String displayedCategory;
  late DatabaseService db;

  @override
  void initState() {
    super.initState();
    displayedCategory = widget.category;
    db = DatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00C18A);
    const surface = Color(0xFFF3FFF8);
    Displaytransaction displaytransaction = Displaytransaction();

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: primary,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications,
                          color: Colors.black87),
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayedCategory,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          //Edit Category
                          Row(
                            children: [
                              if (widget.category != 'Others')
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00C18A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.more_horiz),
                                    onPressed: () async {
                                      final categoryId = await db
                                          .getCategoryId(widget.category);

                                      // Mở edit category bottom sheet
                                      final result =
                                          await showEditCategoryBottomSheet(
                                        context: context,
                                        id: categoryId,
                                      );

                                      if (result == true) {
                                        final categories =
                                            await db.getCategory();
                                        final updated = categories
                                                .where((item) =>
                                                    item.id == categoryId)
                                                .isNotEmpty
                                            ? categories.firstWhere(
                                                (item) => item.id == categoryId)
                                            : null;

                                        if (updated == null) {
                                          if (!mounted) return;
                                          Navigator.of(context).pop(true);
                                          return;
                                        }

                                        setState(() {
                                          displayedCategory = updated.title;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              SizedBox(width: 10),
                              //Add transaction
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C18A),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                          category: widget.category,
                                        ),
                                      ),
                                    );
                                    //debugPrint('******Result: $result');
                                    if (result == true) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      //const SizedBox(height: 6),
                      const Text(
                        'Tap to edit transactions',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45),
                      ),
                      Expanded(
                          child: displaytransaction.displayTransaction(
                        period: -1,
                        type: 'All',
                        bank: 'All',
                        categories: {displayedCategory},
                        title: '',
                        amountFrom: 0.00,
                        amountTo: 100000000000000.00,
                        dateFrom: DateTime(2020, 1, 1),
                        dateTo: DateTime(2030, 1, 1),
                        ontap: (int transactionId) async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditTransactionScreen(
                                id: transactionId,
                              ),
                            ),
                          );

                          //debugPrint('******Result: ${displaytransaction.transactionId}');
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
