import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/wallet_model.dart';
import '../../shared/widgets/glass_card.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  void _showAddSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWalletSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final transactions = ref.watch(transactionsProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    final Map<String, double> balances = {
      for (final w in wallets)
        w.id: transactions.fold(w.initialBalance, (sum, t) {
          if (t.walletId != w.id) return sum;
          return t.type == 'income' ? sum + t.amount : sum - t.amount;
        }),
    };
    final totalBalance = balances.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton.extended(
          heroTag: 'wallets_fab',
          onPressed: () => _showAddSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Wallets', style: Theme.of(context).textTheme.headlineLarge),
          ),
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
                    Text('Net Worth',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(totalBalance, symbol: symbol),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: totalBalance >= 0 ? AppColors.tealPrimary : AppColors.expense,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          if (wallets.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.tealPrimary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('No wallets yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Add a wallet to track balances', style: Theme.of(context).textTheme.bodyMedium),
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
                    final w = wallets[i];
                    final balance = balances[w.id] ?? w.initialBalance;
                    final color = AppColors.categoryColors[w.colorIndex % AppColors.categoryColors.length];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(_typeIcon(w.type), color: color, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(w.name, style: Theme.of(ctx).textTheme.titleMedium),
                                    if (w.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.tealGlow, borderRadius: BorderRadius.circular(6)),
                                        child: const Text('Default',
                                            style: TextStyle(fontSize: 10, color: AppColors.tealPrimary, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ]),
                                  Text(_typeLabel(w.type), style: Theme.of(ctx).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(balance, symbol: symbol),
                                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    color: balance >= 0 ? AppColors.tealPrimary : AppColors.expense,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ref.read(walletsProvider.notifier).delete(w.id);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: wallets.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bank': return Icons.account_balance_rounded;
      case 'credit': return Icons.credit_card_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'crypto': return Icons.currency_bitcoin_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bank': return 'Bank Account';
      case 'credit': return 'Credit Card';
      case 'savings': return 'Savings';
      case 'crypto': return 'Crypto';
      default: return 'Cash';
    }
  }
}

class _AddWalletSheet extends ConsumerStatefulWidget {
  const _AddWalletSheet();
  @override
  ConsumerState<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<_AddWalletSheet> {
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController(text: '0');
  String _type = 'cash';
  int _colorIndex = 0;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _balCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    const uuid = Uuid();
    await ref.read(walletsProvider.notifier).add(WalletModel(
      id: uuid.v4(), name: _nameCtrl.text.trim(), type: _type,
      colorIndex: _colorIndex, initialBalance: double.tryParse(_balCtrl.text) ?? 0,
      icon: '0xe227', isDefault: _isDefault, createdAt: DateTime.now(),
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
          Text('New Wallet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Wallet Name', prefixIcon: Icon(Icons.label_rounded)),
            textCapitalization: TextCapitalization.words),
          const SizedBox(height: 14),
          TextField(controller: _balCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Initial Balance', prefixIcon: Icon(Icons.attach_money_rounded))),
          const SizedBox(height: 14),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['cash', 'bank', 'credit', 'savings', 'crypto'].map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.tealGlow : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppColors.tealPrimary : AppColors.border, width: sel ? 1.5 : 1),
                    ),
                    child: Text(t[0].toUpperCase() + t.substring(1),
                      style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? AppColors.tealPrimary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Set as Default', style: Theme.of(context).textTheme.titleMedium),
              Switch(value: _isDefault, onChanged: (v) => setState(() => _isDefault = v), activeColor: AppColors.tealPrimary),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDeep))
                  : const Text('Create Wallet'),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
