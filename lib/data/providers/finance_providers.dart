import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/recurring_model.dart';
import '../models/savings_goal_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import '../models/split_model.dart';
import '../repositories/finance_repository.dart';
import '../repositories/budget_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../services/notification_service.dart';

// ── Repositories ──────────────────────────────────────────────────────────────
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => TransactionRepository());
final transactionHistoryRepositoryProvider = Provider<TransactionHistoryRepository>((ref) => TransactionHistoryRepository());
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository());
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) => BudgetRepository());

// ── Settings ──────────────────────────────────────────────────────────────────
class SettingsNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() => {
    'currency': AppConstants.defaultCurrency,
    'currencySymbol': AppConstants.defaultCurrencySymbol,
    'budget': AppConstants.defaultBudget,
    'businessBudget': AppConstants.defaultBudget,
    'biometricEnabled': false,
    'privacyMode': false,
    'themeMode': 'dark',
    'reminderEnabled': false,
    'reminderHour': 20,
    'reminderMinute': 0,
  };

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    state = {
      'currency': p.getString(AppConstants.currencyKey) ?? AppConstants.defaultCurrency,
      'currencySymbol': p.getString(AppConstants.currencySymbolKey) ?? AppConstants.defaultCurrencySymbol,
      'budget': p.getDouble(AppConstants.budgetKey) ?? AppConstants.defaultBudget,
      'businessBudget': p.getDouble('${AppConstants.budgetKey}_business') ?? AppConstants.defaultBudget,
      'biometricEnabled': p.getBool(AppConstants.biometricKey) ?? false,
      'privacyMode': p.getBool(AppConstants.privacyModeKey) ?? false,
      'themeMode': p.getString(AppConstants.themeModeKey) ?? 'dark',
      'reminderEnabled': p.getBool(AppConstants.reminderEnabledKey) ?? false,
      'reminderHour': p.getInt(AppConstants.reminderHourKey) ?? 20,
      'reminderMinute': p.getInt(AppConstants.reminderMinuteKey) ?? 0,
    };
  }

  Future<void> setCurrency(String code, String symbol) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.currencyKey, code);
    await p.setString(AppConstants.currencySymbolKey, symbol);
    state = {...state, 'currency': code, 'currencySymbol': symbol};
  }

  Future<void> setBudget(double budget, {String workspace = 'personal'}) async {
    final p = await SharedPreferences.getInstance();
    if (workspace == 'personal') {
      await p.setDouble(AppConstants.budgetKey, budget);
      state = {...state, 'budget': budget};
    } else {
      await p.setDouble('${AppConstants.budgetKey}_business', budget);
      state = {...state, 'businessBudget': budget};
    }
  }

  Future<void> setBiometric(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppConstants.biometricKey, enabled);
    state = {...state, 'biometricEnabled': enabled};
  }

  Future<void> setPrivacyMode(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppConstants.privacyModeKey, enabled);
    state = {...state, 'privacyMode': enabled};
  }

  Future<void> setThemeMode(String mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.themeModeKey, mode);
    state = {...state, 'themeMode': mode};
  }

  Future<void> setReminder(bool enabled, int hour, int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppConstants.reminderEnabledKey, enabled);
    await p.setInt(AppConstants.reminderHourKey, hour);
    await p.setInt(AppConstants.reminderMinuteKey, minute);
    if (enabled) {
      await NotificationService.scheduleDailyReminder(hour, minute);
    } else {
      await NotificationService.cancelAll();
    }
    state = {...state, 'reminderEnabled': enabled, 'reminderHour': hour, 'reminderMinute': minute};
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Map<String, dynamic>>(() => SettingsNotifier());

// ── Theme Mode ────────────────────────────────────────────────────────────────
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider)['themeMode'] as String;
  return mode == 'light' ? ThemeMode.light : ThemeMode.dark;
});

// ── Privacy Mode ──────────────────────────────────────────────────────────────
final privacyModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider)['privacyMode'] as bool;
});

// ── Biometric ─────────────────────────────────────────────────────────────────
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider)['biometricEnabled'] as bool;
});

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// ── Date Selection ────────────────────────────────────────────────────────────
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// ── Workspaces ────────────────────────────────────────────────────────────────
final activeWorkspaceProvider = StateProvider<String>((ref) => 'personal');

// ── Transactions ──────────────────────────────────────────────────────────────
class TransactionsNotifier extends Notifier<List<TransactionModel>> {
  @override
  List<TransactionModel> build() {
    final workspace = ref.watch(activeWorkspaceProvider);
    return ref.read(transactionRepositoryProvider).getAll().where((t) => t.workspaceId == workspace).toList();
  }

  void refresh() {
    final workspace = ref.read(activeWorkspaceProvider);
    state = ref.read(transactionRepositoryProvider).getAll().where((t) => t.workspaceId == workspace).toList();
  }

