import 'package:hive/hive.dart';
part 'recurring_model.g.dart';

@HiveType(typeId: 3)
class RecurringModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) double amount;
  @HiveField(3) String type; // 'income' or 'expense'
  @HiveField(4) String categoryId;
  @HiveField(5) String frequency; // 'daily','weekly','monthly','yearly'
  @HiveField(6) int dayOfMonth; // 1-31
  @HiveField(7) DateTime nextDueDate;
  @HiveField(8) bool isActive;
  @HiveField(9) String? note;
  @HiveField(10) String? walletId;
  @HiveField(11) DateTime createdAt;

  RecurringModel({
    required this.id, required this.title, required this.amount,
    required this.type, required this.categoryId, required this.frequency,
    required this.dayOfMonth, required this.nextDueDate,
    this.isActive = true, this.note, this.walletId, required this.createdAt,
  });

  bool get isDueWithin7Days {
    final now = DateTime.now();
    final diff = nextDueDate.difference(now).inDays;
    return diff >= 0 && diff <= 7;
  }
}
