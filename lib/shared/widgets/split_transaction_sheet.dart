import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/split_model.dart';
import '../../data/providers/finance_providers.dart';
import '../../core/utils/icon_helper.dart';

class SplitTransactionSheet extends ConsumerStatefulWidget {
  final double? totalAmount;
  final List<SplitModel> initialSplits;
  final String transactionType;

  const SplitTransactionSheet({
    super.key,
    this.totalAmount,
    required this.initialSplits,
    required this.transactionType,
  });

  @override
  ConsumerState<SplitTransactionSheet> createState() => _SplitTransactionSheetState();
}

class _SplitTransactionSheetState extends ConsumerState<SplitTransactionSheet> {
  late List<SplitModel> _splits;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _splits = List.from(widget.initialSplits.map((s) => s.copyWith()));
    if (_splits.isEmpty && widget.totalAmount != null && widget.totalAmount! > 0) {
      // Initialize with one split matching the total
      _splits.add(SplitModel(
        categoryId: '',
        amount: widget.totalAmount!,
        note: null,
      ));
    }
  }

  void _addSplit() {
    setState(() {
      _splits.add(SplitModel(
        categoryId: '',
        amount: 0.0,
      ));
    });
  }

  void _removeSplit(int index) {
    setState(() {
      _splits.removeAt(index);
    });
  }

  double get _currentTotal => _splits.fold(0.0, (sum, split) => sum + split.amount);
  double get _remaining => (widget.totalAmount ?? 0.0) - _currentTotal;

  void _save() {
    // Validate
    bool isValid = true;
    for (var s in _splits) {
      if (s.categoryId.isEmpty) isValid = false;
      if (s.amount <= 0) isValid = false;
    }
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and amount > 0 for all splits.')),
      );
      return;
    }

    if (widget.totalAmount != null && widget.totalAmount! > 0) {
      if ((_currentTotal - widget.totalAmount!).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Splits total (${_currentTotal.toStringAsFixed(2)}) must equal transaction amount (${widget.totalAmount!.toStringAsFixed(2)}).')),
        );
        return;
      }
    }

    Navigator.pop(context, _splits);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider)
        .where((c) => c.type == widget.transactionType || c.type == 'both')
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Split Transaction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _addSplit,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.tealPrimary),
                  label: const Text('Add Split', style: TextStyle(color: AppColors.tealPrimary)),
                )
              ],
            ),
          ),
          if (widget.totalAmount != null && widget.totalAmount! > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: \$${widget.totalAmount!.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary)),
                  Text(
                    'Remaining: \$${_remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _remaining == 0 ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: AppColors.border),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: _splits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final split = _splits[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Select Category', style: TextStyle(color: AppColors.textSecondary)),
                                value: split.categoryId.isEmpty ? null : split.categoryId,
                                dropdownColor: AppColors.bgSurface,
                                items: categories.map((cat) {
                                  final catColor = AppColors.categoryColors[cat.colorIndex % AppColors.categoryColors.length];
                                  return DropdownMenuItem<String>(
                                    value: cat.id,
                                    child: Row(
                                      children: [
                                        Icon(IconHelper.getIcon(cat.icon), color: catColor, size: 20),
                                        const SizedBox(width: 8),
                                        Text(cat.name, style: const TextStyle(color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => split.categoryId = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                            onPressed: () => _removeSplit(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: split.amount == 0 ? '' : split.amount.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  split.amount = double.tryParse(v) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: split.note ?? '',
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Note (Optional)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (v) {
                                split.note = v;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _splits.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Splits', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.bgDeep)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