  Future<void> add({
    required String title, required double amount, required String type,
    required String categoryId, required DateTime date, String? note, String? walletId,
    List<String> tags = const [], String? receiptPath,
    List<SplitModel>? splits, DateTime? warrantyDate, DateTime? returnDate,
  }) async {
    const uuid = Uuid();
    final workspace = ref.read(activeWorkspaceProvider);
    final tx = TransactionModel(
      id: uuid.v4(), title: title, amount: amount, type: type,
      categoryId: categoryId, date: date, note: note,
      walletId: walletId, createdAt: DateTime.now(),
      tags: tags, receiptPath: receiptPath,
      workspaceId: workspace,
      splits: splits, warrantyDate: warrantyDate, returnDate: returnDate,
    );
    await ref.read(transactionRepositoryProvider).add(tx);
    await ref.read(transactionHistoryRepositoryProvider).log(tx.id, 'create', 'Created transaction: $title ($amount)');
    refresh();
  }

  Future<void> update(TransactionModel tx) async {
    await ref.read(transactionRepositoryProvider).update(tx);
    await ref.read(transactionHistoryRepositoryProvider).log(tx.id, 'update', 'Updated transaction details');
    refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(transactionRepositoryProvider).delete(id);
    await ref.read(transactionHistoryRepositoryProvider).log(id, 'delete', 'Moved to trash');
    refresh();
  }

  Future<void> restore(String id) async {
    await ref.read(transactionRepositoryProvider).restore(id);
    await ref.read(transactionHistoryRepositoryProvider).log(id, 'restore', 'Restored from trash');
    refresh();
  }

  Future<void> hardDelete(String id) async {
    await ref.read(transactionRepositoryProvider).hardDelete(id);
    refresh();
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  () => TransactionsNotifier(),
);

final trashProvider = Provider<List<TransactionModel>>((ref) {
  ref.watch(transactionsProvider); // trigger on updates
  return ref.read(transactionRepositoryProvider).getDeleted();
});

final monthlyTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final sel = ref.watch(selectedMonthProvider);
  return ref.watch(transactionsProvider)
      .where((t) => t.date.year == sel.year && t.date.month == sel.month)
      .toList();
});

// ── Categories ────────────────────────────────────────────────────────────────
class CategoriesNotifier extends Notifier<List<CategoryModel>> {
  @override
  List<CategoryModel> build() => ref.read(categoryRepositoryProvider).getAll();
  void refresh() => state = ref.read(categoryRepositoryProvider).getAll();
  Future<void> add(CategoryModel c) async { await ref.read(categoryRepositoryProvider).add(c); refresh(); }
  Future<void> update(CategoryModel c) async { await ref.read(categoryRepositoryProvider).update(c); refresh(); }
  Future<void> delete(String id) async { await ref.read(categoryRepositoryProvider).delete(id); refresh(); }
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<CategoryModel>>(() => CategoriesNotifier());

final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, id) {
  try { return ref.watch(categoriesProvider).firstWhere((c) => c.id == id); } catch (_) { return null; }
});

// ── Wallets ───────────────────────────────────────────────────────────────────
class WalletsNotifier extends Notifier<List<WalletModel>> {
  Box<WalletModel> get _box => Hive.box<WalletModel>(AppConstants.walletBox);

  @override
  List<WalletModel> build() => _box.values.toList();

  void refresh() => state = _box.values.toList();

  Future<void> add(WalletModel w) async {
    if (w.isDefault) {
      for (var existing in _box.values) {
        if (existing.isDefault) {
          existing.isDefault = false;
          await existing.save();
        }
      }
    }
    await _box.put(w.id, w);
    refresh();
  }

  Future<void> update(WalletModel w) async {
    if (w.isDefault) {
      for (var existing in _box.values) {
        if (existing.isDefault && existing.id != w.id) {
          existing.isDefault = false;
          await existing.save();
        }
      }
    }
    await _box.put(w.id, w);
    refresh();
  }

  Future<void> delete(String id) async {
    final w = _box.get(id);
    await _box.delete(id);
    if (w != null && w.isDefault && _box.isNotEmpty) {
      final first = _box.values.first;
      first.isDefault = true;
      await first.save();
    }
    refresh();
  }

  Future<void> seedDefault() async {
    if (_box.isNotEmpty) return;
    const uuid = Uuid();
    final wallets = [
      WalletModel(id: uuid.v4(), name: 'Cash', type: 'cash', colorIndex: 0,
          initialBalance: 0, icon: '0xe227', isDefault: true, createdAt: DateTime.now()),
      WalletModel(id: uuid.v4(), name: 'Bank Account', type: 'bank', colorIndex: 1,
          initialBalance: 0, icon: '0xe8f3', isDefault: false, createdAt: DateTime.now()),
    ];
    for (final w in wallets) await _box.put(w.id, w);
    refresh();
  }
}

final walletsProvider = NotifierProvider<WalletsNotifier, List<WalletModel>>(() => WalletsNotifier());

final selectedWalletProvider = StateProvider<String?>((ref) => null); // null = all wallets

