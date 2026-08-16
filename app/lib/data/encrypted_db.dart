import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'db_key.dart';

/// File the encrypted database lives in.
const kEncryptedDbFile = 'burn_my_desire_enc.sqlite';

/// The pre-encryption database drift_flutter created. Kept only long
/// enough to copy its rows into the encrypted file, then deleted.
const kLegacyDbFile = 'burn_my_desire.sqlite';

/// Thrown when the build didn't actually bundle an encryption-capable
/// SQLite. Better to fail loudly than to silently store plaintext while
/// telling users their data is encrypted.
class EncryptionUnavailableException implements Exception {
  const EncryptionUnavailableException();

  @override
  String toString() =>
      'This build has no encryption-capable SQLite. Check the sqlite3 '
      'hooks user_defines source in pubspec.yaml.';
}

/// True when the linked SQLite supports encryption pragmas.
bool cipherAvailable(Database db) => cipherVersion(db) != null;

/// The SQLCipher version string, or null when the linked SQLite has no
/// encryption support at all.
String? cipherVersion(Database db) {
  try {
    final rows = db.select('PRAGMA cipher_version;');
    if (rows.isNotEmpty) {
      final value = '${rows.first.values.first}'.trim();
      if (value.isNotEmpty) return value;
    }
  } on SqliteException {
    // Not a cipher build.
  }
  return null;
}

/// One-line report of whether data at rest is really encrypted. Surfaced
/// in Settings so the privacy claim can be checked, not just trusted.
Future<String> databaseSecurityReport() async {
  final probe = sqlite3.openInMemory();
  final version = cipherVersion(probe);
  probe.close();
  if (version == null) return 'unencrypted: no SQLCipher in this build';

  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, kEncryptedDbFile));
  if (!file.existsSync()) return 'SQLCipher $version, no database yet';
  final header = file.lengthSync() >= 16
      ? String.fromCharCodes(file.readAsBytesSync().take(15))
      : '';
  final plaintext = header.startsWith('SQLite format 3');
  return plaintext
      ? 'WARNING: database file is plaintext'
      : 'encrypted (SQLCipher $version)';
}

/// Applies the key and proves the file really opened. A wrong key only
/// surfaces on first read, so we force one here.
void unlock(Database db, String hexKey) {
  db.execute('PRAGMA key = ${pragmaKeyLiteral(hexKey)};');
  db.select('SELECT count(*) FROM sqlite_master;');
}

/// Copies a plaintext database into a new encrypted one, preserving the
/// schema exactly. Runs on the *plaintext* connection.
void exportToEncrypted(Database plain, String destPath, String hexKey) {
  plain.execute(
    "ATTACH DATABASE ${sqlStringLiteral(destPath)} AS encrypted "
    "KEY ${pragmaKeyLiteral(hexKey)};",
  );
  plain.select("SELECT sqlcipher_export('encrypted');");
  plain.execute('DETACH DATABASE encrypted;');
}

/// Opens the encrypted database, migrating a pre-encryption file on the
/// first run after upgrading.
QueryExecutor openEncryptedDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final encryptedPath = p.join(dir.path, kEncryptedDbFile);
    final legacy = File(p.join(dir.path, kLegacyDbFile));
    final key = await databaseKey();

    if (!File(encryptedPath).existsSync() && legacy.existsSync()) {
      final plain = sqlite3.open(legacy.path);
      try {
        if (!cipherAvailable(plain)) {
          throw const EncryptionUnavailableException();
        }
        exportToEncrypted(plain, encryptedPath, key);
      } finally {
        plain.close();
      }
      // The plaintext copy is the whole problem — remove it once the
      // encrypted file exists.
      if (File(encryptedPath).existsSync()) await legacy.delete();
    }

    return NativeDatabase(
      File(encryptedPath),
      setup: (db) {
        if (!cipherAvailable(db)) {
          // Loud, not silent: shipping plaintext while promising
          // encryption is worse than failing to open.
          debugPrint('FATAL: no SQLCipher — refusing to store plaintext');
          throw const EncryptionUnavailableException();
        }
        unlock(db, key);
      },
    );
  });
}

/// "Erase everything" for the database itself: the file, its WAL and
/// journal siblings, and the Keychain key. Deleting rows is not erasing —
/// SQLite keeps freed pages in the file until a VACUUM, and even a
/// vacuumed file is still ciphertext under a key that would still be in
/// the Keychain. Removing the file *and* rotating the key is the only
/// erase that means what the button says. The next open creates a fresh
/// file under a fresh key. Call after the connection is closed.
Future<void> wipeEncryptedDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final f = File(p.join(dir.path, '$kEncryptedDbFile$suffix'));
    if (f.existsSync()) await f.delete();
  }
  final legacy = File(p.join(dir.path, kLegacyDbFile));
  if (legacy.existsSync()) await legacy.delete();
  await deleteDatabaseKey();
}
