import 'package:drift/drift.dart';

import 'encrypted_db.dart';

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

  /// When the user confirmed they actually moved this money somewhere it
  /// can't be spent. Without this the app's headline number is a claim
  /// nobody's bank balance agrees with: resisting a €150 purchase doesn't
  /// protect €150 if it leaves on something else by Friday. Resisted and
  /// genuinely saved are different facts, so they're stored separately.
  DateTimeColumn get movedAt => dateTime().nullable()();

  /// When the user admitted they bought it in the end. The honest
  /// counterweight to a total that otherwise only ever goes up — a burn
  /// isn't a saving until the craving stays dead.
  DateTimeColumn get boughtAt => dateTime().nullable()();

  /// "Not now": the desire is parked until this moment, and a
  /// notification brings it back. The 24-hour rule is the best-evidenced
  /// intervention against impulse buying, and the app previously only
  /// offered forever.
  DateTimeColumn get parkedUntil => dateTime().nullable()();

  /// The purchase-interview answers, as JSON (see data/reflection.dart).
  /// Kept so a re-burn can show the user their own words from last time
  /// — "you said you'd wear it once" lands harder than any message we
  /// could write.
  TextColumn get reflectionJson => text().nullable()();
}

@DriftDatabase(tables: [Items])
class AppDatabase extends _$AppDatabase {
  /// Encrypted at rest with a key that lives only in the iOS Keychain
  /// (PROJECT.md §5). Without that key the file is ciphertext.
  AppDatabase() : super(openEncryptedDatabase());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(items, items.destroyedAt);
      if (from < 3) await m.addColumn(items, items.reflectionJson);
      if (from < 4) {
        await m.addColumn(items, items.movedAt);
        await m.addColumn(items, items.boughtAt);
        await m.addColumn(items, items.parkedUntil);
      }
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
    String? reflectionJson,
  }) {
    final now = DateTime.now();
    return into(items).insert(
      ItemsCompanion.insert(
        imageFile: imageFile,
        priceCents: priceCents,
        category: Value(category),
        monthlyCents: Value(monthlyCents),
        months: Value(months),
        resistanceCount: const Value(1),
        createdAt: now,
        lastBurnedAt: Value(now),
        reflectionJson: Value(reflectionJson),
      ),
    );
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

  /// The user moved the money for real (or took it back). Only a burned
  /// item can be marked moved, so the toggle can't invent savings.
  Future<void> setMoved(int id, {required bool moved}) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(movedAt: Value(moved ? DateTime.now() : null)),
    );
  }

  /// The follow-up answer: they bought it in the end. Keeps the row —
  /// deleting it would quietly restore the total it should be reducing.
  Future<void> markBought(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        boughtAt: Value(DateTime.now()),
        movedAt: const Value(null),
      ),
    );
  }

  /// "No, I didn't buy it." Nothing to record but the fact we asked, so
  /// the fourteen-day clock restarts instead of firing again tomorrow.
  Future<void> recordFollowUpResisted(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(lastBurnedAt: Value(DateTime.now())),
    );
  }

  /// They resisted after all: clear the confession and let it count again.
  Future<void> markNotBought(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      const ItemsCompanion(boughtAt: Value(null)),
    );
  }

  /// Park a desire until [until] instead of burning it now.
  Future<void> park(int id, DateTime until) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(parkedUntil: Value(until)),
    );
  }

  Future<void> unpark(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      const ItemsCompanion(parkedUntil: Value(null)),
    );
  }

  /// "Erase everything" from settings: wipe the ledger completely.
  Future<void> deleteAllItems() => delete(items).go();

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
