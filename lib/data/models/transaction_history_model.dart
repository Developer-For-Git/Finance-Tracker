import 'package:hive/hive.dart';
part 'transaction_history_model.g.dart';

@HiveType(typeId: 6)
class TransactionHistoryModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String transactionId;
  @HiveField(2) String action; // 'create', 'update', 'delete', 'restore'
  @HiveField(3) String details; // A readable string of what changed
  @HiveField(4) DateTime timestamp;

  TransactionHistoryModel({
    required this.id,
    required this.transactionId,
    required this.action,
    required this.details,
    required this.timestamp,
  });
}
