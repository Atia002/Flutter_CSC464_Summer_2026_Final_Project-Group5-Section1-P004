import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    required this.createdAt,
  });

  // Convert Firestore document -> ExpenseModel
  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseModel(
      id: id,
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert ExpenseModel -> Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExpenseModel copyWith({
    String? name,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
  }) {
    return ExpenseModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}

// Fixed category list used across the app (dropdowns, filters, analytics)
const List<String> expenseCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Entertainment',
  'Health',
  'Other',
];
