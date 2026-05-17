import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../../shared/widgets/add_transaction_sheet.dart';
import '../../core/utils/formatters.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _filterTypeProvider = StateProvider<String?>((ref) => null);

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionsProvider);
    final query = ref.watch(_searchQueryProvider);
    final filterType = ref.watch(_filterTypeProvider);
    final categories = ref.watch(categoriesProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    // Filter
    var filtered = allTxns.where((t) {
      final matchesQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query.toLowerCase()) ||
          (t.note?.toLowerCase().contains(query.toLowerCase()) ?? false);
      final matchesType = filterType == null || t.type == filterType;
      return matchesQuery && matchesType;
    }).toList();

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = Formatters.relativeDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton.extended(
          heroTag: 'transactions_fab',
          onPressed: _showAddSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Transactions', style: Theme.of(context).textTheme.headlineLarge),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(_searchQueryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(_searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: filterType == null,
                        color: AppColors.tealPrimary,
                        onTap: () =>
                            ref.read(_filterTypeProvider.notifier).state = null,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Expenses',
                        isSelected: filterType == 'expense',
                        color: AppColors.expense,
                        onTap: () =>
                            ref.read(_filterTypeProvider.notifier).state = 'expense',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Income',
                        isSelected: filterType == 'income',
                        color: AppColors.income,
                        onTap: () =>
                            ref.read(_filterTypeProvider.notifier).state = 'income',
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(context, query),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final keys = grouped.keys.toList();
                    if (index >= keys.length) return null;
                    final dateKey = keys[index];
                    final txns = grouped[dateKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            dateKey,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                        ...txns.map((tx) {
                          final cat = categories.cast<dynamic>().firstWhere(
                                (c) => c.id == tx.categoryId,
                                orElse: () => null,
                              );
                          return TransactionTile(
                            transaction: tx,
                            category: cat,
                            currencySymbol: symbol,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddTransactionSheet(transactionToEdit: tx),
                              );
                            },
                            onDelete: () =>
                                ref.read(transactionsProvider.notifier).delete(tx.id),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No transactions yet' : 'No results for "$query"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty ? 'Tap the + button to add one' : 'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
