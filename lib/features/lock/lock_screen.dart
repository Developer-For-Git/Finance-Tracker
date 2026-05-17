import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import '../../services/biometric_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _isAuthenticating = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() { _isAuthenticating = true; _errorMsg = null; });
    final ok = await BiometricService.authenticate();
    if (mounted) {
      if (ok) {
        ref.read(isAuthenticatedProvider.notifier).state = true;
      } else {
        setState(() {
          _isAuthenticating = false;
          _errorMsg = 'Authentication failed. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.tealGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tealPrimary.withValues(alpha: 0.2 + _pulse.value * 0.3),
                        blurRadius: 30 + _pulse.value * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.bgDeep, size: 48),
                ),
              ),
              const SizedBox(height: 32),
              Text('Ather Wallet', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.tealPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Secured with Biometrics', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              // Fingerprint Button
              GestureDetector(
                onTap: _authenticate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAuthenticating
                        ? AppColors.tealPrimary.withValues(alpha: 0.2)
                        : AppColors.bgCard,
                    border: Border.all(
                      color: _isAuthenticating ? AppColors.tealPrimary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 40,
                    color: _isAuthenticating ? AppColors.tealPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isAuthenticating ? 'Verifying...' : 'Tap to authenticate',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(_errorMsg!, style: const TextStyle(color: AppColors.expense, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton(onPressed: _authenticate, child: const Text('Try Again')),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
