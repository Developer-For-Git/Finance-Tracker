import 'package:hive/hive.dart';
part 'budget_model.g.dart';

@HiveType(typeId: 7)
class BudgetModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String categoryId;
  @HiveField(2) double amount;
  @HiveField(3) int month;
  @HiveField(4) int year;
  @HiveField(5) DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
