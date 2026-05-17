import 'package:hive/hive.dart';
part 'debt_model.g.dart';

@HiveType(typeId: 5)
class DebtModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String personName;
  @HiveField(2) double amount;
  @HiveField(3) String type; // 'owe' = I owe them | 'owed' = they owe me
  @HiveField(4) DateTime? dueDate;
  @HiveField(5) String? note;
  @HiveField(6) bool isSettled;
  @HiveField(7) DateTime createdAt;

  DebtModel({
    required this.id, required this.personName, required this.amount,
    required this.type, this.dueDate, this.note,
    this.isSettled = false, required this.createdAt,
  });

  bool get isOverdue => dueDate != null && !isSettled && dueDate!.isBefore(DateTime.now());
}
