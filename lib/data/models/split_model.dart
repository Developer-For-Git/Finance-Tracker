import 'package:hive/hive.dart';
part 'split_model.g.dart';

@HiveType(typeId: 8)
class SplitModel extends HiveObject {
  @HiveField(0)
  String categoryId;
  
  @HiveField(1)
  double amount;
  
  @HiveField(2)
  String? note;

  SplitModel({
    required this.categoryId,
    required this.amount,
    this.note,
  });

  SplitModel copyWith({
    String? categoryId,
    double? amount,
    String? note,
  }) {
    return SplitModel(
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}
