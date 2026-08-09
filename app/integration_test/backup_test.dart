import 'dart:io';
import 'dart:typed_data';

import 'package:burn_my_desire/data/backup.dart';
import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backups must be useless to anyone without the passphrase — they leave
/// the device, unlike everything else in this app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ImageStore store;
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase();
    final docs = await getApplicationDocumentsDirectory();
    store = ImageStore(docs.path);
    tmp = await Directory.systemTemp.createTemp('bmd_backup');
    await db.deleteAllItems();
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('rejects a weak passphrase', () async {
    expect(passphraseProblem('short'), isNotNull);
    expect(passphraseProblem('longenough1'), isNull);
    await expectLater(
      BackupService(db, store)
          .export(passphrase: 'abc', destinationDir: tmp.path),
      throwsA(isA<BackupException>()),
    );
  });

  test('the archive is encrypted and hides user content', () async {
    const canary = 'CANARY-BACKUP-4242';
    final image = await store.save(Uint8List.fromList(List.filled(32, 3)));
    await db.insertBurnedItem(
      imageFile: image,
      priceCents: 4242,
      category: 'emotion',
    );
    // Profile data rides along in the archive too.
    await db.customStatement("UPDATE items SET image_file = '$canary.jpg'");

    final file = await BackupService(db, store)
        .export(passphrase: 'a-strong-passphrase', destinationDir: tmp.path);

    expect(file.existsSync(), isTrue);
    final text = String.fromCharCodes(file.readAsBytesSync());
    expect(text.startsWith('SQLite format 3'), isFalse,
        reason: 'the backup must not be a readable database');
    expect(text.contains(canary), isFalse,
        reason: 'user content must not be readable inside the archive');
  });

  test('round-trips desires through export and import', () async {
    final image = await store.save(Uint8List.fromList(List.filled(48, 9)));
    await db.insertBurnedItem(
      imageFile: image,
      priceCents: 89900,
      category: 'purchase',
    );
    await db.insertBurnedItem(
      imageFile: '',
      priceCents: 0,
      category: 'emotion',
    );

    const pass = 'restore-me-please';
    final file = await BackupService(db, store)
        .export(passphrase: pass, destinationDir: tmp.path);

    await db.deleteAllItems();
    expect(await db.select(db.items).get(), isEmpty);

    final restored = await BackupService(db, store)
        .import(path: file.path, passphrase: pass);
    expect(restored, 2);

    final items = await db.select(db.items).get();
    expect(items.length, 2);
    expect(items.map((i) => i.priceCents), containsAll([89900, 0]));
    expect(items.map((i) => i.category), containsAll(['purchase', 'emotion']));
    // The photo came back as real bytes, not just a filename.
    final withPhoto = items.firstWhere((i) => i.imageFile.isNotEmpty);
    expect(store.file(withPhoto.imageFile).existsSync(), isTrue);
  });

  test('a wrong passphrase cannot open the archive', () async {
    await db.insertBurnedItem(imageFile: '', priceCents: 100);
    final file = await BackupService(db, store)
        .export(passphrase: 'correct-horse', destinationDir: tmp.path);

    await expectLater(
      BackupService(db, store)
          .import(path: file.path, passphrase: 'wrong-passphrase'),
      throwsA(isA<BackupException>()),
    );
  });
}
