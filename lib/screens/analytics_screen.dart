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

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.purple;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.pink;
      case 'Bills':
        return Colors.orange;
      case 'Entertainment':
        return Colors.deepPurple;
      case 'Health':
        return Colors.green;
      case 'Other':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        double totalExpense = expenseProvider.totalExpense;

        double monthlyExpense = expenseProvider.totalForMonth(selectedMonth);

        Map<String, double> categoryTotals = expenseProvider
            .categoryTotalsForMonth(selectedMonth);

        List<MapEntry<String, double>> sortedCategories = categoryTotals.entries
            .toList();

        sortedCategories.sort((a, b) => b.value.compareTo(a.value));

        String? highestCategory = expenseProvider.highestCategoryForMonth(
          selectedMonth,
        );

        int expenseCount = expenseProvider.countForMonth(selectedMonth);

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/expense_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
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

                buildSummaryCard(
                  icon: Icons.payments,
                  title: 'All-Time Expense',
                  value: formatMoney(totalExpense),
                ),

                const SizedBox(height: 10),

                buildSummaryCard(
                  icon: Icons.calendar_month,
                  title:
                      '${DateFormat('MMMM yyyy').format(selectedMonth)} Expense',
                  value: formatMoney(monthlyExpense),
                ),

                const SizedBox(height: 10),

                buildSummaryCard(
                  icon: Icons.receipt_long,
                  title: 'Recorded Expenses',
                  value: expenseCount.toString(),
                ),

                const SizedBox(height: 10),

                buildSummaryCard(
                  icon: Icons.trending_up,
                  title: 'Highest Spending Category',
                  value: highestCategory ?? 'No expenses recorded',
                  subtitle: highestCategory == null
                      ? null
                      : formatMoney(categoryTotals[highestCategory] ?? 0.0),
                ),

                const SizedBox(height: 20),

                Text(
                  'Category-wise Spending of ${DateFormat('MMMM yyyy').format(selectedMonth)} ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (categoryTotals.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No expenses recorded for this month.'),
                    ),
                  ),

                if (categoryTotals.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: sortedCategories.map((entry) {
                          double percentage = monthlyExpense == 0
                              ? 0.0
                              : entry.value / monthlyExpense;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: getCategoryColor(entry.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      formatMoney(entry.value),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    SizedBox(
                                      width: 55,
                                      child: Text(
                                        '${(percentage * 100).toStringAsFixed(1)}%',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: getCategoryColor(entry.key),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 9,
                                    color: getCategoryColor(entry.key),
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
