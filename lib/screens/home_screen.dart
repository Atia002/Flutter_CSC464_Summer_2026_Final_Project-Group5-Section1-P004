import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_expense_screen.dart';
import 'expense_details_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _ExpenseListTab(),
    AnalyticsScreen(),
    BudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditExpenseScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
        ],
      ),
    );
  }
}

class _ExpenseListTab extends StatelessWidget {
  const _ExpenseListTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/expense_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              if (provider.selectedCategory != null || provider.selectedMonth != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (provider.selectedCategory != null)
                        Chip(
                          label: Text(provider.selectedCategory!),
                          onDeleted: () => provider.setCategoryFilter(null),
                        ),
                      if (provider.selectedMonth != null)
                        Chip(
                          label: Text(
                              DateFormat('MMMM yyyy').format(provider.selectedMonth!)),
                          onDeleted: () => provider.setMonthFilter(null),
                        ),
                      ActionChip(
                        label: const Text('Clear all'),
                        onPressed: provider.clearFilters,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.visibleExpenses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 52,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No expenses found.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add an expense or change your filters.',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.visibleExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = provider.visibleExpenses[index];
                          return ExpenseTile(
                            expense: expense,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExpenseDetailsScreen(expense: expense),
                                ),
                              );
                            },
                            onDelete: () =>
                                provider.deleteExpense(expense.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _FilterSortSheet(),
    );
  }
}

class _FilterSortSheet extends StatelessWidget {
  const _FilterSortSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Category'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: provider.selectedCategory == null,
                onSelected: (_) => provider.setCategoryFilter(null),
              ),
              ...expenseCategories.map((cat) => ChoiceChip(
                    label: Text(cat),
                    selected: provider.selectedCategory == cat,
                    onSelected: (_) => provider.setCategoryFilter(cat),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Month'),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(
                  provider.selectedMonth == null
                      ? 'Select Month'
                      : DateFormat('MMMM yyyy').format(provider.selectedMonth!),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedMonth ?? now,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    helpText: 'Select any date in the month to filter',
                  );
                  if (picked != null) {
                    provider.setMonthFilter(DateTime(picked.year, picked.month));
                  }
                },
              ),
              if (provider.selectedMonth != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear month filter',
                  onPressed: () => provider.setMonthFilter(null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text('Sort by'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Newest first'),
                selected: provider.sortType == SortType.newest,
                onSelected: (_) => provider.setSortType(SortType.newest),
              ),
              ChoiceChip(
                label: const Text('Oldest first'),
                selected: provider.sortType == SortType.oldest,
                onSelected: (_) => provider.setSortType(SortType.oldest),
              ),
              ChoiceChip(
                label: const Text('Amount: High-Low'),
                selected: provider.sortType == SortType.amountHigh,
                onSelected: (_) => provider.setSortType(SortType.amountHigh),
              ),
              ChoiceChip(
                label: const Text('Amount: Low-High'),
                selected: provider.sortType == SortType.amountLow,
                onSelected: (_) => provider.setSortType(SortType.amountLow),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
