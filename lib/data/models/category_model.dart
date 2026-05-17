import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // Icon codepoint as string

  @HiveField(3)
  int colorIndex; // Index into AppColors.categoryColors

  @HiveField(4)
  String type; // 'income', 'expense', or 'both'

  @HiveField(5)
  bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.type,
    this.isDefault = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorIndex,
    String? type,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
