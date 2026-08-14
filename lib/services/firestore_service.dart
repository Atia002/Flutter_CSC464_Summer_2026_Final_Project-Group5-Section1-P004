import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final CollectionReference _expensesRef =
      FirebaseFirestore.instance.collection('expenses');

  Stream<List<ExpenseModel>> streamExpenses() {
    return _expensesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesRef.add(expense.toMap());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }
}