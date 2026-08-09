import 'dart:io';
import 'dart:typed_data';

import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/db_key.dart';
import 'package:burn_my_desire/data/encrypted_db.dart';
import 'package:burn_my_desire/data/file_protection.dart';
import 'package:burn_my_desire/data/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Runs on a real device/simulator, where the app's bundled SQLCipher is
/// actually linked — the only place the encryption claim can be proven.
///   flutter test integration_test/encryption_test.dart -d DEVICE_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped build links SQLCipher', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    expect(cipherVersion(db), isNotNull,
        reason: 'no SQLCipher: the app would store plaintext');
  });

  test('real burns land in a file that is encrypted on disk', () async {
    const canary = 'CANARY7788 secret craving';
    final db = AppDatabase();
    await db.insertBurnedItem(
      imageFile: '$canary.jpg',
      priceCents: 4242,
      category: 'emotion',
    );
    await db.close();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kEncryptedDbFile));
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));

    final bytes = file.readAsBytesSync();
    final text = String.fromCharCodes(bytes);

    expect(text.startsWith('SQLite format 3'), isFalse,
        reason: 'an encrypted database has no plaintext SQLite header');
    expect(text.contains(canary), isFalse,
        reason: 'user content must not be readable in the raw file');
  });

  test('the file cannot be opened without the Keychain key', () async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, kEncryptedDbFile);

    // No key at all.
    final noKey = sqlite3.open(path);
    expect(() => noKey.select('SELECT count(*) FROM items;'),
        throwsA(isA<SqliteException>()));
    noKey.close();

    // A different key.
    final wrongKey = sqlite3.open(path);
    expect(() => unlock(wrongKey, generateDbKey()),
        throwsA(isA<SqliteException>()));
    wrongKey.close();
  });

  test('the real key opens it and the row is intact', () async {
    final dir = await getApplicationDocumentsDirectory();
    final db = sqlite3.open(p.join(dir.path, kEncryptedDbFile));
    addTearDown(db.close);
    unlock(db, await databaseKey());
    final rows = db.select('SELECT image_file, price_cents FROM items;');
    expect(rows, isNotEmpty);
  });

  test('image files get complete protection, not the iOS default',
      () async {
    final dir = await getApplicationDocumentsDirectory();
    final store = ImageStore(dir.path);
    final name = await store.save(Uint8List.fromList(List.filled(64, 7)));
    // Check the image itself, not just the folder around it.
    final applied =
        await FileProtection().protectionOf(store.file(name).path);
    if (await FileProtection().isSimulator()) {
      // No Secure Enclave: the simulator reports no class at all. This
      // assertion is only meaningful on real hardware.
      expect(applied, anyOf('none', 'complete'));
      return;
    }
    expect(applied, 'complete',
        reason: 'thought pages hold the user\'s words as pixels; they must '
            'be unreadable while the phone is locked');
  });

  test('no plaintext database is left behind after migration', () async {
    final dir = await getApplicationDocumentsDirectory();
    expect(File(p.join(dir.path, kLegacyDbFile)).existsSync(), isFalse,
        reason: 'the pre-encryption file must be deleted, not orphaned');
  });
}
