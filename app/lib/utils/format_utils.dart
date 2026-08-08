import 'package:intl/intl.dart';

final NumberFormat _euros = NumberFormat.currency(
  locale: 'de_DE',
  symbol: '€',
  decimalDigits: 0,
);

/// Formats integer cents as whole euros, e.g. 372877 -> "€3.729".
String formatEuros(int cents) => _euros.format(cents / 100);

/// Parses user price input ("800", "799,99", "1.299") into cents.
/// Returns null when the input isn't a positive amount.
int? parseEurosToCents(String input) {
  final normalized =
      input.trim().replaceAll('.', '').replaceAll(',', '.').replaceAll('€', '');
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}
