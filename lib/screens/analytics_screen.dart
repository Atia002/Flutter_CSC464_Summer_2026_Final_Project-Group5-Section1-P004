import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> selectMonth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedMonth = DateTime(pickedDate.year, pickedDate.month);
      });
    }
  }

  String formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        double totalExpense = expenseProvider.totalExpense;

        double monthlyExpense = expenseProvider.totalForMonth(selectedMonth);

        Map<String, double> categoryTotals = expenseProvider
            .categoryTotalsForMonth(selectedMonth);

        String? highestCategory = expenseProvider.highestCategoryForMonth(
          selectedMonth,
        );

        int expenseCount = expenseProvider.countForMonth(selectedMonth);

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Expense Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: selectMonth,
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat('MMMM yyyy').format(selectedMonth)),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Expense',
                        style: TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        formatMoney(totalExpense),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('MMMM yyyy').format(selectedMonth)} Expense',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        formatMoney(monthlyExpense),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Number of Recorded Expenses'),
                  trailing: Text(
                    expenseCount.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.trending_up),
                  title: const Text('Highest Spending Category'),
                  subtitle: Text(highestCategory ?? 'No expenses recorded'),
                  trailing: highestCategory == null
                      ? null
                      : Text(
                          formatMoney(categoryTotals[highestCategory] ?? 0.0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Category-wise Spending',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (categoryTotals.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No expenses recorded for this month.'),
                  ),
                ),

              ...categoryTotals.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    trailing: Text(
                      formatMoney(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
