import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'file_protection.dart';

/// Stores item photos under the app documents directory. Only the file name
/// goes into the database — the documents path changes between iOS installs.
///
/// A rendered thought page holds the user's own words as pixels, so every
/// file written here gets iOS complete protection: unreadable while the
/// phone is locked, not merely until the first unlock.
class ImageStore {
  ImageStore(this.documentsPath, [FileProtection? protection])
      : _protection = protection ?? FileProtection();

  final String documentsPath;
  final FileProtection _protection;

  Directory get _dir => Directory(p.join(documentsPath, 'item_images'));

  Future<String> save(Uint8List bytes) async {
    final created = !await _dir.exists();
    await _dir.create(recursive: true);
    // A new directory inherits the default class, so protect it too —
    // otherwise the folder itself reports weaker protection than its
    // contents.
    if (created) await _protection.protect(_dir.path);
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(p.join(_dir.path, name)).writeAsBytes(bytes);
    await _protection.protect(p.join(_dir.path, name));
    return name;
  }

  File file(String name) => File(p.join(_dir.path, name));

  Future<Uint8List> read(String name) => file(name).readAsBytes();

  /// Re-applies protection to everything already on disk — covers images
  /// written before this existed, and the directory itself.
  Future<void> protectAll() async {
    if (await _dir.exists()) await _protection.protect(_dir.path);
  }

  /// What iOS actually applied, for the security report in Settings.
  Future<String> protectionClass() => _protection.protectionOf(_dir.path);

  /// Final burn: the photo is the craving trigger — remove it for good.
  Future<void> delete(String name) async {
    final f = file(name);
    if (await f.exists()) await f.delete();
  }
}
