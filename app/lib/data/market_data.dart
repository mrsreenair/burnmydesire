import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

/// Real historical fund data: monthly adjusted closes (dividends included).
/// Shipped as a bundled asset and refreshed from the network when possible,
/// so shock numbers are actual market history — never made-up rates.
class FundSeries {
  const FundSeries({
    required this.id,
    required this.name,
    required this.ticker,
    required this.currency,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    required this.monthly,
  });

  final String id;
  final String name;
  final String ticker;
  final String currency;
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;
  final List<double> monthly;

  factory FundSeries.fromJson(Map<String, dynamic> json) {
    final start = (json['start'] as String).split('-');
    final end = (json['end'] as String).split('-');
    return FundSeries(
      id: json['id'] as String,
      name: json['name'] as String,
      ticker: json['ticker'] as String,
      currency: json['currency'] as String,
      startYear: int.parse(start[0]),
      startMonth: int.parse(start[1]),
      endYear: int.parse(end[0]),
      endMonth: int.parse(end[1]),
      monthly: [for (final v in json['monthly'] as List) (v as num).toDouble()],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ticker': ticker,
    'currency': currency,
    'start': '$startYear-${startMonth.toString().padLeft(2, '0')}',
    'end': '$endYear-${endMonth.toString().padLeft(2, '0')}',
    'monthly': monthly,
  };

  /// Whole years of history available.
  int get yearsAvailable => (monthly.length - 1) ~/ 12;

  /// Growth multiple over the trailing [years] (clamped to available
  /// history): latest price / price [years] ago.
  double multipleOverYears(int years) {
    final span = math.min(years, yearsAvailable);
    return monthly.last / monthly[monthly.length - 1 - span * 12];
  }

  /// Calendar year the trailing-[years] window starts in.
  int investmentYear(int years) {
    final span = math.min(years, yearsAvailable);
    final monthsBack = span * 12;
    final absMonth = (endYear * 12 + endMonth - 1) - monthsBack;
    return absMonth ~/ 12;
  }

  /// What [cents] invested [years] ago would be worth today — real history,
  /// clamped to the fund's available span.
  int valueTodayCents(int cents, int years) =>
      (cents * multipleOverYears(years)).round();

  /// Annualized return actually realized over the trailing [years].
  double realizedCagr(int years) {
    final span = math.min(years, yearsAvailable);
    return math.pow(multipleOverYears(years), 1 / span).toDouble() - 1.0;
  }

  /// True when the fund's history covers the full [years] horizon.
  bool covers(int years) => yearsAvailable >= years;

  /// Annualized return over the fund's entire available history — the
  /// long-run average used for forward projections.
  double get fullHistoryCagr => realizedCagr(yearsAvailable);

  /// Forward projection: what [cents] invested today could become in
  /// [yearsAhead] years IF the fund repeats its full-history average.
  int projectedValueCents(int cents, int yearsAhead) =>
      (cents * math.pow(1 + fullHistoryCagr, yearsAhead)).round();
}

class MarketData {
  const MarketData({required this.generated, required this.funds});

  /// ISO date (yyyy-MM-dd) the dataset was produced.
  final String generated;
  final List<FundSeries> funds;

  factory MarketData.fromJson(Map<String, dynamic> json) => MarketData(
    generated: json['generated'] as String,
    funds: [
      for (final f in json['funds'] as List)
        FundSeries.fromJson(f as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'generated': generated,
    'funds': [for (final f in funds) f.toJson()],
  };

  /// Human label like "Aug 2026" for "data as of".
  String get asOfLabel {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final f = funds.first;
    return '${names[f.endMonth - 1]} ${f.endYear}';
  }
}

const _kAssetPath = 'assets/data/market_returns.json';
const _kCacheFile = 'market_cache.json';
const _kRefreshAfter = Duration(days: 30);

/// Yahoo Finance chart endpoint (free, no key). Used only to refresh public
/// price history — no user data is ever sent.
Uri _chartUri(String ticker) => Uri.https(
  'query1.finance.yahoo.com',
  '/v8/finance/chart/$ticker',
  {'range': '35y', 'interval': '1mo'},
);

class MarketDataStore {
  MarketDataStore(this.documentsPath);

  final String documentsPath;

  File get _cache => File(p.join(documentsPath, _kCacheFile));

  /// Bundled data, or the cached network refresh when it's newer.
  Future<MarketData> load() async {
    final bundled = MarketData.fromJson(
      jsonDecode(await rootBundle.loadString(_kAssetPath))
          as Map<String, dynamic>,
    );
    try {
      if (await _cache.exists()) {
        final cached = MarketData.fromJson(
          jsonDecode(await _cache.readAsString()) as Map<String, dynamic>,
        );
        if (cached.generated.compareTo(bundled.generated) > 0 &&
            cached.funds.length >= bundled.funds.length) {
          return cached;
        }
      }
    } on FormatException {
      // Corrupt cache — fall back to bundled data.
    }
    return bundled;
  }

  /// Refreshes the cache from the network when it's older than
  /// [_kRefreshAfter]. Failures are silent: the bundled data always works.
  Future<void> refreshIfStale(MarketData current) async {
    final today = DateTime.now();
    final generated = DateTime.tryParse(current.generated);
    if (generated != null && today.difference(generated) < _kRefreshAfter) {
      return;
    }
    final client = HttpClient();
    try {
      final refreshed = <FundSeries>[];
      for (final fund in current.funds) {
        final request = await client.getUrl(_chartUri(fund.ticker));
        request.headers.set(HttpHeaders.userAgentHeader, 'BurnMyDesire/1.0');
        final response = await request.close();
        if (response.statusCode != 200) return;
        final body = await response.transform(utf8.decoder).join();
        final parsed = _parseChart(body, fund);
        if (parsed == null) return;
        refreshed.add(parsed);
      }
      final data = MarketData(
        generated: today.toIso8601String().substring(0, 10),
        funds: refreshed,
      );
      await _cache.writeAsString(jsonEncode(data.toJson()));
    } on IOException {
      // Offline or blocked — bundled data keeps working.
    } finally {
      client.close();
    }
  }

  /// Parses a Yahoo chart response into a [FundSeries], keeping the fund's
  /// display metadata. Returns null on any unexpected shape.
  FundSeries? _parseChart(String body, FundSeries meta) {
    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final result = ((root['chart'] as Map)['result'] as List).first as Map;
      final timestamps = (result['timestamp'] as List).cast<int>();
      final adjclose =
          (((result['indicators'] as Map)['adjclose'] as List).first
                  as Map)['adjclose']
              as List;
      final series = <double>[];
      DateTime? first;
      DateTime? last;
      double? prev;
      for (var i = 0; i < timestamps.length; i++) {
        final raw = adjclose[i];
        final value = raw is num ? raw.toDouble() : prev;
        if (value == null) continue;
        prev = value;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);
        first ??= date;
        last = date;
        series.add(value);
      }
      if (series.length < 24 || first == null || last == null) return null;
      return FundSeries(
        id: meta.id,
        name: meta.name,
        ticker: meta.ticker,
        currency: meta.currency,
        startYear: first.year,
        startMonth: first.month,
        endYear: last.year,
        endMonth: last.month,
        monthly: series,
      );
    } on Object {
      return null;
    }
  }
}
