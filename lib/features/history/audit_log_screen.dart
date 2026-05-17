import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  final String transactionId;

  const AuditLogScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepo = ref.read(transactionHistoryRepositoryProvider);
    final history = historyRepo.getHistoryFor(transactionId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit History', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text('No history found for this transaction.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final isCreate = entry.action == 'create';
                final isDelete = entry.action == 'delete';
                final isRestore = entry.action == 'restore';

                final color = isCreate
                    ? AppColors.tealPrimary
                    : isDelete
                        ? AppColors.expense
                        : isRestore
                            ? AppColors.income
                            : AppColors.categoryColors[3];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCreate
                              ? Icons.add_circle_outline_rounded
                              : isDelete
                                  ? Icons.delete_outline_rounded
                                  : isRestore
                                      ? Icons.restore_rounded
                                      : Icons.edit_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.action.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.details,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(entry.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
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
