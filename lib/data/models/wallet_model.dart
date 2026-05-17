import 'package:hive/hive.dart';
part 'wallet_model.g.dart';

@HiveType(typeId: 2)
class WalletModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String type; // 'cash','bank','credit','savings','crypto'
  @HiveField(3) int colorIndex;
  @HiveField(4) double initialBalance;
  @HiveField(5) String icon;
  @HiveField(6) bool isDefault;
  @HiveField(7) DateTime createdAt;

  WalletModel({
    required this.id, required this.name, required this.type,
    required this.colorIndex, required this.initialBalance,
    required this.icon, this.isDefault = false, required this.createdAt,
  });
}
