import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/budget_model.dart';

class BudgetProvider with ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  BudgetModel? currentBudget;

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool isLoading = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? budgetSubscription;

  BudgetProvider() {
    loadBudget();
  }

  String getMonthName(int monthNumber) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[monthNumber - 1];
  }

  void selectMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month);

    loadBudget();
  }

  void loadBudget() {
    isLoading = true;
    notifyListeners();

    String monthName = getMonthName(selectedMonth.month);

    budgetSubscription?.cancel();

    budgetSubscription = firestore
        .collection('budgets')
        .where('month', isEqualTo: monthName)
        .where('year', isEqualTo: selectedMonth.year)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              var document = snapshot.docs.first;

              currentBudget = BudgetModel.fromJson(document.data());

              currentBudget!.docId = document.id;
            } else {
              currentBudget = null;
            }

            isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> createBudget(double amount) async {
    DateTime now = DateTime.now();

    BudgetModel newBudget = BudgetModel(
      month: getMonthName(selectedMonth.month),
      year: selectedMonth.year,
      amount: amount,
      createdAt: now,
      updatedAt: now,
    );

    DocumentReference<Map<String, dynamic>> document = await firestore
        .collection('budgets')
        .add(newBudget.toJson());

    newBudget.docId = document.id;

    currentBudget = newBudget;

    notifyListeners();
  }

  Future<void> updateBudget(double amount) async {
    if (currentBudget == null || currentBudget!.docId == null) {
      return;
    }

    DateTime now = DateTime.now();

    await firestore.collection('budgets').doc(currentBudget!.docId).update({
      'amount': amount,
      'updatedAt': Timestamp.fromDate(now),
    });

    currentBudget!.amount = amount;
    currentBudget!.updatedAt = now;

    notifyListeners();
  }

  Future<void> deleteBudget() async {
    if (currentBudget == null || currentBudget!.docId == null) {
      return;
    }

    await firestore.collection('budgets').doc(currentBudget!.docId).delete();

    currentBudget = null;

    notifyListeners();
  }

  double remainingBudget(double spent) {
    if (currentBudget == null) {
      return 0.0;
    }

    return (currentBudget!.amount ?? 0.0) - spent;
  }

  double usagePercentage(double spent) {
    if (currentBudget == null || (currentBudget!.amount ?? 0.0) <= 0) {
      return 0.0;
    }

    return (spent / currentBudget!.amount!) * 100;
  }

  bool isOverBudget(double spent) {
    if (currentBudget == null) {
      return false;
    }

    return spent > (currentBudget!.amount ?? 0.0);
  }

  double overBudgetAmount(double spent) {
    if (!isOverBudget(spent)) {
      return 0.0;
    }

    return spent - (currentBudget!.amount ?? 0.0);
  }

  @override
  void dispose() {
    budgetSubscription?.cancel();
    super.dispose();
  }
}
