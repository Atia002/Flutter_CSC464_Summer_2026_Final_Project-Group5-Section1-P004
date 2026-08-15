import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  String? docId;
  String? month;
  int? year;
  double? amount;
  DateTime? createdAt;
  DateTime? updatedAt;

  BudgetModel({
    this.docId,
    this.month,
    this.year,
    this.amount,
    this.createdAt,
    this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      docId: json['doc_id'] as String? ?? '',
      month: json['month'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month ?? '',
      'year': year ?? 0,
      'amount': amount ?? 0.0,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }
}
