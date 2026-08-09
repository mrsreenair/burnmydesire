import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/currencies.dart';
import '../data/user_prefs.dart';
import '../utils/format_utils.dart';

/// The active display currency. The single writer of the format_utils
/// global: main() seeds the global before runApp, this notifier mirrors
/// it, and screens watch here so a change in Settings rebuilds them.
class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() => activeCurrency;

  Future<void> change(Currency c) async {
    setActiveCurrency(c);
    state = c;
    await saveCurrencyCode(c.code);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(
  CurrencyNotifier.new,
);
