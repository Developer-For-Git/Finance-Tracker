import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/transaction_history_model.dart';
import '../../core/constants/app_constants.dart';

class TransactionRepository {
  Box<TransactionModel> get _box => Hive.box<TransactionModel>(AppConstants.transactionBox);

  List<TransactionModel> getAll() {
    final items = _box.values.where((t) => !t.isDeleted).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<TransactionModel> getDeleted() {
    final items = _box.values.where((t) => t.isDeleted).toList();
    items.sort((a, b) => (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
    return items;
  }

  List<TransactionModel> getByMonth(int year, int month) {
    return getAll().where((t) => t.date.year == year && t.date.month == month).toList();
  }

  List<TransactionModel> getByYear(int year) {
    return getAll().where((t) => t.date.year == year).toList();
  }

  List<TransactionModel> getByType(String type) {
    return getAll().where((t) => t.type == type).toList();
  }

  Future<void> add(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> update(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    final tx = _box.get(id);
    if (tx != null) {
      tx.isDeleted = true;
      tx.deletedAt = DateTime.now();
      await tx.save();
    }
  }

  Future<void> hardDelete(String id) async {
    await _box.delete(id);
  }

  Future<void> restore(String id) async {
    final tx = _box.get(id);
    if (tx != null) {
      tx.isDeleted = false;
      tx.deletedAt = null;
      await tx.save();
    }
  }

  double getTotalIncome({int? year, int? month}) {
    List<TransactionModel> txns;
    if (year != null && month != null) {
      txns = getByMonth(year, month);
    } else if (year != null) {
      txns = getByYear(year);
    } else {
      txns = getAll();
    }
    return txns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense({int? year, int? month}) {
    List<TransactionModel> txns;
    if (year != null && month != null) {
      txns = getByMonth(year, month);
    } else if (year != null) {
      txns = getByYear(year);
    } else {
      txns = getAll();
    }
    return txns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryBreakdown({int? year, int? month, String type = 'expense'}) {
    List<TransactionModel> txns;
    if (year != null && month != null) {
      txns = getByMonth(year, month);
    } else if (year != null) {
      txns = getByYear(year);
    } else {
      txns = getAll();
    }
    final filtered = txns.where((t) => t.type == type);
    final Map<String, double> breakdown = {};
    for (final t in filtered) {
      breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + t.amount;
    }
    return breakdown;
  }

  Map<int, double> getMonthlyTrend(int year, String type) {
    final Map<int, double> trend = {};
    for (int m = 1; m <= 12; m++) {
      final txns = getByMonth(year, m).where((t) => t.type == type);
      trend[m] = txns.fold(0.0, (sum, t) => sum + t.amount);
    }
    return trend;
  }

  List<TransactionModel> getRecent({int limit = 10}) {
    final all = getAll();
    return all.take(limit).toList();
  }
}

class TransactionHistoryRepository {
  Box<TransactionHistoryModel> get _box => Hive.box<TransactionHistoryModel>(AppConstants.historyBox);

  List<TransactionHistoryModel> getHistoryFor(String transactionId) {
    final items = _box.values.where((h) => h.transactionId == transactionId).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<TransactionHistoryModel> getAllHistory() {
    final items = _box.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> log(String transactionId, String action, String details) async {
    final id = const Uuid().v4();
    final entry = TransactionHistoryModel(
      id: id,
      transactionId: transactionId,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    );
    await _box.put(id, entry);
  }
}

class CategoryRepository {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(AppConstants.categoryBox);

  List<CategoryModel> getAll() => _box.values.toList();

  List<CategoryModel> getByType(String type) {
    return getAll().where((c) => c.type == type || c.type == 'both').toList();
  }

  CategoryModel? getById(String id) => _box.get(id);

  Future<void> add(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> update(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> seedDefaults() async {
    if (_box.isNotEmpty) return;
    const uuid = Uuid();

    final defaults = [
      CategoryModel(id: uuid.v4(), name: 'Food & Dining', icon: '0xe56c', colorIndex: 0, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Transport', icon: '0xe531', colorIndex: 1, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Shopping', icon: '0xe59c', colorIndex: 2, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Entertainment', icon: '0xe40e', colorIndex: 3, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Health', icon: '0xe3f3', colorIndex: 4, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Housing', icon: '0xe318', colorIndex: 5, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Utilities', icon: '0xe5c0', colorIndex: 6, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Education', icon: '0xe80c', colorIndex: 7, type: 'expense', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Salary', icon: '0xe227', colorIndex: 0, type: 'income', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Freelance', icon: '0xe8f9', colorIndex: 8, type: 'income', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Investment', icon: '0xe8dc', colorIndex: 9, type: 'income', isDefault: true),
      CategoryModel(id: uuid.v4(), name: 'Other', icon: '0xe8b8', colorIndex: 11, type: 'both', isDefault: true),
    ];

    for (final cat in defaults) {
      await _box.put(cat.id, cat);
    }
  }
}
