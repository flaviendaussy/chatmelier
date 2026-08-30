class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final bool symbolPrefix;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    this.symbolPrefix = false,
  });

  String get label => '$code ($symbol) - $name';
}

class CurrencyHelper {
  static const List<CurrencyOption> supportedCurrencies = [
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro', symbolPrefix: false),
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar', symbolPrefix: true),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound', symbolPrefix: true),
    CurrencyOption(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', symbolPrefix: false),
    CurrencyOption(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', symbolPrefix: true),
    CurrencyOption(code: 'AUD', symbol: 'AU\$', name: 'Australian Dollar', symbolPrefix: true),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen', symbolPrefix: true),
    CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', symbolPrefix: true),
    CurrencyOption(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar', symbolPrefix: true),
    CurrencyOption(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', symbolPrefix: true),
  ];

  static const String defaultCurrency = 'EUR';

  static CurrencyOption getOption(String? currencyCode) {
    final code = (currencyCode ?? defaultCurrency).toUpperCase();
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyOption(code: code, symbol: code, name: code),
    );
  }

  static String getSymbol(String? currencyCode) {
    return getOption(currencyCode).symbol;
  }

  static String formatPrice(num? amount, {String? currency, int decimals = 0}) {
    if (amount == null) return '';
    final opt = getOption(currency);
    final formattedNum = decimals > 0 
        ? amount.toStringAsFixed(decimals) 
        : amount.round().toString();

    if (opt.symbolPrefix) {
      return '${opt.symbol}$formattedNum';
    } else {
      return '$formattedNum ${opt.symbol}';
    }
  }

  /// Approximate reference exchange rates to EUR for unified analytics valuation
  static const Map<String, double> approxRateToEur = {
    'EUR': 1.0,
    'USD': 0.92,
    'GBP': 1.17,
    'CHF': 1.05,
    'CAD': 0.67,
    'AUD': 0.60,
    'JPY': 0.006,
    'SGD': 0.68,
    'HKD': 0.12,
    'NZD': 0.55,
  };

  /// Convert amount from sourceCurrency to targetCurrency
  static double convert(num amount, {required String from, required String to}) {
    final fromRate = approxRateToEur[from.toUpperCase()] ?? 1.0;
    final toRate = approxRateToEur[to.toUpperCase()] ?? 1.0;
    final inEur = amount * fromRate;
    return inEur / toRate;
  }
}
