import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/widgets/transaction_tile.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final symbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    // Group transactions by day
    Map<DateTime, List<TransactionModel>> txnsByDay = {};
    for (var tx in allTxns) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      txnsByDay.putIfAbsent(date, () => []).add(tx);
    }

    // Get transactions for selected day
    final selectedDateOnly = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : null;
    final selectedDayTxns = selectedDateOnly != null ? txnsByDay[selectedDateOnly] ?? [] : [];

    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in selectedDayTxns) {
      if (tx.isIncome) totalIncome += tx.amount;
      if (tx.isExpense) totalExpense += tx.amount;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Calendar', style: Theme.of(context).textTheme.headlineLarge),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: TableCalendar<TransactionModel>(
                  firstDay: DateTime(2000),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    final d = DateTime(day.year, day.month, day.day);
                    return txnsByDay[d] ?? [];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();
                      
                      bool hasIncome = events.any((e) => e.isIncome);
                      bool hasExpense = events.any((e) => e.isExpense);
                      
                      return Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasIncome)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.income,
                                ),
                              ),
                            if (hasExpense)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.expense,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                    weekendStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    weekendTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.tealPrimary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.tealPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text(
                    _selectedDay != null ? DateFormat('MMMM d, yyyy').format(_selectedDay!) : 'Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (selectedDayTxns.isNotEmpty)
                    Text(
                      '${selectedDayTxns.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          if (selectedDayTxns.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 16),
                    Text('No transactions on this day', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            )
          else ...[
            // Summary for the day
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGlow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Income', style: TextStyle(color: AppColors.income, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('+$symbol${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.income, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.expenseGlow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expense', style: TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('-$symbol${totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.expense, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Transaction List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = selectedDayTxns[index];
                    final cat = categories.cast<dynamic>().firstWhere(
                          (c) => c.id == tx.categoryId,
                          orElse: () => null,
                        );
                    return TransactionTile(
                      transaction: tx,
                      category: cat,
                      currencySymbol: symbol,
                    );
                  },
                  childCount: selectedDayTxns.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
