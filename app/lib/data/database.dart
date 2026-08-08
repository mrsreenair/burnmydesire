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
}

@DriftDatabase(tables: [Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'burn_my_desire'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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
}
