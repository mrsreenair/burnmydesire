import 'package:intl/intl.dart';

final NumberFormat _euros = NumberFormat.currency(
  locale: 'en_US',
  symbol: '€',
  decimalDigits: 0,
);

/// Formats integer cents as whole euros with comma thousands separators,
/// e.g. 168900 -> "€1,689" (never "1.689", which reads as one euro).
String formatEuros(int cents) => _euros.format(cents / 100);

/// Parses user price input into cents, accepting both decimal styles:
/// "800", "799.99", "799,99", "1,299", "1.299", "1,299.50", "1.299,50".
/// Returns null when the input isn't a positive amount.
int? parseEurosToCents(String input) {
  final s = input.trim().replaceAll('€', '').replaceAll(' ', '');
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
/// 1-2 digits after ("799,99"); otherwise it groups thousands ("1.299").
String _resolveSingleSeparator(String s, String sep) {
  final first = s.indexOf(sep);
  final last = s.lastIndexOf(sep);
  final digitsAfter = s.length - last - 1;
  final isDecimal = first == last && digitsAfter >= 1 && digitsAfter <= 2;
  return isDecimal ? s.replaceAll(sep, '.') : s.replaceAll(sep, '');
}
