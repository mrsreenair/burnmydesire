import 'dart:io';
import 'dart:typed_data';

import 'package:burn_my_desire/data/backup.dart';
import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/financial_goal.dart';
import 'package:burn_my_desire/data/image_store.dart';
import 'package:burn_my_desire/data/user_prefs.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

/// Backup and restore, end to end. The test VM has plain SQLite (PRAGMA
/// key is a no-op there), so this proves the *data* round-trips; the
/// encryption of the archive is SQLCipher's and is verified on device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late ImageStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('bmd_backup');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = ImageStore(p.join(dir.path, 'a'));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('a v2 archive brings back everything the ledger knows', () async {
    // A confessed purchase, a moved one, a reflection, a re-burn, a park.
    final bought = await db.insertBurnedItem(imageFile: '', priceCents: 30000);
    await db.markBought(bought);
    final moved = await db.insertBurnedItem(
      imageFile: await store.save(Uint8List.fromList([1, 2, 3])),
      priceCents: 12000,
      reflectionJson: '[{"q":"Why?","a":"Because"}]',
    );
    await db.setMoved(moved, moved: true);
    await db.recordReBurn(moved);
    await db.park(moved, DateTime(2030));
    await db.recordFollowUpResisted(moved);
    await saveCurrencyCode('INR');
    await saveFinancialGoal(
      const FinancialGoal(name: 'A trip', emoji: '✈️', targetCents: 400000),
    );

    final file = await BackupService(db, store).export(
      passphrase: 'correct horse',
      destinationDir: dir.path,
    );

    // A second phone: fresh database, fresh prefs, different currency.
    SharedPreferences.setMockInitialValues({'currency_code': 'EUR'});
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db2.close);
    final store2 = ImageStore(p.join(dir.path, 'b'));
    final n = await BackupService(
      db2,
      store2,
    ).import(path: file.path, passphrase: 'correct horse');
    expect(n, 2);

    final items = await db2.watchItems().first;
    final b = items.firstWhere((i) => i.priceCents == 30000);
    final m = items.firstWhere((i) => i.priceCents == 12000);
    // The confession survives — so the protected total stays honest.
    expect(b.boughtAt, isNotNull);
    expect(m.movedAt, isNotNull);
    expect(m.reflectionJson, contains('Because'));
    expect(m.parkedUntil, DateTime(2030));
    expect(m.followUpAt, isNotNull);
    expect(m.resistanceCount, 2);
    expect(m.imageFile, isNotEmpty);
    // The burn log came across as events, not a back-fill: two burns
    // for the re-burned item, one for the other.
    final burns = await db2.watchBurnsSince(DateTime(1970)).first;
    expect(burns.where((x) => x.itemId == m.id), hasLength(2));
    expect(burns.where((x) => x.itemId == b.id), hasLength(1));
    // Currency and goal travelled in the meta.
    expect(await savedCurrencyCode(), 'INR');
    expect((await savedFinancialGoal())?.name, 'A trip');
  });

  test('a v1 archive (no confessions, no log) still restores', () async {
    // Hand-built in the old shape: 9 item columns, no burns table.
    final path = p.join(dir.path, 'old.bmd');
    final a = sqlite3.open(path);
    a.execute("PRAGMA key = 'x';");
    a.execute(
      'CREATE TABLE meta (format INTEGER, created_at TEXT, name TEXT, '
      'goals TEXT, categories TEXT);',
    );
    a.execute(
      'CREATE TABLE items (image_file TEXT, price_cents INTEGER, '
      'category TEXT, monthly_cents INTEGER, months INTEGER, '
      'resistance_count INTEGER, created_at INTEGER, '
      'last_burned_at INTEGER, destroyed_at INTEGER);',
    );
    a.execute('CREATE TABLE images (name TEXT, bytes BLOB);');
    a.execute("INSERT INTO meta VALUES (1, '2026-01-01', 'Sam', 'impulse_buying', '');");
    a.execute(
      "INSERT INTO items VALUES ('', 8000, 'purchase', NULL, NULL, 3, "
      '1700000000000, 1700100000000, NULL);',
    );
    a.close();

    final n = await BackupService(db, store).import(path: path, passphrase: 'x');
    expect(n, 1);
    final item = (await db.watchItems().first).single;
    expect(item.priceCents, 8000);
    expect(item.boughtAt, isNull);
    expect(item.followUpAt, isNull);
    // One back-filled burn event, dated at the last burn.
    final burns = await db.watchBurnsSince(DateTime(1970)).first;
    expect(burns, hasLength(1));
    expect(burns.single.at.millisecondsSinceEpoch, 1700100000000);
    expect(await profileName(), 'Sam');
  });

  test('a newer archive is refused rather than half-read', () async {
    final path = p.join(dir.path, 'future.bmd');
    final a = sqlite3.open(path);
    a.execute("PRAGMA key = 'x';");
    a.execute('CREATE TABLE meta (format INTEGER, created_at TEXT, name TEXT, '
        'goals TEXT, categories TEXT);');
    a.execute("INSERT INTO meta VALUES (99, '', '', '', '');");
    a.close();
    expect(
      () => BackupService(db, store).import(path: path, passphrase: 'x'),
      throwsA(isA<BackupException>()),
    );
  });
}
