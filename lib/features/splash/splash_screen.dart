import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/models/recurring_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_history_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/split_model.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/repositories/finance_repository.dart';
import '../shell/app_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Logo pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Fade-out animation before navigating
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Logo scale-in on mount
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  // Shimmer for the tagline
  late AnimationController _shimmerController;

  bool _initDone = false;

  @override
  void initState() {
    super.initState();

    // ── Scale in ────────────────────────────────────────────
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();

    // ── Soft pulse glow ──────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Shimmer ──────────────────────────────────────────────
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // ── Fade-out ─────────────────────────────────────────────
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start init in parallel with animations
    _runInit();
  }

  Future<void> _runInit() async {
    // Run Hive init (it may already be done from main, but openBox is idempotent)
    await Hive.initFlutter();

    // Register adapters only if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WalletModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(RecurringModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SavingsGoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DebtModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TransactionHistoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(BudgetModelAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(SplitModelAdapter());
    }

    // Open boxes (idempotent if already open)
    if (!Hive.isBoxOpen(AppConstants.transactionBox)) {
      await Hive.openBox<TransactionModel>(AppConstants.transactionBox);
    }
    if (!Hive.isBoxOpen(AppConstants.categoryBox)) {
      await Hive.openBox<CategoryModel>(AppConstants.categoryBox);
    }
    if (!Hive.isBoxOpen(AppConstants.walletBox)) {
      await Hive.openBox<WalletModel>(AppConstants.walletBox);
    }
    if (!Hive.isBoxOpen(AppConstants.recurringBox)) {
      await Hive.openBox<RecurringModel>(AppConstants.recurringBox);
    }
    if (!Hive.isBoxOpen(AppConstants.goalsBox)) {
      await Hive.openBox<SavingsGoalModel>(AppConstants.goalsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.debtsBox)) {
      await Hive.openBox<DebtModel>(AppConstants.debtsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.historyBox)) {
      await Hive.openBox<TransactionHistoryModel>(AppConstants.historyBox);
    }
    if (!Hive.isBoxOpen('budgets')) {
      await Hive.openBox<BudgetModel>('budgets');
    }

    // Seed defaults
    final catRepo = CategoryRepository();
    await catRepo.seedDefaults();

    // Post-frame: load settings & seed wallets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
      ref.read(walletsProvider.notifier).seedDefault();
    });

    // Ensure a minimum display time of 1.5s so the logo is actually seen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _initDone = true);

    // Fade out then navigate
    await _fadeController.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ───────────────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF0097A7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tealPrimary
                                  .withValues(alpha: 0.35 * _pulseAnim.value),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.bgDeep,
                      size: 52,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── App name ────────────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const Text(
                    'Ather Wallet',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Tagline with shimmer ────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          final shimmerX = _shimmerController.value;
                          return LinearGradient(
                            begin: Alignment(-1.5 + shimmerX * 3, 0),
                            end: Alignment(-0.5 + shimmerX * 3, 0),
                            colors: const [
                              AppColors.textSecondary,
                              AppColors.tealLight,
                              AppColors.textSecondary,
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Your smart finance companion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 72),

                // ── Loading indicator ───────────────────────────────────
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.bgElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.tealPrimary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _initDone ? 'Ready!' : 'Loading your data…',
                    key: ValueKey(_initDone),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
