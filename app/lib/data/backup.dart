import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'db_key.dart';
import 'financial_goal.dart';
import 'image_store.dart';
import 'user_prefs.dart';

/// A Burn My Desire backup is itself a SQLCipher database, encrypted with
/// a passphrase the user chooses. Nothing is uploaded: the file goes
/// wherever they send it, and only their passphrase opens it.
///
/// SQLCipher derives the key from the passphrase (PBKDF2-HMAC-SHA512), so
/// no separate key handling is needed — and a wrong passphrase simply
/// fails to open.
///
/// Format history — every reader must open every older format:
///   1  items (9 columns), images, meta(name, goals, categories)
///   2  + items.reflection_json / moved_at / bought_at / parked_until /
///        follow_up_at, + burns table, + meta.currency, + financial goal.
///      v1 archives silently lost "I bought it" confessions, so a
///      restore *inflated* the protected total; that's the bug this
///      version exists to close.
const kBackupFormatVersion = 2;

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Passphrase rules: this is the only thing standing between the file and
/// whoever finds it.
String? passphraseProblem(String passphrase) {
  if (passphrase.trim().length < 8) {
    return 'Use at least 8 characters — this is the only key to the file.';
  }
  return null;
}

class BackupService {
  BackupService(this.db, this.store);

  final AppDatabase db;
  final ImageStore store;

