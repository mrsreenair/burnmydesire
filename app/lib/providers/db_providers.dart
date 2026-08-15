import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/image_store.dart';
import '../data/market_data.dart';
import '../data/user_prefs.dart';
import 'currency_provider.dart';

/// Overridden in main() with the real documents path.
final imageStoreProvider = Provider<ImageStore>(
  (ref) => throw UnimplementedError('overridden in main'),
);

/// Real market history (bundled asset, network-refreshed monthly). Kicks
/// off a silent background refresh after the first load.
final marketDataProvider = FutureProvider<MarketData>((ref) async {
  final store = MarketDataStore(ref.watch(imageStoreProvider).documentsPath);
  final data = await store.load();
  store.refreshIfStale(data).ignore();
  return data;
});

/// The funds the user should actually see, matched to their currency:
/// their market's indices first, so the default projection is always a
/// local index, never a hand-picked winner stock.
final relevantFundsProvider = Provider<List<FundSeries>>((ref) {
  final market = ref.watch(marketDataProvider).value;
  final currency = ref.watch(currencyProvider);
  return market?.fundsFor(currency.code) ?? const [];
});

/// The one fund used where there's no picker: dashboards and victory
/// lines. Null while market data is still loading.
final defaultFundProvider = Provider<FundSeries?>((ref) {
  final funds = ref.watch(relevantFundsProvider);
  return funds.isEmpty ? null : funds.first;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(databaseProvider).watchItems(),
);

/// Temptations still in the fight — what home shows. Destroyed items
/// vanish from sight (their photo is gone; a visible item is a cue).
final liveItemsProvider = Provider<List<Item>>(
  (ref) => (ref.watch(itemsProvider).value ?? const <Item>[])
      .where((i) => i.destroyedAt == null)
      .toList(),
);

/// Desires ended forever by a final burn. Tombstones only: price, dates,
/// streak — no image. Feeds the dashboard "Ashes" section.
final destroyedItemsProvider = Provider<List<Item>>(
  (ref) => (ref.watch(itemsProvider).value ?? const <Item>[])
      .where((i) => i.destroyedAt != null)
      .toList(),
);

/// Now, as a provider so tests can freeze the calendar.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Desires captured this calendar month — including destroyed ones,
/// whose rows survive as tombstones, so a final burn can't be farmed to
/// refill the month's allowance.
final newItemsThisMonthProvider = Provider<int>((ref) {
  final now = ref.watch(nowProvider);
  final items = ref.watch(itemsProvider).value ?? const <Item>[];
  return items
      .where(
        (i) => i.createdAt.year == now.year && i.createdAt.month == now.month,
      )
      .length;
});

/// Total wealth protected: each unique item counted once, no matter how
/// often it was re-burned (PROJECT.md F4).
final protectedCentsProvider = Provider<int>((ref) {
  final items = ref.watch(itemsProvider).value ?? const [];
  return items.fold(0, (sum, item) => sum + item.priceCents);
});

/// Thoughts burned: items with no price, counted once each however often
/// they were re-burned. The world counter's second number.
final thoughtsBurnedProvider = Provider<int>((ref) {
  final items = ref.watch(itemsProvider).value ?? const [];
  return items.where((i) => i.category == 'emotion').length;
});

/// The spending weaknesses picked during setup (labels from
/// [spendCategories]).
final spendCategoriesProvider = FutureProvider<List<String>>(
  (ref) => savedSpendCategories(),
);

/// The burn goals picked during setup (ids from [burnGoals]).
final burnGoalsProvider = FutureProvider<List<String>>(
  (ref) => savedBurnGoals(),
);
