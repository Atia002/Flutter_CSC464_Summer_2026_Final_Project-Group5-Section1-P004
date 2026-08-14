import 'package:flutter/foundation.dart';

// TEMP STUB — Person 3's real implementation will replace this.
// Only exists so the app compiles while testing the Expense/Firebase part.
class BudgetProvider extends ChangeNotifier {
  double? _budget;
  double? get budget => _budget;

  void setBudget(double amount) {
    _budget = amount;
    notifyListeners();
  }
}