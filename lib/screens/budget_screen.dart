import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color getBudgetStatusColor(double usage) {
    if (usage > 100) {
      return Colors.red;
    } else if (usage >= 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String getBudgetStatusText(double usage) {
    if (usage > 100) {
      return 'You are over your monthly budget';
    } else if (usage >= 80) {
      return 'You are close to your monthly budget';
    } else if (usage >= 50) {
      return 'More than half of your budget is used';
    } else {
      return 'You are within your monthly budget';
    }
  }

  Future<void> selectMonth(BudgetProvider budgetProvider) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: budgetProvider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      budgetProvider.selectMonth(DateTime(pickedDate.year, pickedDate.month));
    }
  }

  Future<void> showBudgetDialog({
    required bool isEditing,
    required BudgetProvider budgetProvider,
  }) async {
    TextEditingController amountController = TextEditingController(
      text: isEditing
          ? (budgetProvider.currentBudget?.amount ?? 0).toStringAsFixed(2)
          : '',
    );

    GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Monthly Budget' : 'Set Monthly Budget'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a budget amount';
                }

                double? amount = double.tryParse(value.trim());

                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                double amount = double.parse(amountController.text.trim());

                if (isEditing) {
                  await budgetProvider.updateBudget(amount);
                } else {
                  await budgetProvider.createBudget(amount);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
  }

  Future<void> confirmDelete(BudgetProvider budgetProvider) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Budget?'),
          content: const Text(
            'This will delete the budget for the selected month.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await budgetProvider.deleteBudget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, child) {
        double spent = expenseProvider.totalForMonth(
          budgetProvider.selectedMonth,
        );

        double remaining = budgetProvider.remainingBudget(spent);

        double usage = budgetProvider.usagePercentage(spent);

        bool overBudget = budgetProvider.isOverBudget(spent);

        double overBudgetAmount = budgetProvider.overBudgetAmount(spent);

        Color statusColor = getBudgetStatusColor(usage);

        String selectedMonthText = DateFormat(
          'MMMM yyyy',
        ).format(budgetProvider.selectedMonth);

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
                  'Monthly Budget',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  'Manage your spending limit for each month.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () {
                    selectMonth(budgetProvider);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(selectedMonthText),
                ),

                const SizedBox(height: 20),

                if (budgetProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (budgetProvider.currentBudget == null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 52,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'No budget set for $selectedMonthText',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Set a monthly budget to track your spending.',
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 18),

                          ElevatedButton.icon(
                            onPressed: () {
                              showBudgetDialog(
                                isEditing: false,
                                budgetProvider: budgetProvider,
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Set Budget'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    size: 30,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      '$selectedMonthText Budget',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              buildRow(
                                'Budget',
                                formatMoney(
                                  budgetProvider.currentBudget?.amount ?? 0.0,
                                ),
                              ),

                              const Divider(),

                              buildRow('Spent', formatMoney(spent)),

                              const Divider(),

                              if (overBudget)
                                buildRow(
                                  'Over Budget',
                                  formatMoney(overBudgetAmount),
                                  valueColor: Colors.red,
                                )
                              else
                                buildRow('Remaining', formatMoney(remaining)),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Budget Usage',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${usage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (usage / 100).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  color: statusColor,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Icon(
                                    overBudget
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    color: statusColor,
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      getBudgetStatusText(usage),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showBudgetDialog(
                                  isEditing: true,
                                  budgetProvider: budgetProvider,
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Budget'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                confirmDelete(budgetProvider);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Reset Budget'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17)),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
