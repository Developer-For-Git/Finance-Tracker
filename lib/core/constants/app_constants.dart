class AppConstants {
  // Hive Box Names
  static const String transactionBox = 'transactions';
  static const String categoryBox = 'categories';
  static const String walletBox = 'wallets';
  static const String recurringBox = 'recurring';
  static const String goalsBox = 'savings_goals';
  static const String debtsBox = 'debts';
  static const String historyBox = 'transaction_history';

  // Settings Keys
  static const String currencyKey = 'currency';
  static const String currencySymbolKey = 'currency_symbol';
  static const String budgetKey = 'monthly_budget';
  static const String biometricKey = 'biometric_enabled';
  static const String privacyModeKey = 'privacy_mode';
  static const String themeModeKey = 'theme_mode'; // 'dark' | 'light'
  static const String reminderEnabledKey = 'reminder_enabled';
  static const String reminderHourKey = 'reminder_hour';
  static const String reminderMinuteKey = 'reminder_minute';

  // Default Values
  static const String defaultCurrency = 'USD';
  static const String defaultCurrencySymbol = '\$';
  static const double defaultBudget = 0.0;

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CAD', 'symbol': 'CA\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CHF', 'symbol': 'Fr', 'name': 'Swiss Franc'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
  ];
}

class TransactionType {
  static const String income = 'income';
  static const String expense = 'expense';
}

class WalletType {
  static const String cash = 'cash';
  static const String bank = 'bank';
  static const String credit = 'credit';
  static const String savings = 'savings';
}
