import 'package:burn_my_desire/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Migrations run against a *real* older schema, not a fresh one.
///
/// Every other database test opens the latest schema directly, which
/// means an onUpgrade bug — the kind that bricks an existing install on
/// update — is invisible to them. This builds the v4 file by hand (the
/// last schema before the burn log), lets drift upgrade it, and checks
/// what a real user's data looks like afterwards.
void main() {
  test('a v4 database upgrades to the current schema with its data', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_file TEXT NOT NULL,
        price_cents INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'purchase',
        monthly_cents INTEGER,
        months INTEGER,
        resistance_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_burned_at INTEGER,
        destroyed_at INTEGER,
        reflection_json TEXT,
        moved_at INTEGER,
        bought_at INTEGER,
        parked_until INTEGER
      );
    ''');
    // Two items: one burned twice, one never re-burned. Seconds since
    // epoch, drift's default DateTime storage.
    raw.execute(
      "INSERT INTO items (image_file, price_cents, resistance_count, "
      "created_at, last_burned_at) VALUES ('a.jpg', 20000, 2, 1000, 5000);",
    );
    raw.execute(
      "INSERT INTO items (image_file, price_cents, resistance_count, "
      "created_at) VALUES ('b.jpg', 500, 1, 2000);",
    );
    raw.execute('PRAGMA user_version = 4;');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    // Any query opens the database and runs onUpgrade(4 → current).
    final items = await db.watchItems().first;
    expect(items, hasLength(2));

    // v5: the burn log exists and was back-filled, one event per item,
    // dated at the last burn (or creation when never re-burned).
    final burns = await db.watchBurnsSince(DateTime(1970)).first;
    expect(burns, hasLength(2));
    final byItem = {for (final b in burns) b.itemId: b};
    expect(byItem[1]!.at.millisecondsSinceEpoch ~/ 1000, 5000);
    expect(byItem[2]!.at.millisecondsSinceEpoch ~/ 1000, 2000);
    expect(byItem[1]!.priceCents, 20000);

    // v6: the follow-up column exists and is null for old rows.
    expect(items.every((i) => i.followUpAt == null), isTrue);
    await db.recordFollowUpResisted(1);
    expect((await db.getItem(1)).followUpAt, isNotNull);

    // And the app can keep writing: a new burn logs an event.
    await db.recordReBurn(2);
    expect(await db.watchBurnsSince(DateTime(1970)).first, hasLength(3));
  });
}