  /// Writes an encrypted archive and returns the file, ready to share.
  Future<File> export({
    required String passphrase,
    required String destinationDir,
  }) async {
    final problem = passphraseProblem(passphrase);
    if (problem != null) throw BackupException(problem);

    final path = p.join(destinationDir, 'burn-my-desire-backup.bmd');
    final out = File(path);
    if (out.existsSync()) out.deleteSync();

    final archive = sqlite3.open(path);
    try {
      archive.execute('PRAGMA key = ${sqlStringLiteral(passphrase)};');
      archive.execute(
        'CREATE TABLE meta (format INTEGER, created_at TEXT, name TEXT, '
        'goals TEXT, categories TEXT, currency TEXT, goal_name TEXT, '
        'goal_emoji TEXT, goal_target_cents INTEGER);',
      );
      // Items carry an archive-local id so burns can point at them; the
      // device ids are not preserved (restore re-inserts).
      archive.execute(
        'CREATE TABLE items (id INTEGER, image_file TEXT, '
        'price_cents INTEGER, category TEXT, monthly_cents INTEGER, '
        'months INTEGER, resistance_count INTEGER, created_at INTEGER, '
        'last_burned_at INTEGER, destroyed_at INTEGER, '
        'reflection_json TEXT, moved_at INTEGER, bought_at INTEGER, '
        'parked_until INTEGER, follow_up_at INTEGER);',
      );
      archive.execute(
        'CREATE TABLE burns (item_id INTEGER, at INTEGER, '
        'price_cents INTEGER, category TEXT);',
      );
      archive.execute('CREATE TABLE images (name TEXT, bytes BLOB);');

      final goal = await savedFinancialGoal();
      final meta = archive.prepare(
        'INSERT INTO meta VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      );
      meta.execute([
        kBackupFormatVersion,
        DateTime.now().toIso8601String(),
        await profileName(),
        (await savedBurnGoals()).join(','),
        (await savedSpendCategories()).join(','),
        await savedCurrencyCode(),
        goal?.name,
        goal?.emoji,
        goal?.targetCents,
      ]);
      meta.close();

      final items = await db.select(db.items).get();
      final insertItem = archive.prepare(
        'INSERT INTO items VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      );
      final insertImage = archive.prepare('INSERT INTO images VALUES (?, ?);');
      for (final item in items) {
        insertItem.execute([
          item.id,
          item.imageFile,
          item.priceCents,
          item.category,
          item.monthlyCents,
          item.months,
          item.resistanceCount,
          item.createdAt.millisecondsSinceEpoch,
          item.lastBurnedAt?.millisecondsSinceEpoch,
          item.destroyedAt?.millisecondsSinceEpoch,
          item.reflectionJson,
          item.movedAt?.millisecondsSinceEpoch,
          item.boughtAt?.millisecondsSinceEpoch,
          item.parkedUntil?.millisecondsSinceEpoch,
          item.followUpAt?.millisecondsSinceEpoch,
        ]);
        // Destroyed items have no photo left — that deletion is permanent
        // by design and must stay permanent through a backup.
        final file = store.file(item.imageFile);
        if (item.imageFile.isNotEmpty && file.existsSync()) {
          insertImage.execute([item.imageFile, file.readAsBytesSync()]);
        }
      }
      insertItem.close();
      insertImage.close();

      final burns = await db.select(db.burns).get();
      final insertBurn = archive.prepare('INSERT INTO burns VALUES (?, ?, ?, ?);');
      for (final b in burns) {
        insertBurn.execute([
          b.itemId,
          b.at.millisecondsSinceEpoch,
          b.priceCents,
          b.category,
        ]);
      }
      insertBurn.close();
    } finally {
      archive.close();
    }
    return out;
  }

  /// Restores an archive, replacing what's on the device.
  /// Returns how many desires came back.
  Future<int> import({required String path, required String passphrase}) async {
    final archive = sqlite3.open(path);
    try {
      archive.execute('PRAGMA key = ${sqlStringLiteral(passphrase)};');
      try {
        archive.select('SELECT count(*) FROM meta;');
      } on SqliteException {
        throw const BackupException(
          'Wrong passphrase, or this isn\'t a Burn My Desire backup.',
        );
      }

      final meta = archive.select('SELECT * FROM meta;').firstOrNull;
      if (meta == null) {
        throw const BackupException('This backup file is empty.');
      }
      final format = meta['format'] as int? ?? 0;
      if (format > kBackupFormatVersion) {
        throw const BackupException(
          'This backup was made by a newer version of the app.',
        );
      }

      await db.deleteAllItems();
      final images = {
        for (final row in archive.select('SELECT name, bytes FROM images;'))
          row['name'] as String: row['bytes'],
      };

      // Columns absent from older formats read as null — a v1 archive
      // simply has no confessions or reflections to bring back.
      Object? col(Map<String, dynamic> row, String name) =>
          row.keys.contains(name) ? row[name] : null;

      var restored = 0;
      // Archive item id → new device id, for the burn log.
      final idMap = <int, int>{};
      for (final row in archive.select('SELECT * FROM items;')) {
        final originalName = row['image_file'] as String? ?? '';
        var storedName = '';
        final bytes = images[originalName];
        if (bytes is List<int>) {
          storedName = await store.save(Uint8List.fromList(bytes));
        }
        final newId = await db
            .into(db.items)
            .insert(
              ItemsCompanion.insert(
                imageFile: storedName,
                priceCents: row['price_cents'] as int? ?? 0,
                category: Value(row['category'] as String? ?? 'purchase'),
                monthlyCents: Value(row['monthly_cents'] as int?),
                months: Value(row['months'] as int?),
                resistanceCount: Value(row['resistance_count'] as int? ?? 1),
                createdAt: _dateFrom(row['created_at']) ?? DateTime.now(),
                lastBurnedAt: Value(_dateFrom(row['last_burned_at'])),
                destroyedAt: Value(_dateFrom(row['destroyed_at'])),
                reflectionJson: Value(col(row, 'reflection_json') as String?),
                movedAt: Value(_dateFrom(col(row, 'moved_at'))),
                boughtAt: Value(_dateFrom(col(row, 'bought_at'))),
                parkedUntil: Value(_dateFrom(col(row, 'parked_until'))),
                followUpAt: Value(_dateFrom(col(row, 'follow_up_at'))),
              ),
            );
        final oldId = col(row, 'id');
        if (oldId is int) idMap[oldId] = newId;
        restored++;
      }

      // The burn log (format ≥ 2). Anything it can't map — or a v1
      // archive with no log at all — falls back to one event per item.
      if (format >= 2) {
        for (final row in archive.select('SELECT * FROM burns;')) {
          final newId = idMap[row['item_id']];
          final at = _dateFrom(row['at']);
          if (newId == null || at == null) continue;
          await db
              .into(db.burns)
              .insert(
                BurnsCompanion.insert(
                  itemId: newId,
                  at: at,
                  priceCents: row['price_cents'] as int? ?? 0,
                  category: Value(row['category'] as String? ?? 'purchase'),
                ),
              );
        }
      }
      await db.backfillBurns();

      final name = meta['name'] as String? ?? '';
      if (name.isNotEmpty) await saveProfileName(name);
      final goals = (meta['goals'] as String? ?? '').split(',')
        ..removeWhere((g) => g.isEmpty);
      if (goals.isNotEmpty) await saveBurnGoals(goals);
      final categories = (meta['categories'] as String? ?? '').split(',')
        ..removeWhere((c) => c.isEmpty);
      if (categories.isNotEmpty) await saveSpendCategories(categories);
      // Amounts are unit-less integers; the currency is the only thing
      // that says what they mean. Restore it, or a backup made in rupees
      // reads as euros on the new phone.
      final currency = col(meta, 'currency');
      if (currency is String && currency.isNotEmpty) {
        await saveCurrencyCode(currency);
      }
      final goalName = col(meta, 'goal_name');
      final goalTarget = col(meta, 'goal_target_cents');
      if (goalName is String && goalName.isNotEmpty && goalTarget is int) {
        await saveFinancialGoal(
          FinancialGoal(
            name: goalName,
            emoji: (col(meta, 'goal_emoji') as String?) ?? '🌱',
            targetCents: goalTarget,
          ),
        );
      }

      return restored;
    } finally {
      archive.close();
    }
  }

  static DateTime? _dateFrom(Object? millis) =>
      millis is int ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
}
