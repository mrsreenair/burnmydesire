import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/image_store.dart';
import '../data/market_data.dart';
import '../data/user_prefs.dart';

/// Overridden in main() with the real documents path.
final imageStoreProvider = Provider<ImageStore>(
  (ref) => throw UnimplementedError('overridden in main'),
);

/// Real market history (bundled asset, network-refreshed monthly). Kicks
/// off a silent background refresh after the first load.
final marketDataProvider = FutureProvider<MarketData>((ref) async {
  final store =
      MarketDataStore(ref.watch(imageStoreProvider).documentsPath);
  final data = await store.load();
  store.refreshIfStale(data).ignore();
  return data;
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
final liveItemsProvider = Provider<List<Item>>((ref) =>
    (ref.watch(itemsProvider).value ?? const <Item>[])
        .where((i) => i.destroyedAt == null)
        .toList());

/// Desires ended forever by a final burn. Tombstones only: price, dates,
/// streak — no image. Feeds the dashboard "Ashes" section.
final destroyedItemsProvider = Provider<List<Item>>((ref) =>
    (ref.watch(itemsProvider).value ?? const <Item>[])
        .where((i) => i.destroyedAt != null)
        .toList());

/// Total wealth protected: each unique item counted once, no matter how
/// often it was re-burned (PROJECT.md F4).
final protectedCentsProvider = Provider<int>((ref) {
  final items = ref.watch(itemsProvider).value ?? const [];
  return items.fold(0, (sum, item) => sum + item.priceCents);
});

/// The spending weaknesses picked during setup (labels from
/// [spendCategories]).
final spendCategoriesProvider =
    FutureProvider<List<String>>((ref) => savedSpendCategories());

/// The burn goals picked during setup (ids from [burnGoals]).
final burnGoalsProvider =
    FutureProvider<List<String>>((ref) => savedBurnGoals());
