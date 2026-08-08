import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Stores item photos under the app documents directory. Only the file name
/// goes into the database — the documents path changes between iOS installs.
class ImageStore {
  ImageStore(this.documentsPath);

  final String documentsPath;

  Directory get _dir => Directory(p.join(documentsPath, 'item_images'));

  Future<String> save(Uint8List bytes) async {
    await _dir.create(recursive: true);
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(p.join(_dir.path, name)).writeAsBytes(bytes);
    return name;
  }

  File file(String name) => File(p.join(_dir.path, name));

  Future<Uint8List> read(String name) => file(name).readAsBytes();
}
