import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedTxns = ref.watch(trashProvider);
    final categories = ref.watch(categoriesProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recycle Bin', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: deletedTxns.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('Trash is empty', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: deletedTxns.length,
              itemBuilder: (context, index) {
                final tx = deletedTxns[index];
                final cat = categories.cast<dynamic>().firstWhere(
                      (c) => c.id == tx.categoryId,
                      orElse: () => null,
                    );
                return _TrashTile(
                  transaction: tx,
                  category: cat,
                  currencySymbol: symbol,
                );
              },
            ),
    );
  }
}

class _TrashTile extends ConsumerWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final String currencySymbol;

  const _TrashTile({
    required this.transaction,
    required this.category,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TransactionTile(
        transaction: transaction,
        category: category,
        currencySymbol: currencySymbol,
        onTap: () {
          // Show bottom sheet with restore or hard delete options
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.bgCard,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: AppColors.tealPrimary),
                    title: const Text('Restore Transaction', style: TextStyle(color: AppColors.tealPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(transactionsProvider.notifier).restore(transaction.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction restored')));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
                    title: const Text('Delete Permanently', style: TextStyle(color: AppColors.expense)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(transactionsProvider.notifier).hardDelete(transaction.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction permanently deleted')));
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
