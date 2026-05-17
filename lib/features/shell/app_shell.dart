import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_screen.dart';
import '../wallets/wallets_screen.dart';
import '../settings/settings_screen.dart';
import '../categories/categories_screen.dart';
import '../goals/goals_screen.dart';
import '../recurring/recurring_screen.dart';
import '../debts/debts_screen.dart';
import '../trash/trash_screen.dart';
import '../calendar/calendar_screen.dart';
import '../budgets/budgets_screen.dart';
import '../lock/lock_screen.dart';
import '../history/global_audit_log_screen.dart';
import '../../data/providers/finance_providers.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../services/backup_service.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (isBiometricEnabled && !isAuthenticated) {
      return const LockScreen();
    }

    final navIndex = ref.watch(_navIndexProvider);

    const screens = [
      DashboardScreen(),
      TransactionsScreen(),
      AnalyticsScreen(),
      WalletsScreen(),
      MoreScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: IndexedStack(
          index: navIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: navIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          ref.read(_navIndexProvider.notifier).state = i;
        },
      ),
    );
  }

}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);
    final items = [
      _MoreItem(Icons.calendar_month_rounded, 'Calendar', 'View daily transactions', AppColors.tealPrimary, const CalendarScreen()),
      _MoreItem(Icons.pie_chart_outline_rounded, 'Budgets', 'Category spending limits', AppColors.expense, const BudgetsScreen()),
      _MoreItem(Icons.savings_rounded, 'Savings Goals', 'Track your financial goals', AppColors.categoryColors[1], const GoalsScreen()),
      _MoreItem(Icons.repeat_rounded, 'Recurring', 'Bills & subscriptions', AppColors.categoryColors[3], const RecurringScreen()),
      _MoreItem(Icons.handshake_rounded, 'Debts & Loans', 'Track who owes whom', AppColors.categoryColors[2], const DebtsScreen()),
      _MoreItem(Icons.category_rounded, 'Categories', 'Manage your categories', AppColors.categoryColors[4], const CategoriesScreen()),
      _MoreItem(Icons.history_rounded, 'History & Audit Log', 'Track all changes', AppColors.categoryColors[0], const GlobalAuditLogScreen()),
      _MoreItem(Icons.delete_outline_rounded, 'Recycle Bin', 'Restore deleted items', AppColors.expense, const TrashScreen()),
      _MoreItem(Icons.settings_rounded, 'Settings', 'App preferences', AppColors.textSecondary, const SettingsScreen()),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('More', style: Theme.of(context).textTheme.headlineLarge),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.bgCard,
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                title: Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      reverseTransitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (ctx, animation, secondaryAnimation) {
                        return Scaffold(
                          backgroundColor: AppColors.bgDeep,
                          body: Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.bgGradient,
                            ),
                            child: item.screen,
                          ),
                        );
                      },
                      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
                        final slideAnim = Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slideAnim, child: child),
                        );
                      },
                    ),
                  );
                },
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.bgCard,
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.tealPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: AppColors.tealPrimary, size: 24),
                ),
                title: Text('App Lock', style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('Require biometrics to open', style: Theme.of(context).textTheme.bodySmall),
                trailing: Switch(
                  value: isBiometricEnabled,
                  activeColor: AppColors.tealPrimary,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(settingsProvider.notifier).setBiometric(val);
                  },
                ),
              ),
            ),
            // Export / Import Tools
            _buildActionTile(
              context: context,
              icon: Icons.file_upload_rounded,
              color: AppColors.tealPrimary,
              title: 'Import from CSV',
              subtitle: 'Import transactions from a CSV file',
              onTap: () async {
                HapticFeedback.lightImpact();
                try {
                  final count = await ImportService.importTransactionsFromCSV(ref);
                  if (count > 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count transactions!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                  }
                }
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.file_download_rounded,
              color: AppColors.tealPrimary,
              title: 'Export to CSV',
              subtitle: 'Export all transactions to a CSV spreadsheet',
              onTap: () async {
                HapticFeedback.lightImpact();
                final txns = ref.read(transactionsProvider);
                if (txns.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions to export')));
                  return;
                }
                try {
                  await ExportService.exportTransactionsToCSV(txns);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.tealPrimary,
              title: 'Export to PDF',
              subtitle: 'Generate a PDF report of your transactions',
              onTap: () async {
                HapticFeedback.lightImpact();
                final txns = ref.read(transactionsProvider);
                if (txns.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions to export')));
                  return;
                }
                try {
                  await ExportService.exportTransactionsToPDF(txns);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.backup_rounded,
              color: AppColors.tealPrimary,
              title: 'Create Backup',
              subtitle: 'Export local database files for safekeeping',
              onTap: () async {
                HapticFeedback.lightImpact();
                try {
                  await BackupService.createLocalBackup();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        tileColor: AppColors.bgCard,
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }


}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;
  const _MoreItem(this.icon, this.title, this.subtitle, this.color, this.screen);
}

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Txns'),
      _NavItem(Icons.analytics_rounded, Icons.analytics_outlined, 'Analytics'),
      _NavItem(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallets'),
      _NavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, 'More'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = currentIndex == i;
              return _NavButton(
                item: item,
                isActive: isActive,
                onTap: () => onTap(i),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.tealGlow : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.inactiveIcon,
                  key: ValueKey(widget.isActive),
                  color: widget.isActive ? AppColors.tealPrimary : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isActive ? AppColors.tealPrimary : AppColors.textMuted,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
