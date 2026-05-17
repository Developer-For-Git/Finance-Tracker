import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/recurring_model.dart';
import '../../shared/widgets/glass_card.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  void _showAddSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    final active = items.where((r) => r.isActive).toList();
    final inactive = items.where((r) => !r.isActive).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recurring_fab',
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recurring', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Recurring', style: Theme.of(context).textTheme.headlineLarge),
          ),
          if (items.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(children: [
                  Expanded(child: _SummaryTile(
                    label: 'Monthly Income',
                    amount: active.where((r) => r.type == 'income' && r.frequency == 'monthly')
                        .fold(0.0, (s, r) => s + r.amount),
                    color: AppColors.income, symbol: symbol, context: context,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryTile(
                    label: 'Monthly Bills',
                    amount: active.where((r) => r.type == 'expense' && r.frequency == 'monthly')
                        .fold(0.0, (s, r) => s + r.amount),
                    color: AppColors.expense, symbol: symbol, context: context,
                  )),
                ]),
              ),
            ),
          ],
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.repeat_rounded, color: AppColors.tealPrimary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('No recurring items', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Set up bills and subscriptions', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  if (i == 0 && active.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Active', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                    );
                  }
                  if (i == active.length + (active.isNotEmpty ? 1 : 0) && inactive.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text('Paused', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                    );
                  }

                  // item index logic
                  int itemIdx;
                  if (active.isNotEmpty && i > 0 && i <= active.length) {
                    itemIdx = i - 1;
                    final r = active[itemIdx];
                    return _RecurringTile(item: r, symbol: symbol,
                      onDelete: () => ref.read(recurringProvider.notifier).delete(r.id),
                      onToggle: () {
                        final updated = RecurringModel(
                          id: r.id, title: r.title, amount: r.amount, type: r.type,
                          categoryId: r.categoryId, frequency: r.frequency, dayOfMonth: r.dayOfMonth,
                          nextDueDate: r.nextDueDate, isActive: !r.isActive, note: r.note,
                          walletId: r.walletId, createdAt: r.createdAt,
                        );
                        ref.read(recurringProvider.notifier).update(updated);
                      });
                  } else {
                    int offset = active.isNotEmpty ? active.length + 1 : 0;
                    int inactiveOffset = inactive.isNotEmpty ? 1 : 0;
                    itemIdx = i - offset - inactiveOffset;
                    if (itemIdx < 0 || itemIdx >= inactive.length) return const SizedBox.shrink();
                    final r = inactive[itemIdx];
                    return _RecurringTile(item: r, symbol: symbol,
                      onDelete: () => ref.read(recurringProvider.notifier).delete(r.id),
                      onToggle: () {
                        final updated = RecurringModel(
                          id: r.id, title: r.title, amount: r.amount, type: r.type,
                          categoryId: r.categoryId, frequency: r.frequency, dayOfMonth: r.dayOfMonth,
                          nextDueDate: r.nextDueDate, isActive: !r.isActive, note: r.note,
                          walletId: r.walletId, createdAt: r.createdAt,
                        );
                        ref.read(recurringProvider.notifier).update(updated);
                      });
                  }
                },
                childCount: (active.isNotEmpty ? active.length + 1 : 0) +
                    (inactive.isNotEmpty ? inactive.length + 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String symbol;
  final BuildContext context;

  const _SummaryTile({required this.label, required this.amount,
    required this.color, required this.symbol, required this.context});

  @override
  Widget build(BuildContext _) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(Formatters.formatCurrency(amount, symbol: symbol),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringModel item;
  final String symbol;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _RecurringTile({required this.item, required this.symbol,
    required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isExpense = item.type == 'expense';
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${_freqLabel(item.frequency)} · Day ${item.dayOfMonth}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Next: ${Formatters.formatDateShort(item.nextDueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: item.isDueWithin7Days ? AppColors.expense : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}${Formatters.formatCurrency(item.amount, symbol: symbol)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                        item.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                        color: AppColors.textSecondary, size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _freqLabel(String f) {
    switch (f) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'yearly': return 'Yearly';
      default: return 'Monthly';
    }
  }
}

// ── Add Recurring Sheet ───────────────────────────────────────────────────────
class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();
  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _titleCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  String _freq = 'monthly';
  int _dayOfMonth = 1;
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _amtCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, _dayOfMonth).isBefore(now)
        ? DateTime(now.year, now.month + 1, _dayOfMonth)
        : DateTime(now.year, now.month, _dayOfMonth);
    const uuid = Uuid();
    final categories = ref.read(categoriesProvider);
    final catId = categories.isNotEmpty ? categories.first.id : 'default';
    await ref.read(recurringProvider.notifier).add(RecurringModel(
      id: uuid.v4(), title: _titleCtrl.text.trim(),
      amount: double.tryParse(_amtCtrl.text) ?? 0,
      type: _type, categoryId: catId, frequency: _freq,
      dayOfMonth: _dayOfMonth, nextDueDate: next,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: now,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Recurring', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            // Type toggle
            Row(children: [
              Expanded(child: _TypeBtn(label: 'Expense', isSelected: _type == 'expense',
                color: AppColors.expense, onTap: () => setState(() => _type = 'expense'))),
              const SizedBox(width: 12),
              Expanded(child: _TypeBtn(label: 'Income', isSelected: _type == 'income',
                color: AppColors.income, onTap: () => setState(() => _type = 'income'))),
            ]),
            const SizedBox(height: 14),
            TextField(controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.label_rounded)),
              textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 14),
            TextField(controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money_rounded))),
            const SizedBox(height: 14),
            Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['daily', 'weekly', 'monthly', 'yearly'].map((f) {
                  final sel = _freq == f;
                  return GestureDetector(
                    onTap: () => setState(() => _freq = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.tealGlow : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? AppColors.tealPrimary : AppColors.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.tealPrimary : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Text('Day of Month: $_dayOfMonth', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: _dayOfMonth.toDouble(), min: 1, max: 28, divisions: 27,
              activeColor: AppColors.tealPrimary,
              onChanged: (v) => setState(() => _dayOfMonth = v.round()),
            ),
            TextField(controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
                    : const Text('Create Recurring'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 14,
          )),
        ),
      ),
    );
  }
}
