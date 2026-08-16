import 'dart:io' show Platform;

/// A display currency.
///
/// This is the whole story: amounts are stored as plain integer minor
/// units (`priceCents`) with no currency attached, everything lives on
/// one device, and nothing is ever converted. The currency only decides
/// how a number is *written* — which symbol, and which grouping style.
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.locale,
    required this.eurosPerUnit,
  });

  /// ISO 4217, e.g. 'INR'.
  final String code;

  final String symbol;
  final String name;
  final String flag;

  /// Locale that supplies the digit grouping. Almost everything uses
  /// 'en_US' (1,689) — deliberately, after "1.689 €" was read as one euro
  /// — but India groups by lakh ('en_IN' → ₹1,00,000), and writing
  /// ₹100,000 to an Indian teen would look as foreign as 1.689 did.
  final String locale;

  /// Very rough EUR value of one unit, used for exactly two things,
  /// neither of them display: the opt-in world counter (whose total is
  /// labelled self-reported and approximate) and the "is this burn worth
  /// more than Pro" threshold in pro_moment.dart. Never shown to the
  /// user as a conversion.
  final double eurosPerUnit;
}

/// Ordered by who the app is for: the launch markets first (US, India,
/// Europe), then the rest of the world's majors.
const currencies = <Currency>[
  Currency(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    flag: '🇺🇸',
    locale: 'en_US',
    eurosPerUnit: 0.86,
  ),
  Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    flag: '🇮🇳',
    locale: 'en_IN',
    eurosPerUnit: 0.0098,
  ),
  Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    flag: '🇪🇺',
    locale: 'en_US',
    eurosPerUnit: 1,
  ),
  Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    flag: '🇬🇧',
    locale: 'en_US',
    eurosPerUnit: 1.17,
  ),
  Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    flag: '🇯🇵',
    locale: 'en_US',
    eurosPerUnit: 0.0058,
  ),
  Currency(
    code: 'CHF',
    symbol: 'CHF ',
    name: 'Swiss Franc',
    flag: '🇨🇭',
    locale: 'en_US',
    eurosPerUnit: 1.07,
  ),
  Currency(
    code: 'SEK',
    symbol: 'kr ',
    name: 'Swedish Krona',
    flag: '🇸🇪',
    locale: 'en_US',
    eurosPerUnit: 0.090,
  ),
  Currency(
    code: 'NOK',
    symbol: 'kr ',
    name: 'Norwegian Krone',
    flag: '🇳🇴',
    locale: 'en_US',
    eurosPerUnit: 0.085,
  ),
  Currency(
    code: 'DKK',
    symbol: 'kr ',
    name: 'Danish Krone',
    flag: '🇩🇰',
    locale: 'en_US',
    eurosPerUnit: 0.134,
  ),
  Currency(
    code: 'PLN',
    symbol: 'zł ',
    name: 'Polish Złoty',
    flag: '🇵🇱',
    locale: 'en_US',
    eurosPerUnit: 0.235,
  ),
  Currency(
    code: 'CZK',
    symbol: 'Kč ',
    name: 'Czech Koruna',
    flag: '🇨🇿',
    locale: 'en_US',
    eurosPerUnit: 0.041,
  ),
  Currency(
    code: 'CAD',
    symbol: r'CA$',
    name: 'Canadian Dollar',
    flag: '🇨🇦',
    locale: 'en_US',
    eurosPerUnit: 0.63,
  ),
  Currency(
    code: 'AUD',
    symbol: r'A$',
    name: 'Australian Dollar',
    flag: '🇦🇺',
    locale: 'en_US',
    eurosPerUnit: 0.57,
  ),
  Currency(
    code: 'SGD',
    symbol: r'S$',
    name: 'Singapore Dollar',
    flag: '🇸🇬',
    locale: 'en_US',
    eurosPerUnit: 0.67,
  ),
  Currency(
    code: 'AED',
    symbol: 'AED ',
    name: 'UAE Dirham',
    flag: '🇦🇪',
    locale: 'en_US',
    eurosPerUnit: 0.235,
  ),
  Currency(
    code: 'BRL',
    symbol: r'R$',
    name: 'Brazilian Real',
    flag: '🇧🇷',
    locale: 'en_US',
    eurosPerUnit: 0.16,
  ),
  Currency(
    code: 'MXN',
    symbol: r'MX$',
    name: 'Mexican Peso',
    flag: '🇲🇽',
    locale: 'en_US',
    eurosPerUnit: 0.046,
  ),
  Currency(
    code: 'KRW',
    symbol: '₩',
    name: 'South Korean Won',
    flag: '🇰🇷',
    locale: 'en_US',
    eurosPerUnit: 0.00063,
  ),
];

/// Null for unknown codes so a stale pref can't crash startup.
Currency? currencyByCode(String? code) {
  for (final c in currencies) {
    if (c.code == code) return c;
  }
  return null;
}

/// Countries that pay in euros, for locale detection.
const _eurozone = {
  'AT',
  'BE',
  'CY',
  'DE',
  'EE',
  'ES',
  'FI',
  'FR',
  'GR',
  'HR',
  'IE',
  'IT',
  'LT',
  'LU',
  'LV',
  'MT',
  'NL',
  'PT',
  'SI',
  'SK',
};

const _regionToCurrency = {
  'US': 'USD',
  'IN': 'INR',
  'GB': 'GBP',
  'JP': 'JPY',
  'CH': 'CHF',
  'LI': 'CHF',
  'SE': 'SEK',
  'NO': 'NOK',
  'DK': 'DKK',
  'PL': 'PLN',
  'CZ': 'CZK',
  'CA': 'CAD',
  'AU': 'AUD',
  'NZ': 'AUD',
  'SG': 'SGD',
  'AE': 'AED',
  'BR': 'BRL',
  'MX': 'MXN',
  'KR': 'KRW',
};

/// Best guess from the device locale (e.g. `en_IN` → INR). Only ever a
/// pre-selection — setup shows it and asks; it is never silently final.
Currency detectCurrency([String? localeName]) {
  final name = localeName ?? Platform.localeName;
  // 'en_IN', 'en-IN' or 'hi_IN@calendar=...' — the region is the first
  // two-letter uppercase chunk after the language.
  final match = RegExp(r'[_-]([A-Z]{2})').firstMatch(name);
  final region = match?.group(1);
  if (region == null) return currencyByCode('USD')!;
  if (_eurozone.contains(region)) return currencyByCode('EUR')!;
  return currencyByCode(_regionToCurrency[region]) ?? currencyByCode('USD')!;
}
