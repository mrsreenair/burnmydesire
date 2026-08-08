import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// One temptation the user has burned. `category` is stored from day one so
/// v2's habit/emotion modes need no migration (PROJECT.md §4.4).
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imageFile => text()();
  IntColumn get priceCents => integer()();
  TextColumn get category => text().withDefault(const Constant('purchase'))();
  IntColumn get monthlyCents => integer().nullable()();
  IntColumn get months => integer().nullable()();
  IntColumn get resistanceCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastBurnedAt => dateTime().nullable()();

  /// Set when the item was final-burned. A destroyed item is a tombstone:
  /// the photo is deleted from disk (the craving trigger dies) but the row
  /// survives so "wealth protected" totals stay honest forever.
  DateTimeColumn get destroyedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'burn_my_desire'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(items, items.destroyedAt);
        },
      );

  Stream<List<Item>> watchItems() {
    final query = select(items)
      ..orderBy([
        (t) => OrderingTerm.desc(t.lastBurnedAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch();
  }

  /// First burn of a new temptation.
  Future<int> insertBurnedItem({
    required String imageFile,
    required int priceCents,
    int? monthlyCents,
    int? months,
    String category = 'purchase',
  }) {
    final now = DateTime.now();
    return into(items).insert(ItemsCompanion.insert(
      imageFile: imageFile,
      priceCents: priceCents,
      category: Value(category),
      monthlyCents: Value(monthlyCents),
      months: Value(months),
      resistanceCount: const Value(1),
      createdAt: now,
      lastBurnedAt: Value(now),
    ));
  }

  /// The urge came back and the user burned it again.
  Future<void> recordReBurn(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion.custom(
        resistanceCount: items.resistanceCount + const Constant(1),
        lastBurnedAt: Variable(DateTime.now()),
      ),
    );
  }

  Future<Item> getItem(int id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingle();

  /// The final burn: tombstone the row. The caller deletes the image file
  /// first (it needs the file name); this clears the reference and stamps
  /// the death date. Price and streak stay — the ledger survives the fire.
  Future<void> markDestroyed(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        destroyedAt: Value(DateTime.now()),
        imageFile: const Value(''),
      ),
    );
  }
}
