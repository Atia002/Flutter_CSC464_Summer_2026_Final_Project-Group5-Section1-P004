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

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  selectMonth(budgetProvider);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  DateFormat('MMMM yyyy').format(budgetProvider.selectedMonth),
                ),
              ),

              const SizedBox(height: 20),

              if (budgetProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (budgetProvider.currentBudget == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 50,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'No budget set for ${DateFormat('MMMM yyyy').format(budgetProvider.selectedMonth)}',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: () {
                            showBudgetDialog(
                              isEditing: false,
                              budgetProvider: budgetProvider,
                            );
                          },
                          child: const Text('Set Budget'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
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
                              )
                            else
                              buildRow('Remaining', formatMoney(remaining)),

                            const SizedBox(height: 20),

                            LinearProgressIndicator(
                              value: (usage / 100).clamp(0.0, 1.0),
                              minHeight: 10,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              '${usage.toStringAsFixed(1)}% used',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: overBudget ? Colors.red : null,
                              ),
                            ),

                            if (overBudget)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'You are over your monthly budget.',
                                  style: TextStyle(color: Colors.red),
                                ),
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
                            icon: const Icon(Icons.delete),
                            label: const Text('Reset Budget'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17)),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
