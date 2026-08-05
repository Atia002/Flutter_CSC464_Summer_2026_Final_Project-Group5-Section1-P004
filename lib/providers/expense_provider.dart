import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';

enum SortType { newest, oldest, amountHigh, amountLow }

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  StreamSubscription<List<ExpenseModel>>? _sub;

  List<ExpenseModel> _allExpenses = []; // raw data from Firestore
  List<ExpenseModel> get allExpenses => _allExpenses;

  // ---- filter / search / sort state ----
  String _searchQuery = '';
  String? _selectedCategory; // null = all categories
  DateTime? _selectedMonth; // filter by month/year (day ignored)
  SortType _sortType = SortType.newest;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    loadExpenses();
  }

  // Load expenses (real-time listener)
  void loadExpenses() {
    _isLoading = true;
    _sub?.cancel();
    _sub = _service.streamExpenses().listen((expenses) {
      _allExpenses = expenses;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _service.addExpense(expense);
  }

  Future<void> editExpense(ExpenseModel expense) async {
    await _service.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _service.deleteExpense(id);
  }

  // ---- search / filter / sort setters ----
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setMonthFilter(DateTime? month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSortType(SortType type) {
    _sortType = type;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedMonth = null;
    _sortType = SortType.newest;
    notifyListeners();
  }

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTime? get selectedMonth => _selectedMonth;
  SortType get sortType => _sortType;

  // The final list the UI should render: search + filter + sort applied
  List<ExpenseModel> get visibleExpenses {
    List<ExpenseModel> result = List.from(_allExpenses);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != null) {
      result = result.where((e) => e.category == _selectedCategory).toList();
    }

    if (_selectedMonth != null) {
      result = result
          .where((e) =>
              e.date.year == _selectedMonth!.year &&
              e.date.month == _selectedMonth!.month)
          .toList();
    }

    switch (_sortType) {
      case SortType.newest:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortType.oldest:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortType.amountHigh:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortType.amountLow:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return result;
  }

  // ---- Analytics helpers ----

  double get totalExpense =>
      _allExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double totalForMonth(DateTime month) {
    return _allExpenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> categoryTotalsForMonth(DateTime month) {
    final Map<String, double> totals = {};
    for (final e in _allExpenses) {
      if (e.date.year == month.year && e.date.month == month.month) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
    }
    return totals;
  }

  String? highestCategoryForMonth(DateTime month) {
    final totals = categoryTotalsForMonth(month);
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int countForMonth(DateTime month) {
    return _allExpenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
