import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/budget_model.dart';
import '../../data/providers/finance_providers.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showAddBudgetSheet() {
    HapticFeedback.lightImpact();
    _amountController.clear();
    _selectedCategoryId = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categories = ref.read(categoriesProvider).where((c) => c.type == 'expense' || c.type == 'both').toList();
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Category Budget', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Text('Category', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      final catColor = AppColors.categoryColors[cat.colorIndex % AppColors.categoryColors.length];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor.withOpacity(0.2) : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? catColor : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? catColor : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Limit',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedCategoryId == null || _amountController.text.isEmpty) return;
                        final amount = double.tryParse(_amountController.text) ?? 0;
                        if (amount <= 0) return;
                        
                        final now = DateTime.now();
                        final budget = BudgetModel(
                          id: const Uuid().v4(),
                          categoryId: _selectedCategoryId!,
                          amount: amount,
                          month: now.month,
                          year: now.year,
                          createdAt: now,
                        );
                        ref.read(budgetsProvider.notifier).add(budget);
                        Navigator.pop(context);
                      },
                      child: const Text('Save Budget'),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'budgets_fab',
        onPressed: _showAddBudgetSheet,
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Budgets', style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No budgets set', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Set monthly limits to keep track of spending', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final cat = categories.cast<dynamic>().firstWhere((c) => c.id == budget.categoryId, orElse: () => null);
                if (cat == null) return const SizedBox();

                final spent = breakdown[budget.categoryId] ?? 0.0;
                final progress = (spent / budget.amount).clamp(0.0, 1.0);
                final catColor = AppColors.categoryColors[cat.colorIndex % AppColors.categoryColors.length];
                final isOver = spent > budget.amount;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                            onPressed: () => ref.read(budgetsProvider.notifier).delete(budget.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$symbol${spent.toStringAsFixed(2)} spent',
                            style: TextStyle(
                              color: isOver ? AppColors.expense : AppColors.textPrimary,
                              fontWeight: isOver ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          Text(
                            'of $symbol${budget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.bgSurface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOver ? AppColors.expense : catColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
