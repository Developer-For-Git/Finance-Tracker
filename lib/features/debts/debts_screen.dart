import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/debt_model.dart';
import '../../shared/widgets/glass_card.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  void _showAddSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddDebtSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    final unsettled = debts.where((d) => !d.isSettled).toList();
    final settled = debts.where((d) => d.isSettled).toList();

    final iOwe = unsettled.where((d) => d.type == 'owe').fold(0.0, (s, d) => s + d.amount);
    final owedToMe = unsettled.where((d) => d.type == 'owed').fold(0.0, (s, d) => s + d.amount);
    final netBalance = owedToMe - iOwe;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debts_fab',
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Debt', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Debts & Loans', style: Theme.of(context).textTheme.headlineLarge),
          ),
          if (unsettled.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    GlassCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A3A4A), Color(0xFF0D2232)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Balance',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text(
                            '${netBalance >= 0 ? '+' : ''}${Formatters.formatCurrency(netBalance.abs(), symbol: symbol)}',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _BalancePill(
                              label: 'I Owe', amount: iOwe, color: AppColors.expense, symbol: symbol, context: context)),
                            const SizedBox(width: 12),
                            Expanded(child: _BalancePill(
                              label: 'Owed to Me', amount: owedToMe, color: AppColors.income, symbol: symbol, context: context)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (debts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.handshake_rounded, color: AppColors.tealPrimary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('No debts tracked', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Track money you owe or are owed', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    int offset = 0;
                    if (i == 0 && unsettled.isNotEmpty) {
                      return Padding(padding: const EdgeInsets.only(bottom: 10),
                        child: Text('Outstanding', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)));
                    }
                    offset = unsettled.isNotEmpty ? 1 : 0;
                    if (i >= offset && i < offset + unsettled.length) {
                      final d = unsettled[i - offset];
                      return _DebtTile(debt: d, symbol: symbol,
                        onSettle: () => ref.read(debtsProvider.notifier).settle(d.id),
                        onDelete: () => ref.read(debtsProvider.notifier).delete(d.id));
                    }
                    int offset2 = offset + unsettled.length;
                    if (i == offset2 && settled.isNotEmpty) {
                      return Padding(padding: const EdgeInsets.only(bottom: 10, top: 8),
                        child: Text('Settled', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)));
                    }
                    int offset3 = offset2 + (settled.isNotEmpty ? 1 : 0);
                    if (i >= offset3 && i < offset3 + settled.length) {
                      final d = settled[i - offset3];
                      return _DebtTile(debt: d, symbol: symbol,
                        onDelete: () => ref.read(debtsProvider.notifier).delete(d.id));
                    }
                    return null;
                  },
                  childCount: (unsettled.isNotEmpty ? unsettled.length + 1 : 0) +
                      (settled.isNotEmpty ? settled.length + 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String symbol;
  final BuildContext context;

  const _BalancePill({required this.label, required this.amount,
    required this.color, required this.symbol, required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(Formatters.formatCurrency(amount, symbol: symbol),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  final String symbol;
  final VoidCallback? onSettle;
  final VoidCallback onDelete;

  const _DebtTile({required this.debt, required this.symbol, this.onSettle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isOwe = debt.type == 'owe';
    final color = isOwe ? AppColors.expense : AppColors.income;
    final isOverdue = debt.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        border: isOverdue
            ? Border.all(color: AppColors.expense.withOpacity(0.5), width: 1.5)
            : null,
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(isOwe ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(debt.personName, style: Theme.of(context).textTheme.titleMedium)),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.expense.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Overdue', style: TextStyle(fontSize: 10, color: AppColors.expense, fontWeight: FontWeight.w600)),
                      ),
                    if (debt.isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Settled', style: TextStyle(fontSize: 10, color: AppColors.tealPrimary, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  Text(isOwe ? 'I owe them' : 'They owe me',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
                  if (debt.dueDate != null)
                    Text('Due: ${Formatters.formatDate(debt.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.expense : AppColors.textMuted)),
                  if (debt.note != null && debt.note!.isNotEmpty)
                    Text(debt.note!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(debt.amount, symbol: symbol),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!debt.isSettled && onSettle != null)
                      GestureDetector(
                        onTap: onSettle,
                        child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.income, size: 20),
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
}

// ── Add Debt Sheet ─────────────────────────────────────────────────────────────
class _AddDebtSheet extends ConsumerStatefulWidget {
  const _AddDebtSheet();
  @override
  ConsumerState<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'owe';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _amtCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    const uuid = Uuid();
    await ref.read(debtsProvider.notifier).add(DebtModel(
      id: uuid.v4(), personName: _nameCtrl.text.trim(),
      amount: double.tryParse(_amtCtrl.text) ?? 0,
      type: _type, dueDate: _dueDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
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
            Text('New Debt / Loan', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _TypeToggle(label: 'I Owe', isSelected: _type == 'owe',
                color: AppColors.expense, onTap: () => setState(() => _type = 'owe'))),
              const SizedBox(width: 12),
              Expanded(child: _TypeToggle(label: 'Owed to Me', isSelected: _type == 'owed',
                color: AppColors.income, onTap: () => setState(() => _type = 'owed'))),
            ]),
            const SizedBox(height: 14),
            TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Person Name', prefixIcon: Icon(Icons.person_rounded)),
              textCapitalization: TextCapitalization.words),
            const SizedBox(height: 14),
            TextField(controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money_rounded))),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (d != null) setState(() => _dueDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null ? 'Set due date (optional)' : Formatters.formatDate(_dueDate!),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _dueDate == null ? AppColors.textMuted : AppColors.textPrimary),
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                    : const Text('Add Debt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _TypeToggle({required this.label, required this.isSelected, required this.color, required this.onTap});

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
            color: isSelected ? color : AppColors.textSecondary, fontSize: 14)),
        ),
      ),
    );
  }
}
