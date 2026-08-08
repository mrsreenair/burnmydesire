import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/image_store.dart';

/// Overridden in main() with the real documents path.
final imageStoreProvider = Provider<ImageStore>(
  (ref) => throw UnimplementedError('overridden in main'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(databaseProvider).watchItems(),
);

/// Total wealth protected: each unique item counted once, no matter how
/// often it was re-burned (PROJECT.md F4).
final protectedCentsProvider = Provider<int>((ref) {
  final items = ref.watch(itemsProvider).value ?? const [];
  return items.fold(0, (sum, item) => sum + item.priceCents);
});
