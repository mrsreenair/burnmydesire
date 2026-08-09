import 'dart:convert';

import 'package:burn_my_desire/data/market_data.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// A synthetic fund that doubles every 12 months: 25 monthly points
/// spanning Jan 2024 – Jan 2026, 100 -> 200 -> 400.
FundSeries doublingFund() {
  final monthly = [
    for (var i = 0; i <= 24; i++) 100.0 * (1 << (i ~/ 12)) * _within(i % 12)
  ];
  return FundSeries(
    id: 'test',
    name: 'Test Fund',
    ticker: 'TST',
    currency: 'EUR',
    startYear: 2024,
    startMonth: 1,
    endYear: 2026,
    endMonth: 1,
    monthly: monthly,
  );
}

// Linear-ish drift inside the year; exact at month 0.
double _within(int m) => 1.0 + m * 0.05;

void main() {
  group('FundSeries math', () {
    test('multiple over one year uses 12-month spacing', () {
      final fund = doublingFund();
      // Last point: month 24 = 400.0; 12 months earlier: month 12 = 200.0.
      expect(fund.multipleOverYears(1), closeTo(2.0, 1e-9));
      expect(fund.multipleOverYears(2), closeTo(4.0, 1e-9));
    });

    test('value today applies the real multiple to cents', () {
      final fund = doublingFund();
      expect(fund.valueTodayCents(80000, 2), 320000);
    });

    test('realized CAGR of a doubling fund is 100%', () {
      final fund = doublingFund();
      expect(fund.realizedCagr(1), closeTo(1.0, 1e-9));
      expect(fund.realizedCagr(2), closeTo(1.0, 1e-9));
    });

    test('horizon beyond history clamps to available span', () {
      final fund = doublingFund();
      expect(fund.yearsAvailable, 2);
      expect(fund.covers(2), isTrue);
      expect(fund.covers(10), isFalse);
      // 10y request clamps to the full 2y history.
      expect(fund.multipleOverYears(10), closeTo(4.0, 1e-9));
      expect(fund.realizedCagr(10), closeTo(1.0, 1e-9));
    });

    test('investment year reflects the clamped window start', () {
      final fund = doublingFund();
      expect(fund.investmentYear(1), 2025);
      expect(fund.investmentYear(10), 2024);
    });

    test('full-history CAGR of a doubling fund is 100%', () {
      expect(doublingFund().fullHistoryCagr, closeTo(1.0, 1e-9));
    });

    test('forward projection compounds the full-history average', () {
      final fund = doublingFund();
      // €800 at 100%/yr: 3 years ahead -> €6,400.
      expect(fund.projectedValueCents(80000, 3), 640000);
      // Projection horizon may exceed available history — it's a forecast.
      expect(fund.projectedValueCents(80000, 5), 2560000);
    });
  });

  group('serialization', () {
    test('round-trips through json', () {
      final fund = doublingFund();
      final data = MarketData(generated: '2026-08-08', funds: [fund]);
      final back = MarketData.fromJson(
          jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
      expect(back.generated, '2026-08-08');
      expect(back.funds.single.ticker, 'TST');
      expect(back.funds.single.monthly, fund.monthly);
      expect(back.funds.single.endMonth, 1);
    });

    test('asOf label is readable', () {
      final data = MarketData(generated: '2026-08-08', funds: [doublingFund()]);
      expect(data.asOfLabel, 'Jan 2026');
    });
  });

  group('bundled asset', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('parses and contains every launch market with sane history',
        () async {
      final data = MarketData.fromJson(jsonDecode(
              await rootBundleLoadString('assets/data/market_returns.json'))
          as Map<String, dynamic>);
      expect(
          data.funds.map((f) => f.name),
          containsAll([
            'S&P 500', 'NASDAQ-100', 'MSCI World',
            'Nifty 50', 'FTSE 100', 'DAX',
            'Apple', 'Microsoft', 'Google', 'Amazon', 'Nvidia', 'Tesla',
            'Reliance', 'TCS',
          ]));
      for (final fund in data.funds) {
        expect(fund.yearsAvailable, greaterThanOrEqualTo(10),
            reason: '${fund.name} needs at least a decade of history');
        expect(fund.monthly.every((p) => p > 0), isTrue);
        // Long-run equity multiples should be growth, not noise. The
        // FTSE is the honest laggard of the set, hence the low bar.
        expect(fund.multipleOverYears(10), greaterThan(1.2),
            reason: fund.name);
        // Full-history averages should be sane annual percentages.
        expect(fund.fullHistoryCagr, inExclusiveRange(0.02, 0.60),
            reason: fund.name);
      }
    });

    test('funds are matched to the market someone actually lives in',
        () async {
      final data = MarketData.fromJson(jsonDecode(
              await rootBundleLoadString('assets/data/market_returns.json'))
          as Map<String, dynamic>);

      // An Indian teen opens on the Nifty, an index — never on a
      // hand-picked winner stock.
      final inr = data.fundsFor('INR');
      expect(inr.first.id, 'nifty');
      expect(inr.map((f) => f.id),
          containsAll(['nifty', 'world', 'sp500', 'reliance', 'tcs']));
      // Their own companies come before the US household names.
      expect(inr.indexWhere((f) => f.id == 'reliance'),
          lessThan(inr.indexWhere((f) => f.id == 'aapl')));
      // A foreign local index is noise: no DAX in Delhi.
      expect(inr.map((f) => f.id), isNot(contains('dax')));

      final usd = data.fundsFor('USD');
      expect(usd.first.id, 'sp500');
      expect(usd.map((f) => f.id), isNot(contains('nifty')));

      final eur = data.fundsFor('EUR');
      expect(eur.map((f) => f.id), containsAll(['world', 'dax', 'sp500']));
      expect(eur.map((f) => f.id), isNot(contains('ftse')));

      final gbp = data.fundsFor('GBP');
      expect(gbp.first.id, 'ftse');

      // No local market at all: the world index leads, and every fund
      // is still an index or a global household name.
      final jpy = data.fundsFor('JPY');
      expect(jpy.first.id, 'world');
      expect(jpy, isNotEmpty);
      expect(jpy.map((f) => f.id), isNot(contains('reliance')));
    });
  });
}

Future<String> rootBundleLoadString(String key) =>
    TestWidgetsFlutterBinding.instance.runAsync(() =>
        rootBundle.loadString(key)).then((v) => v!);
