import 'package:intl/intl.dart';

import '../data/currencies.dart';

/// The currency every amount is written in. A plain module global, not a
/// provider, because formatting happens in pure code too (milestone
/// cards, canvas painting) where no ref exists. Set once at startup and
/// again on the rare occasion the user changes it in Settings — the
/// currency provider is the only writer.
Currency _active = currencies.first;
NumberFormat _format = _formatterFor(currencies.first);

NumberFormat _formatterFor(Currency c) =>
    NumberFormat.currency(locale: c.locale, symbol: c.symbol, decimalDigits: 0);

Currency get activeCurrency => _active;

void setActiveCurrency(Currency c) {
  _active = c;
  _format = _formatterFor(c);
}

/// Formats integer minor units in the active currency, whole units only:
/// 168900 → "€1,689", or "₹1,689" — and Indian grouping where it applies,
/// 10000000 → "₹1,00,000". (Never "1.689", which reads as one euro.)
String formatMoney(int cents) => _format.format(cents / 100);

/// The world counter aggregates in euros whatever the phone's currency
/// is, so its public total is always written as euros — showing it with
/// the local symbol would claim a conversion that never happened.
final NumberFormat _euroFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '€',
  decimalDigits: 0,
);

String formatWorldEuros(int cents) => _euroFormat.format(cents / 100);

/// Parses user price input into minor units ("cents"), accepting both
/// decimal styles: "800", "799.99", "799,99", "1,299", "1.299",
/// "1,299.50", "1.299,50" — and Indian grouping, "1,00,000". Returns null
/// when the input isn't a positive amount.
int? parseMoneyToCents(String input) {
  // Strip currency symbols, codes, spaces — any of them, not just the
  // active currency's, because people type what the price tag shows.
  // Digits, separators and the sign carry meaning; the minus survives so
  // "-50" is rejected below rather than silently read as 50.
  final s = input.replaceAll(RegExp(r'[^\d.,-]'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  final String normalized;
  if (lastComma >= 0 && lastDot >= 0) {
    // Both present: the later separator is the decimal point.
    normalized = lastComma > lastDot
        ? s.replaceAll('.', '').replaceAll(',', '.')
        : s.replaceAll(',', '');
  } else if (lastComma >= 0) {
    normalized = _resolveSingleSeparator(s, ',');
  } else if (lastDot >= 0) {
    normalized = _resolveSingleSeparator(s, '.');
  } else {
    normalized = s;
  }
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

/// One separator type only: it's a decimal point when it appears once with
/// 1-2 digits after ("799,99"); otherwise it groups thousands ("1.299",
/// "1,00,000").
String _resolveSingleSeparator(String s, String sep) {
  final first = s.indexOf(sep);
  final last = s.lastIndexOf(sep);
  final digitsAfter = s.length - last - 1;
  final isDecimal = first == last && digitsAfter >= 1 && digitsAfter <= 2;
  return isDecimal ? s.replaceAll(sep, '.') : s.replaceAll(sep, '');
}
