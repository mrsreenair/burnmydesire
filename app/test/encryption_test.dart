import 'dart:io';
import 'dart:math';

import 'package:burn_my_desire/data/db_key.dart';
import 'package:burn_my_desire/data/encrypted_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// The host test VM links plain SQLite; the sqlite3mc build ships only in
/// the app bundle (verified separately against the real database file on
/// device). Cipher behaviour tests are skipped here rather than silently
/// passing against an unencrypted engine.
final _cipherSkip = () {
  final db = sqlite3.openInMemory();
  try {
    return cipherAvailable(db)
        ? null
        : 'no cipher build in the test VM — verified on device instead';
  } finally {
    db.close();
  }
}();

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('bmd_enc'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('key generation', () {
    test('produces 64 hex chars (256 bits)', () {
      final key = generateDbKey();
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('keys differ', () {
      final rng = Random(7);
      expect(generateDbKey(rng), isNot(generateDbKey(rng)));
    });

    test('pragma literal is a quoted blob literal', () {
      // SQLCipher rejects the unquoted form.
      expect(pragmaKeyLiteral('abcd'), '"x\'abcd\'"');
    });

    test('sql string literal escapes quotes', () {
      expect(sqlStringLiteral("it's"), "'it''s'");
    });
  });

  group('cipher build', () {
    test('linked sqlite supports encryption', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      expect(cipherAvailable(db), isTrue,
          reason: 'sqlite3 must be built with sqlite3mc — check the hooks '
              'user_defines in pubspec.yaml');
    }, skip: _cipherSkip);
  });

  group('encryption at rest', () {
    test('written data is not readable as plaintext on disk', () {
      final key = generateDbKey();
      final path = p.join(dir.path, 'enc.sqlite');
      final db = sqlite3.open(path);
      unlock(db, key);
      db.execute('CREATE TABLE secrets (body TEXT);');
      db.execute("INSERT INTO secrets VALUES ('I keep texting my ex');");
      db.close();

      final bytes = File(path).readAsBytesSync();
      final asText = String.fromCharCodes(bytes);
      expect(asText, isNot(contains('I keep texting my ex')),
          reason: 'the thought must not sit in the file as plaintext');
      expect(asText.startsWith('SQLite format 3'), isFalse,
          reason: 'an encrypted file has no plaintext SQLite header');
    }, skip: _cipherSkip);

    test('correct key reads the data back', () {
      final key = generateDbKey();
      final path = p.join(dir.path, 'enc.sqlite');
      final write = sqlite3.open(path);
      unlock(write, key);
      write.execute('CREATE TABLE t (v TEXT);');
      write.execute("INSERT INTO t VALUES ('kept');");
      write.close();

      final read = sqlite3.open(path);
      unlock(read, key);
      expect(read.select('SELECT v FROM t;').first['v'], 'kept');
      read.close();
    }, skip: _cipherSkip);

    test('wrong key cannot read the data', () {
      final path = p.join(dir.path, 'enc.sqlite');
      final write = sqlite3.open(path);
      unlock(write, generateDbKey());
      write.execute('CREATE TABLE t (v TEXT);');
      write.execute("INSERT INTO t VALUES ('kept');");
      write.close();

      final read = sqlite3.open(path);
      expect(() => unlock(read, generateDbKey()), throwsA(isA<Exception>()));
      read.close();
    }, skip: _cipherSkip);

    test('no key at all cannot read the data', () {
      final path = p.join(dir.path, 'enc.sqlite');
      final write = sqlite3.open(path);
      unlock(write, generateDbKey());
      write.execute('CREATE TABLE t (v TEXT);');
      write.close();

      final read = sqlite3.open(path);
      expect(() => read.select('SELECT * FROM t;'), throwsA(isA<Exception>()));
      read.close();
    }, skip: _cipherSkip);
  });

  group('migration from plaintext', () {
    test('rows survive and the result is encrypted', () {
      final plainPath = p.join(dir.path, 'plain.sqlite');
      final encPath = p.join(dir.path, 'enc.sqlite');
      final key = generateDbKey();

      final plain = sqlite3.open(plainPath);
      plain.execute('CREATE TABLE items (id INTEGER, note TEXT);');
      plain.execute("INSERT INTO items VALUES (1, 'one more drink');");
      exportToEncrypted(plain, encPath, key);
      plain.close();

      final enc = sqlite3.open(encPath);
      unlock(enc, key);
      final rows = enc.select('SELECT note FROM items;');
      expect(rows.first['note'], 'one more drink');
      enc.close();

      final onDisk = String.fromCharCodes(File(encPath).readAsBytesSync());
      expect(onDisk, isNot(contains('one more drink')));
    }, skip: _cipherSkip);
  });
}
