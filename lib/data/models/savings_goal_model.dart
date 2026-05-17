import 'package:hive/hive.dart';
part 'savings_goal_model.g.dart';

@HiveType(typeId: 4)
class SavingsGoalModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) double targetAmount;
  @HiveField(3) double currentAmount;
  @HiveField(4) DateTime? deadline;
  @HiveField(5) int colorIndex;
  @HiveField(6) String icon;
  @HiveField(7) DateTime createdAt;
  @HiveField(8) bool isCompleted;

  SavingsGoalModel({
    required this.id, required this.title, required this.targetAmount,
    this.currentAmount = 0, this.deadline, required this.colorIndex,
    required this.icon, required this.createdAt, this.isCompleted = false,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
}
