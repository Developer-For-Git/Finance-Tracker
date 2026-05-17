import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../../shared/widgets/add_transaction_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showAddSheet({String? type}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(initialType: type),
    );
  }

  void _showAboutDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDeveloperCard(context),
            const SizedBox(height: 16),
            _buildSupportCard(context),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, double currentBudget, String workspace, String initialSymbol, String initialCurrencyCode) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        String selectedSymbol = initialSymbol;
        String selectedCurrencyCode = initialCurrencyCode;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text(currentBudget == 0 ? 'Set Monthly Budget' : 'Add to Budget', style: const TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCurrencyCode,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.tealPrimary)),
                    ),
                    items: AppConstants.currencies.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text('${c['code']} (${c['symbol']})', style: const TextStyle(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedCurrencyCode = val;
                          selectedSymbol = AppConstants.currencies.firstWhere((c) => c['code'] == val)['symbol']!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      prefixText: '$selectedSymbol ',
                      prefixStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.w600),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.tealPrimary)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: AppColors.bgDeep,
                  ),
                  onPressed: () {
                    if (selectedCurrencyCode != initialCurrencyCode) {
                      ref.read(settingsProvider.notifier).setCurrency(selectedCurrencyCode, selectedSymbol);
                    }
                    final val = double.tryParse(controller.text.trim()) ?? 0.0;
                    if (val > 0) {
                      ref.read(settingsProvider.notifier).setBudget(currentBudget + val, workspace: workspace);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final symbol = settings['currencySymbol'] as String;
    final currencyCode = settings['currency'] as String;
    final totalBalance = ref.watch(totalBalanceProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final workspace = ref.watch(activeWorkspaceProvider);
    final budget = workspace == 'personal' ? settings['budget'] as double : (settings['businessBudget'] as double? ?? 0.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              toolbarHeight: 70,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_greeting()},',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    'Ather Wallet',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.tealPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => _showAboutDialog(),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 22),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddSheet(),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.bgDeep, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workspace Switcher (Prominent)
                    _buildWorkspaceSwitcher(context),
                    const SizedBox(height: 20),

                    // Balance Card (Glassmorphism)
                    _buildBalanceCard(context, totalBalance, monthlyIncome, monthlyExpense, symbol),
                    const SizedBox(height: 20),

                    // Quick Action Buttons
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Budget Progress
                    _buildBudgetCard(context, monthlyExpense, budget, symbol, currencyCode, workspace),
                    const SizedBox(height: 24),

                    // Month Selector
                    _buildMonthSelector(context, selectedMonth),
                    const SizedBox(height: 16),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                            style: Theme.of(context).textTheme.headlineMedium),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transaction List
                    if (recentTxns.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...recentTxns.map((tx) {
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
                          onDelete: () => ref
                              .read(transactionsProvider.notifier)
                              .delete(tx.id),
                        );
                      }),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceSwitcher(BuildContext context) {
    final workspace = ref.watch(activeWorkspaceProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(activeWorkspaceProvider.notifier).state = 'personal';
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: workspace == 'personal' ? AppColors.tealPrimary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: workspace == 'personal' ? AppColors.tealPrimary : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: workspace == 'personal' ? AppColors.tealPrimary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Personal', style: TextStyle(
                      color: workspace == 'personal' ? AppColors.tealPrimary : AppColors.textSecondary,
                      fontWeight: workspace == 'personal' ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(activeWorkspaceProvider.notifier).state = 'business';
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: workspace == 'business' ? Colors.amber.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: workspace == 'business' ? Colors.amber : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center_rounded, size: 16, color: workspace == 'business' ? Colors.amber : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Business', style: TextStyle(
                      color: workspace == 'business' ? Colors.amber : AppColors.textSecondary,
                      fontWeight: workspace == 'business' ? FontWeight.w700 : FontWeight.w500,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO', style: TextStyle(fontSize: 9, color: AppColors.bgDeep, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    return InkWell(
      onTap: () async {
        final Uri url = Uri.parse('https://github.com/Developer-For-Git');
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Could not launch GitHub profile'),
                backgroundColor: AppColors.expense,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.tealPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Developer-For-Git',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'https://github.com/Developer-For-Git',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.tealPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Support the Developer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'If you like this app, consider supporting its development!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/support.png',
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text('Please add support.png\nto assets/images/', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: AppColors.bgDeep,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF8A80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Support Project',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buy me a coffee or donate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
    String symbol,
  ) {
    final isNegative = balance < 0;
    return GlassCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A3A4A), Color(0xFF0D2232)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'All Time',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.tealPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isNegative ? '-' : ''}${Formatters.formatCurrency(balance.abs(), symbol: symbol)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: isNegative ? AppColors.expense : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Income',
                  amount: income,
                  color: AppColors.income,
                  symbol: symbol,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.glassBorder,
              ),
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Expense',
                  amount: expense,
                  color: AppColors.expense,
                  symbol: symbol,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required String symbol,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(
                  Formatters.formatCurrency(amount, symbol: symbol),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Add Expense',
            icon: Icons.remove_circle_rounded,
            gradient: AppColors.expenseGradient,
            onTap: () => _showAddSheet(type: 'expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Add Income',
            icon: Icons.add_circle_rounded,
            gradient: AppColors.incomeGradient,
            onTap: () => _showAddSheet(type: 'income'),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    double expense,
    double budget,
    String symbol,
    String currencyCode,
    String workspace,
  ) {
    if (budget == 0) {
      return AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.tealPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Monthly Budget', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Track your spending easily', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showAddBudgetDialog(context, budget, workspace, symbol, currencyCode),
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.tealPrimary, size: 28),
            ),
          ],
        ),
      );
    }

    final progress = math.min(expense / budget, 1.0);
    final isOverBudget = expense > budget;
    final progressColor = isOverBudget
        ? AppColors.expense
        : progress > 0.75
            ? AppColors.categoryColors[3]
            : AppColors.income;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Text(
                    '${Formatters.formatCurrency(expense, symbol: symbol)} / ${Formatters.formatCurrency(budget, symbol: symbol)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverBudget ? AppColors.expense : AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddBudgetDialog(context, budget, workspace, symbol, currencyCode),
                    child: const Icon(Icons.add_circle_rounded, color: AppColors.tealPrimary, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverBudget
                ? '⚠ Over budget by ${Formatters.formatCurrency(expense - budget, symbol: symbol)}'
                : '${Formatters.formatCurrency(budget - expense, symbol: symbol)} remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverBudget ? AppColors.expense : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime selectedMonth) {
    final now = DateTime.now();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(6, (i) {
          final date = DateTime(now.year, now.month - (5 - i));
          final isSelected = date.year == selectedMonth.year && date.month == selectedMonth.month;
          return GestureDetector(
            onTap: () {
              ref.read(selectedMonthProvider.notifier).state = date;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.tealGradient : null,
                color: isSelected ? null : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border,
                ),
              ),
              child: Text(
                Formatters.formatMonthShort(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.bgDeep : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.tealGlow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.tealPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction\nto get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _QuickActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: AppColors.bgDeep, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.bgDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
