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

  /// When the user last answered a follow-up with "still resisted".
  /// Two questions per burn (3 days, then 14 — GROWTH.md M5); this is
  /// how the second knows the first was answered, and how a re-burn
  /// (which moves [lastBurnedAt] past it) starts the pair again.
  DateTimeColumn get followUpAt => dateTime().nullable()();

  /// The purchase-interview answers, as JSON (see data/reflection.dart).
  /// Kept so a re-burn can show the user their own words from last time
  /// — "you said you'd wear it once" lands harder than any message we
  /// could write.
  TextColumn get reflectionJson => text().nullable()();
}

/// One burn, as an event. `Items` keeps only the latest (`lastBurnedAt`)
/// and a count, which is enough for streaks but not for "what happened
/// this week" — the weekly Ash Report (GROWTH.md M4) needs every burn
/// with its date. The price is snapshotted so a later edit or a bought
/// confession can't rewrite history: the report says what was true.
class Burns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id)();
  DateTimeColumn get at => dateTime()();
  IntColumn get priceCents => integer()();
  TextColumn get category => text().withDefault(const Constant('purchase'))();
}

@DriftDatabase(tables: [Items, Burns])
class AppDatabase extends _$AppDatabase {
  /// Encrypted at rest with a key that lives only in the iOS Keychain
  /// (PROJECT.md §5). Without that key the file is ciphertext.
  AppDatabase() : super(openEncryptedDatabase());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

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
      if (from < 5) {
        await m.createTable(burns);
        // Existing users get one event per item, dated at its last
        // burn — the most recent thing we know for sure. Their first
        // report is a little thin rather than empty.
        await backfillBurns();
      }
      if (from < 6) await m.addColumn(items, items.followUpAt);
    },
  );

  /// One burn row per item that has none, dated at its last burn (or
  /// creation). Used by the v5 migration and by restore-from-backup,
  /// which recreates items without their event history.
  Future<void> backfillBurns() => customStatement(
    'INSERT INTO burns (item_id, at, price_cents, category) '
    'SELECT id, COALESCE(last_burned_at, created_at), price_cents, category '
    'FROM items WHERE id NOT IN (SELECT item_id FROM burns)',
  );

  /// Every burn since [since], newest first.
  Stream<List<Burn>> watchBurnsSince(DateTime since) {
    final query = select(burns)
      ..where((t) => t.at.isBiggerOrEqualValue(since))
      ..orderBy([(t) => OrderingTerm.desc(t.at)]);
    return query.watch();
  }

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
    return transaction(() async {
      final id = await into(items).insert(
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
      await _recordBurn(id, now, priceCents, category);
      return id;
    });
  }

  /// The urge came back and the user burned it again.
  Future<void> recordReBurn(int id) {
    final now = DateTime.now();
    return transaction(() async {
      await (update(items)..where((t) => t.id.equals(id))).write(
        ItemsCompanion.custom(
          resistanceCount: items.resistanceCount + const Constant(1),
          lastBurnedAt: Variable(now),
        ),
      );
      final item = await getItem(id);
      await _recordBurn(id, now, item.priceCents, item.category);
    });
  }

  Future<void> _recordBurn(int itemId, DateTime at, int cents, String cat) =>
      into(burns).insert(
        BurnsCompanion.insert(
          itemId: itemId,
          at: at,
          priceCents: cents,
          category: Value(cat),
        ),
      );

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

  /// "No, I didn't buy it." Stamps the answer so the next stage (or
  /// silence) follows. Deliberately no longer touches [lastBurnedAt]:
  /// re-stamping the burn to restart a clock also moved streaks and
  /// the weekly report, and an answer isn't a burn.
  Future<void> recordFollowUpResisted(int id) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(followUpAt: Value(DateTime.now())),
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
  Future<void> deleteAllItems() => transaction(() async {
    await delete(burns).go();
    await delete(items).go();
  });

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
