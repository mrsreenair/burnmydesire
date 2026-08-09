import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'db_key.dart';
import 'image_store.dart';
import 'user_prefs.dart';

/// A Burn My Desire backup is itself a SQLCipher database, encrypted with
/// a passphrase the user chooses. Nothing is uploaded: the file goes
/// wherever they send it, and only their passphrase opens it.
///
/// SQLCipher derives the key from the passphrase (PBKDF2-HMAC-SHA512), so
/// no separate key handling is needed — and a wrong passphrase simply
/// fails to open.
const kBackupFormatVersion = 1;

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
        'goals TEXT, categories TEXT);',
      );
      archive.execute(
        'CREATE TABLE items (image_file TEXT, price_cents INTEGER, '
        'category TEXT, monthly_cents INTEGER, months INTEGER, '
        'resistance_count INTEGER, created_at INTEGER, '
        'last_burned_at INTEGER, destroyed_at INTEGER);',
      );
      archive.execute('CREATE TABLE images (name TEXT, bytes BLOB);');

      final meta = archive.prepare(
        'INSERT INTO meta VALUES (?, ?, ?, ?, ?);',
      );
      meta.execute([
        kBackupFormatVersion,
        DateTime.now().toIso8601String(),
        await profileName(),
        (await savedBurnGoals()).join(','),
        (await savedSpendCategories()).join(','),
      ]);
      meta.close();

      final items = await db.select(db.items).get();
      final insertItem = archive.prepare(
        'INSERT INTO items VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      );
      final insertImage =
          archive.prepare('INSERT INTO images VALUES (?, ?);');
      for (final item in items) {
        insertItem.execute([
          item.imageFile,
          item.priceCents,
          item.category,
          item.monthlyCents,
          item.months,
          item.resistanceCount,
          item.createdAt.millisecondsSinceEpoch,
          item.lastBurnedAt?.millisecondsSinceEpoch,
          item.destroyedAt?.millisecondsSinceEpoch,
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
    } finally {
      archive.close();
    }
    return out;
  }

  /// Restores an archive, replacing what's on the device.
  /// Returns how many desires came back.
  Future<int> import({
    required String path,
    required String passphrase,
  }) async {
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

      var restored = 0;
      for (final row in archive.select('SELECT * FROM items;')) {
        final originalName = row['image_file'] as String? ?? '';
        var storedName = '';
        final bytes = images[originalName];
        if (bytes is List<int>) {
          storedName = await store.save(Uint8List.fromList(bytes));
        }
        await db.into(db.items).insert(
              ItemsCompanion.insert(
                imageFile: storedName,
                priceCents: row['price_cents'] as int? ?? 0,
                category: Value(row['category'] as String? ?? 'purchase'),
                monthlyCents: Value(row['monthly_cents'] as int?),
                months: Value(row['months'] as int?),
                resistanceCount:
                    Value(row['resistance_count'] as int? ?? 1),
                createdAt: _dateFrom(row['created_at']) ?? DateTime.now(),
                lastBurnedAt: Value(_dateFrom(row['last_burned_at'])),
                destroyedAt: Value(_dateFrom(row['destroyed_at'])),
              ),
            );
        restored++;
      }

      final name = meta['name'] as String? ?? '';
      if (name.isNotEmpty) await saveProfileName(name);
      final goals = (meta['goals'] as String? ?? '').split(',')
        ..removeWhere((g) => g.isEmpty);
      if (goals.isNotEmpty) await saveBurnGoals(goals);
      final categories = (meta['categories'] as String? ?? '').split(',')
        ..removeWhere((c) => c.isEmpty);
      if (categories.isNotEmpty) await saveSpendCategories(categories);

      return restored;
    } finally {
      archive.close();
    }
  }

  static DateTime? _dateFrom(Object? millis) =>
      millis is int ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
}
