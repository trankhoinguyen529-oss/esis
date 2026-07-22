import 'package:flutter/material.dart';
import 'package:a_management/management_child/add_expenditure_screen.dart';
import 'package:a_management/management_child/expenditure_edit_screen.dart';
import 'package:a_management/widget/widget.dart';

class ExpenditureManagementScreen extends StatefulWidget {
  const ExpenditureManagementScreen({super.key});

  @override
  State<ExpenditureManagementScreen> createState() => _ExpenditureManagementScreenState();
}

class _ExpenditureManagementScreenState extends State<ExpenditureManagementScreen> {
  Key _displayKey = UniqueKey();

  void _refresh() {
    setState(() {
      _displayKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00C18A);
    const scaffoldBg = Color(0xFFF6F9F8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Expenditure Budgets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenditureScreen(),
                ),
              ).then((_) => _refresh());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DisplayBudget(
          key: _displayKey,
          onTap: (budget, spentAmount) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenditureEditScreen(
                  budget: budget,
                  spentAmount: spentAmount,
                ),
              ),
            ).then((_) => _refresh());
          },
        ),
      ),
    );
  }
}

