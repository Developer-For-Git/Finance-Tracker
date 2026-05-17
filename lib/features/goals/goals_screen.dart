import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/savings_goal_model.dart';
import '../../shared/widgets/glass_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _showAddSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    final totalTarget = activeGoals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalSaved = activeGoals.fold(0.0, (s, g) => s + g.currentAmount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Savings Goals', style: Theme.of(context).textTheme.headlineLarge),
          ),
          if (goals.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GlassCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A4A), Color(0xFF0D2232)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total Saved',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(8)),
                          child: Text('${activeGoals.length} Active',
                              style: const TextStyle(fontSize: 11, color: AppColors.tealPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(totalSaved, symbol: symbol),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.tealPrimary, fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${Formatters.formatCurrency(totalTarget, symbol: symbol)} target',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (totalTarget > 0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (totalSaved / totalTarget).clamp(0.0, 1.0),
                            backgroundColor: AppColors.bgSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tealPrimary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (goals.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.savings_rounded, color: AppColors.tealPrimary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('No savings goals', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Set a goal to start saving', style: Theme.of(context).textTheme.bodyMedium),
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
                    if (i == 0 && activeGoals.isNotEmpty) {
                      return Padding(padding: const EdgeInsets.only(bottom: 10),
                        child: Text('In Progress', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)));
                    }
                    offset = activeGoals.isNotEmpty ? 1 : 0;
                    if (i >= offset && i < offset + activeGoals.length) {
                      return _GoalCard(goal: activeGoals[i - offset], symbol: symbol,
                        onContribute: () => _showContributeDialog(ctx, ref, activeGoals[i - offset], symbol),
                        onDelete: () => ref.read(goalsProvider.notifier).delete(activeGoals[i - offset].id));
                    }
                    int offset2 = offset + activeGoals.length;
                    if (i == offset2 && completedGoals.isNotEmpty) {
                      return Padding(padding: const EdgeInsets.only(bottom: 10, top: 8),
                        child: Text('Completed', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)));
                    }
                    int offset3 = offset2 + (completedGoals.isNotEmpty ? 1 : 0);
                    if (i >= offset3 && i < offset3 + completedGoals.length) {
                      return _GoalCard(goal: completedGoals[i - offset3], symbol: symbol,
                        onDelete: () => ref.read(goalsProvider.notifier).delete(completedGoals[i - offset3].id));
                    }
                    return null;
                  },
                  childCount: (activeGoals.isNotEmpty ? activeGoals.length + 1 : 0) +
                      (completedGoals.isNotEmpty ? completedGoals.length + 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context, WidgetRef ref, SavingsGoalModel goal, String symbol) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount', prefixText: '$symbol '),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt != 0) {
                ref.read(goalsProvider.notifier).contribute(goal.id, amt);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final String symbol;
  final VoidCallback? onContribute;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.symbol, this.onContribute, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[goal.colorIndex % AppColors.categoryColors.length];
    final isComplete = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.savings_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
                      if (goal.deadline != null)
                        Text('By ${Formatters.formatDate(goal.deadline!)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Done', style: TextStyle(fontSize: 11, color: AppColors.tealPrimary, fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatCurrency(goal.currentAmount, symbol: symbol),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                Text(
                  'of ${Formatters.formatCurrency(goal.targetAmount, symbol: symbol)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: AppColors.bgSurface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            if (!isComplete && onContribute != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onContribute,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Contribute'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Add Goal Sheet ─────────────────────────────────────────────────────────────
class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();
  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  int _colorIndex = 0;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); _targetCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _targetCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    const uuid = Uuid();
    await ref.read(goalsProvider.notifier).add(SavingsGoalModel(
      id: uuid.v4(), title: _titleCtrl.text.trim(),
      targetAmount: double.tryParse(_targetCtrl.text) ?? 0,
      colorIndex: _colorIndex, icon: 'savings', deadline: _deadline, createdAt: DateTime.now(),
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
          Text('New Savings Goal', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          TextField(controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Goal Name', prefixIcon: Icon(Icons.flag_rounded)),
            textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 14),
          TextField(controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target Amount', prefixIcon: Icon(Icons.attach_money_rounded))),
          const SizedBox(height: 14),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(AppColors.categoryColors.length, (i) {
                final c = AppColors.categoryColors[i];
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: _colorIndex == i ? Border.all(color: Colors.white, width: 2.5) : null,
                      boxShadow: _colorIndex == i ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (d != null) setState(() => _deadline = d);
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
                      _deadline == null ? 'Set deadline (optional)' : Formatters.formatDate(_deadline!),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _deadline == null ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
                  : const Text('Create Goal'),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
