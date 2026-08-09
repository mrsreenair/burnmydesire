import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDbKeyKey = 'db_encryption_key';

/// Keychain-backed database key. `first_unlock_this_device` means the key
/// (and therefore the data) is unreadable until the phone has been
/// unlocked once after boot, and never syncs to iCloud or another device.
const _storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// A 256-bit key, hex-encoded for the `PRAGMA key` literal.
String generateDbKey([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Reads the database key, creating it on first launch. Losing this key
/// means losing the data — which is the point: without the Keychain
/// entry the file is ciphertext.
Future<String> databaseKey() async {
  final existing = await _storage.read(key: _kDbKeyKey);
  if (existing != null && existing.isNotEmpty) return existing;
  final key = generateDbKey();
  await _storage.write(key: _kDbKeyKey, value: key);
  return key;
}

Future<bool> hasDatabaseKey() async =>
    (await _storage.read(key: _kDbKeyKey)) != null;

/// Erase-everything must drop the key too, or the old ciphertext would
/// still be readable if the file were somehow recovered.
Future<void> deleteDatabaseKey() => _storage.delete(key: _kDbKeyKey);

/// SQLCipher takes a raw 256-bit key as a *quoted* blob literal —
/// `PRAGMA key = "x'<hex>'"`. Without the surrounding quotes SQLite
/// parses it as an expression and rejects it.
String pragmaKeyLiteral(String hexKey) => '"x\'$hexKey\'"';

/// Escapes a passphrase for use in a single-quoted SQL string literal.
String sqlStringLiteral(String value) =>
    "'${value.replaceAll("'", "''")}'";

/// Base64 of the raw key bytes — used when a key must travel inside an
/// encrypted backup archive rather than the Keychain.
String keyToBase64(String hexKey) {
  final bytes = <int>[
    for (var i = 0; i < hexKey.length; i += 2)
      int.parse(hexKey.substring(i, i + 2), radix: 16),
  ];
  return base64Encode(bytes);
}