// ── Savings Goals ─────────────────────────────────────────────────────────────
class GoalsNotifier extends Notifier<List<SavingsGoalModel>> {
  Box<SavingsGoalModel> get _box => Hive.box<SavingsGoalModel>(AppConstants.goalsBox);

  @override
  List<SavingsGoalModel> build() => _box.values.toList();

  void refresh() => state = _box.values.toList();

  Future<void> add(SavingsGoalModel g) async { await _box.put(g.id, g); refresh(); }

  Future<void> contribute(String id, double amount) async {
    final goal = _box.get(id);
    if (goal == null) return;
    goal.currentAmount = (goal.currentAmount + amount).clamp(0, goal.targetAmount);
    goal.isCompleted = goal.currentAmount >= goal.targetAmount;
    await goal.save();
    refresh();
  }

  Future<void> delete(String id) async { await _box.delete(id); refresh(); }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<SavingsGoalModel>>(() => GoalsNotifier());

// ── Recurring Transactions ────────────────────────────────────────────────────
class RecurringNotifier extends Notifier<List<RecurringModel>> {
  Box<RecurringModel> get _box => Hive.box<RecurringModel>(AppConstants.recurringBox);

  @override
  List<RecurringModel> build() => _box.values.toList();

  void refresh() => state = _box.values.toList();

  Future<void> add(RecurringModel r) async { await _box.put(r.id, r); refresh(); }
  Future<void> update(RecurringModel r) async { await _box.put(r.id, r); refresh(); }
  Future<void> delete(String id) async { await _box.delete(id); refresh(); }
}

final recurringProvider = NotifierProvider<RecurringNotifier, List<RecurringModel>>(() => RecurringNotifier());

final upcomingBillsProvider = Provider<List<RecurringModel>>((ref) {
  return ref.watch(recurringProvider)
      .where((r) => r.isActive && r.type == 'expense' && r.isDueWithin7Days)
      .toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
});

// ── Debts ─────────────────────────────────────────────────────────────────────
class DebtsNotifier extends Notifier<List<DebtModel>> {
  Box<DebtModel> get _box => Hive.box<DebtModel>(AppConstants.debtsBox);

  @override
  List<DebtModel> build() => _box.values.toList();

  void refresh() => state = _box.values.toList();

  Future<void> add(DebtModel d) async { await _box.put(d.id, d); refresh(); }

  Future<void> settle(String id) async {
    final debt = _box.get(id);
    if (debt == null) return;
    debt.isSettled = true;
    await debt.save();
    refresh();
  }

  Future<void> delete(String id) async { await _box.delete(id); refresh(); }
}

final debtsProvider = NotifierProvider<DebtsNotifier, List<DebtModel>>(() => DebtsNotifier());

// ── Budgets ───────────────────────────────────────────────────────────────────
class BudgetsNotifier extends Notifier<List<BudgetModel>> {
  @override
  List<BudgetModel> build() => ref.read(budgetRepositoryProvider).getAll();

  void refresh() => state = ref.read(budgetRepositoryProvider).getAll();

  Future<void> add(BudgetModel b) async { await ref.read(budgetRepositoryProvider).add(b); refresh(); }
  Future<void> update(BudgetModel b) async { await ref.read(budgetRepositoryProvider).update(b); refresh(); }
  Future<void> delete(String id) async { await ref.read(budgetRepositoryProvider).delete(id); refresh(); }
}

final budgetsProvider = NotifierProvider<BudgetsNotifier, List<BudgetModel>>(() => BudgetsNotifier());

// ── Summary Providers ─────────────────────────────────────────────────────────
final monthlyIncomeProvider = Provider<double>((ref) =>
    ref.watch(monthlyTransactionsProvider).where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount));

final monthlyExpenseProvider = Provider<double>((ref) =>
    ref.watch(monthlyTransactionsProvider).where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount));

final monthlyBalanceProvider = Provider<double>((ref) =>
    ref.watch(monthlyIncomeProvider) - ref.watch(monthlyExpenseProvider));

final totalBalanceProvider = Provider<double>((ref) {
  final all = ref.watch(transactionsProvider);
  final wallets = ref.watch(walletsProvider);
  final initialBalances = wallets.fold(0.0, (sum, w) => sum + w.initialBalance);
  final income = all.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  final expense = all.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
  return initialBalances + income - expense;
});

final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final Map<String, double> breakdown = {};
  for (final t in ref.watch(monthlyTransactionsProvider).where((t) => t.type == 'expense')) {
    breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + t.amount;
  }
  return breakdown;
});

final yearlyTrendProvider = Provider<Map<int, Map<String, double>>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final all = ref.watch(transactionsProvider);
  final Map<int, Map<String, double>> result = {};
  for (int m = 1; m <= 12; m++) {
    final txns = all.where((t) => t.date.year == year && t.date.month == m);
    result[m] = {
      'income': txns.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount),
      'expense': txns.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount),
    };
  }
  return result;
});

final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) =>
    ref.watch(transactionsProvider).take(20).toList());
