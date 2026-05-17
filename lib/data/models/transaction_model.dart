import 'package:hive/hive.dart';
import 'split_model.dart';
part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) double amount;
  @HiveField(3) String type;
  @HiveField(4) String categoryId;
  @HiveField(5) DateTime date;
  @HiveField(6) String? note;
  @HiveField(7) DateTime createdAt;
  @HiveField(8) String? walletId; // null = no specific wallet
  @HiveField(9) bool isDeleted;
  @HiveField(10) DateTime? deletedAt;
  @HiveField(11) List<String> tags;
  @HiveField(12) String? receiptPath;
  @HiveField(13) String workspaceId; // 'personal' or 'business'
  @HiveField(14) DateTime? warrantyDate;
  @HiveField(15) DateTime? returnDate;
  @HiveField(16) List<SplitModel>? splits;

  TransactionModel({
    required this.id, required this.title, required this.amount,
    required this.type, required this.categoryId, required this.date,
    this.note, required this.createdAt, this.walletId,
    this.isDeleted = false, this.deletedAt,
    this.tags = const [],
    this.receiptPath,
    this.workspaceId = 'personal',
    this.warrantyDate,
    this.returnDate,
    this.splits,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  TransactionModel copyWith({
    String? id, String? title, double? amount, String? type,
    String? categoryId, DateTime? date, String? note,
    DateTime? createdAt, String? walletId,
    bool? isDeleted, DateTime? deletedAt,
    List<String>? tags,
    String? receiptPath,
    String? workspaceId,
    DateTime? warrantyDate,
    DateTime? returnDate,
    List<SplitModel>? splits,
  }) => TransactionModel(
    id: id ?? this.id, title: title ?? this.title,
    amount: amount ?? this.amount, type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId, date: date ?? this.date,
    note: note ?? this.note, createdAt: createdAt ?? this.createdAt,
    walletId: walletId ?? this.walletId,
    isDeleted: isDeleted ?? this.isDeleted, deletedAt: deletedAt ?? this.deletedAt,
    tags: tags ?? this.tags,
    receiptPath: receiptPath ?? this.receiptPath,
    workspaceId: workspaceId ?? this.workspaceId,
    warrantyDate: warrantyDate ?? this.warrantyDate,
    returnDate: returnDate ?? this.returnDate,
    splits: splits ?? this.splits,
  );
}
